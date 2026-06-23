from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import PatientProfile, PatientRecommendation
from app.schemas.extras import PatientRecommendationOut, RecommendationFeedback

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


@router.get("/me", response_model=list[PatientRecommendationOut])
def get_my_recommendations(
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    return (
        db.query(PatientRecommendation)
        .options(joinedload(PatientRecommendation.recommendation))
        .filter(PatientRecommendation.patient_profile_id == profile.id)
        .order_by(PatientRecommendation.delivered_at.desc())
        .all()
    )


@router.post("/{patient_recommendation_id}/viewed", status_code=status.HTTP_204_NO_CONTENT)
def mark_recommendation_viewed(
    patient_recommendation_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    pr = _get_owned(db, patient_recommendation_id, profile)
    pr.is_viewed = True
    db.add(pr)
    db.commit()
    return None


@router.post("/{patient_recommendation_id}/feedback", status_code=status.HTTP_204_NO_CONTENT)
def submit_recommendation_feedback(
    patient_recommendation_id: str,
    payload: RecommendationFeedback,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    pr = _get_owned(db, patient_recommendation_id, profile)
    pr.is_helpful_feedback = payload.is_helpful
    db.add(pr)
    db.commit()
    return None


@router.delete("/{patient_recommendation_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_recommendation(
    patient_recommendation_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    pr = _get_owned(db, patient_recommendation_id, profile)
    db.delete(pr)
    db.commit()
    return None


def _get_owned(db: Session, patient_recommendation_id: str, profile: PatientProfile) -> PatientRecommendation:
    pr = (
        db.query(PatientRecommendation)
        .filter(
            PatientRecommendation.id == patient_recommendation_id,
            PatientRecommendation.patient_profile_id == profile.id,
        )
        .first()
    )
    if pr is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="التوصية غير موجودة")
    return pr
