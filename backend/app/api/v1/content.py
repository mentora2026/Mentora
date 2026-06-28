from fastapi import APIRouter, Depends
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import PatientCondition, PatientProfile
from app.models.misc import ContentLibraryItem
from app.schemas.extras import ContentLibraryOut

router = APIRouter(tags=["Educational Content"])


@router.get("/content-library", response_model=list[ContentLibraryOut])
def get_my_content_library(
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    patient_condition_ids = [
        pc.chronic_condition_id
        for pc in db.query(PatientCondition).filter(PatientCondition.patient_profile_id == profile.id).all()
    ]

    query = db.query(ContentLibraryItem).filter(ContentLibraryItem.is_published.is_(True))

    if patient_condition_ids:
        query = query.filter(
            or_(
                ContentLibraryItem.chronic_condition_id.is_(None),
                ContentLibraryItem.chronic_condition_id.in_(patient_condition_ids),
            )
        )
    else:
        query = query.filter(ContentLibraryItem.chronic_condition_id.is_(None))

    return query.order_by(ContentLibraryItem.created_at.desc()).all()
