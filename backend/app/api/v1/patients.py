from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import ChronicCondition, PatientCondition, PatientProfile
from app.schemas.patient import (
    ChronicConditionOut,
    PatientConditionCreate,
    PatientConditionOut,
    PatientProfileOut,
    PatientProfileUpdate,
)

router = APIRouter(tags=["Patient Profile"])


@router.get("/conditions", response_model=list[ChronicConditionOut])
def list_chronic_conditions(db: Session = Depends(get_db)):
    return db.query(ChronicCondition).filter(ChronicCondition.is_active.is_(True)).all()


@router.get("/patients/me", response_model=PatientProfileOut)
def get_my_profile(profile: PatientProfile = Depends(get_current_patient_profile)):
    return profile


@router.put("/patients/me", response_model=PatientProfileOut)
def update_my_profile(
    payload: PatientProfileUpdate,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    # Mark onboarding complete once core fields are filled in
    if profile.disease_duration_months is not None and profile.activity_level is not None:
        profile.onboarding_completed = True

    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.get("/patients/me/conditions", response_model=list[PatientConditionOut])
def list_my_conditions(profile: PatientProfile = Depends(get_current_patient_profile), db: Session = Depends(get_db)):
    return (
        db.query(PatientCondition)
        .options(joinedload(PatientCondition.chronic_condition))
        .filter(PatientCondition.patient_profile_id == profile.id)
        .all()
    )


@router.post("/patients/me/conditions", response_model=PatientConditionOut, status_code=status.HTTP_201_CREATED)
def add_my_condition(
    payload: PatientConditionCreate,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    condition = db.query(ChronicCondition).filter(ChronicCondition.id == payload.chronic_condition_id).first()
    if condition is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="نوع المرض غير موجود")

    existing = (
        db.query(PatientCondition)
        .filter(
            PatientCondition.patient_profile_id == profile.id,
            PatientCondition.chronic_condition_id == payload.chronic_condition_id,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="هذا المرض مضاف مسبقاً لملفك الشخصي")

    patient_condition = PatientCondition(
        patient_profile_id=profile.id,
        chronic_condition_id=payload.chronic_condition_id,
        diagnosed_at=payload.diagnosed_at,
        is_primary=payload.is_primary,
    )
    db.add(patient_condition)
    db.commit()
    db.refresh(patient_condition)
    return patient_condition


@router.delete("/patients/me/conditions/{condition_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_my_condition(
    condition_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    patient_condition = (
        db.query(PatientCondition)
        .filter(
            PatientCondition.patient_profile_id == profile.id,
            PatientCondition.chronic_condition_id == condition_id,
        )
        .first()
    )
    if patient_condition is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="السجل غير موجود")

    db.delete(patient_condition)
    db.commit()
    return None
