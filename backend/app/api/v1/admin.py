from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.api.deps import require_admin
from app.core.database import get_db
from app.models import (
    AuditLog,
    ContentLibraryItem,
    InterviewSession,
    PatientCondition,
    PatientProfile,
    Recommendation,
    PatientRecommendation,
    RiskAssessment,
    User,
    UserDevice,
    Notification,
)
from app.models.enums import SessionStatus, RecommendationCategory, NotificationType, NotificationStatus
from app.core.firebase import send_push_notification
from app.schemas.admin import (
    AdminAnalyticsOverview,
    AdminAnswerOut,
    AdminConditionOut,
    AdminInterviewDetail,
    AdminInterviewSessionSummary,
    AdminPatientDetail,
    AdminRiskAssessmentDetail,
    AdminRiskAssessmentSummary,
    AdminUserOut,
    AuditLogOut,
    RiskMonitoringEntry,
    UserStatusUpdate,
    DirectRecommendationCreate,
)
from app.schemas.extras import (
    AdminRecommendationOut,
    ContentLibraryCreate,
    ContentLibraryOut,
    RecommendationCreate,
    RecommendationUpdate,
)
from app.schemas.interview import ChatMessageOut

router = APIRouter(prefix="/admin", tags=["Admin Dashboard"], dependencies=[Depends(require_admin)])


# ----------------------------------------------------------------------
# User management
# ----------------------------------------------------------------------
@router.get("/users", response_model=list[AdminUserOut])
def list_users(db: Session = Depends(get_db)):
    return db.query(User).order_by(User.created_at.desc()).all()


@router.get("/users/{user_id}", response_model=AdminUserOut)
def get_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود")
    return user


@router.get("/users/{user_id}/patient-detail", response_model=AdminPatientDetail)
def get_patient_detail(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود")

    profile = db.query(PatientProfile).filter(PatientProfile.user_id == user.id).first()
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="لا يوجد ملف مريض لهذا المستخدم")

    patient_conditions = (
        db.query(PatientCondition)
        .options(joinedload(PatientCondition.chronic_condition))
        .filter(PatientCondition.patient_profile_id == profile.id)
        .all()
    )
    conditions = [
        AdminConditionOut(
            code=pc.chronic_condition.code,
            name_ar=pc.chronic_condition.name_ar,
            is_primary=pc.is_primary,
        )
        for pc in patient_conditions
    ]

    sessions = (
        db.query(InterviewSession)
        .options(joinedload(InterviewSession.risk_assessment))
        .filter(InterviewSession.patient_profile_id == profile.id)
        .order_by(InterviewSession.started_at.desc())
        .limit(50)
        .all()
    )
    interview_sessions = [
        AdminInterviewSessionSummary(
            id=s.id,
            status=s.status,
            trigger_type=s.trigger_type,
            started_at=s.started_at,
            ended_at=s.ended_at,
            total_questions_asked=s.total_questions_asked,
            risk_level=s.risk_assessment.risk_level if s.risk_assessment else None,
        )
        for s in sessions
    ]

    risk_assessments = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.patient_profile_id == profile.id)
        .order_by(RiskAssessment.created_at.desc())
        .limit(50)
        .all()
    )
    risk_history = [AdminRiskAssessmentSummary.model_validate(ra) for ra in risk_assessments]

    return AdminPatientDetail(
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
        is_active=user.is_active,
        created_at=user.created_at,
        patient_profile_id=profile.id,
        onboarding_completed=profile.onboarding_completed,
        activity_level=profile.activity_level.value if profile.activity_level else None,
        social_support_level=profile.social_support_level.value if profile.social_support_level else None,
        sleep_hours_avg=profile.sleep_hours_avg,
        disease_duration_months=profile.disease_duration_months,
        conditions=conditions,
        interview_sessions=interview_sessions,
        risk_history=risk_history,
    )


@router.patch("/users/{user_id}/status", response_model=AdminUserOut)
def update_user_status(
    user_id: str,
    payload: UserStatusUpdate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود")

    user.is_active = payload.is_active
    db.add(user)

    audit = AuditLog(
        actor_user_id=admin_user.id,
        action="user_status_updated",
        target_table="users",
        target_id=user.id,
        metadata_json={"is_active": payload.is_active},
    )
    db.add(audit)
    db.commit()
    db.refresh(user)
    return user


# ----------------------------------------------------------------------
# Risk monitoring
# ----------------------------------------------------------------------
@router.get("/risk-monitoring", response_model=list[RiskMonitoringEntry])
def risk_monitoring(db: Session = Depends(get_db)):
    profiles = db.query(PatientProfile).options(joinedload(PatientProfile.user)).all()

    results: list[RiskMonitoringEntry] = []
    for profile in profiles:
        latest = (
            db.query(RiskAssessment)
            .filter(RiskAssessment.patient_profile_id == profile.id)
            .order_by(RiskAssessment.created_at.desc())
            .first()
        )
        results.append(
            RiskMonitoringEntry(
                patient_profile_id=profile.id,
                user_id=profile.user_id,
                user_full_name=profile.user.full_name,
                latest_risk_level=latest.risk_level if latest else None,
                latest_assessment_at=latest.created_at if latest else None,
            )
        )

    # Sort highest risk first (None last)
    results.sort(key=lambda r: (r.latest_risk_level is None, -(r.latest_risk_level or 0)))
    return results


# ----------------------------------------------------------------------
# Interview monitoring
# ----------------------------------------------------------------------
@router.get("/interviews/{session_id}", response_model=AdminInterviewDetail)
def get_interview_session(session_id: str, db: Session = Depends(get_db)):
    session = (
        db.query(InterviewSession)
        .options(
            joinedload(InterviewSession.conversation),
            joinedload(InterviewSession.answers),
            joinedload(InterviewSession.risk_assessment),
            joinedload(InterviewSession.patient_profile).joinedload(PatientProfile.user),
        )
        .filter(InterviewSession.id == session_id)
        .first()
    )
    if session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="الجلسة غير موجودة")

    return AdminInterviewDetail(
        id=session.id,
        patient_profile_id=session.patient_profile_id,
        patient_full_name=session.patient_profile.user.full_name,
        status=session.status,
        trigger_type=session.trigger_type,
        started_at=session.started_at,
        ended_at=session.ended_at,
        total_questions_asked=session.total_questions_asked,
        session_summary_ar=session.session_summary_ar,
        conversation=[ChatMessageOut.model_validate(m) for m in session.conversation],
        answers=[AdminAnswerOut.model_validate(a) for a in session.answers],
        risk_assessment=AdminRiskAssessmentDetail.model_validate(session.risk_assessment)
        if session.risk_assessment
        else None,
    )


# ----------------------------------------------------------------------
# Recommendation catalog management
# ----------------------------------------------------------------------
@router.get("/recommendations", response_model=list[AdminRecommendationOut])
def list_recommendations_admin(db: Session = Depends(get_db)):
    return db.query(Recommendation).order_by(Recommendation.created_at.desc()).all()


@router.post("/recommendations", response_model=AdminRecommendationOut, status_code=status.HTTP_201_CREATED)
def create_recommendation(
    payload: RecommendationCreate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rec = Recommendation(**payload.model_dump())
    db.add(rec)
    db.flush()
    
    audit = AuditLog(
        actor_user_id=admin_user.id,
        action="recommendation_created",
        target_table="recommendations",
        target_id=rec.id,
        metadata_json={"category": rec.category.value, "title_ar": rec.title_ar},
    )
    db.add(audit)
    
    db.commit()
    db.refresh(rec)
    return rec


@router.put("/recommendations/{recommendation_id}", response_model=AdminRecommendationOut)
def update_recommendation(
    recommendation_id: str,
    payload: RecommendationUpdate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rec = db.query(Recommendation).filter(Recommendation.id == recommendation_id).first()
    if rec is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="التوصية غير موجودة")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(rec, field, value)

    db.add(rec)
    
    audit = AuditLog(
        actor_user_id=admin_user.id,
        action="recommendation_updated",
        target_table="recommendations",
        target_id=rec.id,
        metadata_json={"updated_fields": list(payload.model_dump(exclude_unset=True).keys())},
    )
    db.add(audit)
    
    db.commit()
    db.refresh(rec)
    return rec


@router.delete("/recommendations/{recommendation_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_recommendation(
    recommendation_id: str,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rec = db.query(Recommendation).filter(Recommendation.id == recommendation_id).first()
    if rec is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="التوصية غير موجودة")

    rec.is_active = False
    db.add(rec)
    
    audit = AuditLog(
        actor_user_id=admin_user.id,
        action="recommendation_deactivated",
        target_table="recommendations",
        target_id=rec.id,
    )
    db.add(audit)
    
    db.commit()
    return None


@router.post("/patients/{patient_profile_id}/send-recommendation", response_model=AdminRecommendationOut, status_code=status.HTTP_201_CREATED)
def send_direct_recommendation(
    patient_profile_id: str,
    payload: DirectRecommendationCreate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    profile = db.query(PatientProfile).filter(PatientProfile.id == patient_profile_id).first()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="ملف المريض غير موجود")

    # 1. Create the custom recommendation
    rec = Recommendation(
        category=RecommendationCategory.direct_supervisor,
        title_ar=payload.title_ar,
        content_ar=payload.content_ar,
        applicable_risk_levels=[1, 2, 3, 4, 5],
        is_active=True,
    )
    db.add(rec)
    db.flush()  # to get rec.id

    # 2. Link to patient
    patient_rec = PatientRecommendation(
        patient_profile_id=profile.id,
        recommendation_id=rec.id,
    )
    db.add(patient_rec)
    db.flush()

    # 3. Create Notification in DB
    notification = Notification(
        user_id=profile.user_id,
        type=NotificationType.recommendation_alert,
        title_ar=payload.title_ar,
        body_ar=payload.content_ar,
    )
    db.add(notification)
    
    audit = AuditLog(
        actor_user_id=admin_user.id,
        action="direct_recommendation_sent",
        target_table="patient_recommendations",
        target_id=patient_rec.id,
        metadata_json={"patient_profile_id": str(profile.id), "recommendation_id": str(rec.id)},
    )
    db.add(audit)

    db.commit()
    db.refresh(rec)

    # 4. Send Push Notification
    devices = db.query(UserDevice).filter(UserDevice.user_id == profile.user_id).all()
    for device in devices:
        send_push_notification(
            token=device.fcm_token,
            title=payload.title_ar,
            body=payload.content_ar,
            data={
                "type": "recommendation_alert",
                "patient_recommendation_id": str(patient_rec.id),
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
        )

    return rec


# ----------------------------------------------------------------------
# Content library management
# ----------------------------------------------------------------------
@router.get("/content-library", response_model=list[ContentLibraryOut])
def list_content_library(db: Session = Depends(get_db)):
    return db.query(ContentLibraryItem).order_by(ContentLibraryItem.created_at.desc()).all()


@router.post("/content-library", response_model=ContentLibraryOut, status_code=status.HTTP_201_CREATED)
def create_content_item(
    payload: ContentLibraryCreate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    item = ContentLibraryItem(**payload.model_dump())
    db.add(item)
    db.flush()
    
    audit = AuditLog(
        actor_user_id=admin_user.id,
        action="content_item_created",
        target_table="content_library",
        target_id=item.id,
        metadata_json={"content_type": item.content_type.value, "key": item.key},
    )
    db.add(audit)

    db.commit()
    db.refresh(item)
    return item


# ----------------------------------------------------------------------
# Analytics overview
# ----------------------------------------------------------------------
@router.get("/analytics/overview", response_model=AdminAnalyticsOverview)
def analytics_overview(db: Session = Depends(get_db)):
    total_patients = db.query(func.count(PatientProfile.id)).scalar() or 0

    week_ago = datetime.now(timezone.utc) - timedelta(days=7)
    month_ago = datetime.now(timezone.utc) - timedelta(days=30)

    active_patients_last_7_days = (
        db.query(func.count(func.distinct(InterviewSession.patient_profile_id)))
        .filter(InterviewSession.started_at >= week_ago)
        .scalar()
        or 0
    )

    total_sessions_last_30_days = (
        db.query(func.count(InterviewSession.id))
        .filter(InterviewSession.started_at >= month_ago, InterviewSession.status == SessionStatus.completed)
        .scalar()
        or 0
    )

    risk_distribution_rows = (
        db.query(RiskAssessment.risk_level, func.count(RiskAssessment.id))
        .group_by(RiskAssessment.risk_level)
        .all()
    )
    risk_distribution = {str(level): count for level, count in risk_distribution_rows}
    for level in range(1, 6):
        risk_distribution.setdefault(str(level), 0)

    return AdminAnalyticsOverview(
        total_patients=total_patients,
        active_patients_last_7_days=active_patients_last_7_days,
        risk_level_distribution=risk_distribution,
        total_sessions_last_30_days=total_sessions_last_30_days,
    )


# ----------------------------------------------------------------------
# Audit logs
# ----------------------------------------------------------------------
@router.get("/audit-logs", response_model=list[AuditLogOut])
def list_audit_logs(db: Session = Depends(get_db)):
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(200).all()
