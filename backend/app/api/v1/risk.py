from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import PatientProfile, RiskAssessment
from app.schemas.assessment import RiskAssessmentOut

router = APIRouter(prefix="/risk-assessments", tags=["Risk Assessment"])


@router.get("/latest", response_model=RiskAssessmentOut)
def get_latest_risk_assessment(
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    assessment = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.patient_profile_id == profile.id)
        .order_by(RiskAssessment.created_at.desc())
        .first()
    )
    if assessment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="لا يوجد تقييم نفسي متاح حتى الآن")
    return assessment


@router.get("", response_model=list[RiskAssessmentOut])
def list_risk_assessments(
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    return (
        db.query(RiskAssessment)
        .filter(RiskAssessment.patient_profile_id == profile.id)
        .order_by(RiskAssessment.created_at.desc())
        .all()
    )


@router.get("/{assessment_id}", response_model=RiskAssessmentOut)
def get_risk_assessment(
    assessment_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    assessment = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.id == assessment_id, RiskAssessment.patient_profile_id == profile.id)
        .first()
    )
    if assessment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="التقييم غير موجود")
    return assessment
