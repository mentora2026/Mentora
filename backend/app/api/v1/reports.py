from datetime import date, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import InterviewSession, MoodEntry, PatientProfile, Report, RiskAssessment
from app.models.enums import ReportType, SessionStatus
from app.schemas.assessment import ReportOut, RiskProgressionPoint

router = APIRouter(prefix="/reports", tags=["Reports & Analytics"])


def _build_report(db: Session, profile: PatientProfile, report_type: ReportType, days: int) -> Report:
    period_end = date.today()
    period_start = period_end - timedelta(days=days)

    mood_avg = (
        db.query(func.avg(MoodEntry.mood_value))
        .filter(MoodEntry.patient_profile_id == profile.id, MoodEntry.recorded_at >= period_start)
        .scalar()
    )

    sessions_count = (
        db.query(func.count(InterviewSession.id))
        .filter(
            InterviewSession.patient_profile_id == profile.id,
            InterviewSession.status == SessionStatus.completed,
            InterviewSession.started_at >= period_start,
        )
        .scalar()
    )

    risk_assessments = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.patient_profile_id == profile.id, RiskAssessment.created_at >= period_start)
        .order_by(RiskAssessment.created_at.asc())
        .all()
    )

    risk_levels = [ra.risk_level for ra in risk_assessments]
    latest_risk_level = risk_levels[-1] if risk_levels else None

    metrics = {
        "average_mood": float(mood_avg) if mood_avg is not None else None,
        "completed_sessions": sessions_count or 0,
        "risk_levels": risk_levels,
        "latest_risk_level": latest_risk_level,
    }

    summary_ar = _build_summary_ar(report_type, metrics)

    report = Report(
        patient_profile_id=profile.id,
        report_type=report_type,
        period_start=period_start,
        period_end=period_end,
        summary_ar=summary_ar,
        metrics_json=metrics,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report


def _build_summary_ar(report_type: ReportType, metrics: dict) -> str:
    period_name = {
        ReportType.daily: "اليوم",
        ReportType.weekly: "هذا الأسبوع",
        ReportType.monthly: "هذا الشهر",
    }[report_type]

    parts = [f"ملخص {period_name}:"]

    if metrics["average_mood"] is not None:
        parts.append(f"متوسط حالتك المزاجية كان {round(metrics['average_mood'], 1)} من 5.")
    else:
        parts.append("لم تقم بتسجيل حالتك المزاجية خلال هذه الفترة.")

    parts.append(f"أكملت {metrics['completed_sessions']} جلسة محادثة تفاعلية.")

    if metrics["latest_risk_level"] is not None:
        parts.append(f"آخر تصنيف لمستوى الخطر النفسي كان المستوى {metrics['latest_risk_level']}.")
    else:
        parts.append("لا يوجد تقييم نفسي مسجل بعد خلال هذه الفترة.")

    return " ".join(parts)


@router.get("/daily", response_model=ReportOut)
def get_daily_report(profile: PatientProfile = Depends(get_current_patient_profile), db: Session = Depends(get_db)):
    return _build_report(db, profile, ReportType.daily, days=1)


@router.get("/weekly", response_model=ReportOut)
def get_weekly_report(profile: PatientProfile = Depends(get_current_patient_profile), db: Session = Depends(get_db)):
    return _build_report(db, profile, ReportType.weekly, days=7)


@router.get("/monthly", response_model=ReportOut)
def get_monthly_report(profile: PatientProfile = Depends(get_current_patient_profile), db: Session = Depends(get_db)):
    return _build_report(db, profile, ReportType.monthly, days=30)


@router.get("/risk-progression", response_model=list[RiskProgressionPoint])
def get_risk_progression(
    profile: PatientProfile = Depends(get_current_patient_profile), db: Session = Depends(get_db)
):
    assessments = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.patient_profile_id == profile.id)
        .order_by(RiskAssessment.created_at.asc())
        .all()
    )
    return [
        RiskProgressionPoint(date=ra.created_at, risk_level=ra.risk_level, composite_score=ra.composite_score)
        for ra in assessments
    ]
