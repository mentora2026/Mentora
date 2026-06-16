from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import MoodEntry, PatientProfile
from app.schemas.assessment import MoodEntryCreate, MoodEntryOut, MoodTrendPoint

router = APIRouter(prefix="/mood-entries", tags=["Mood Tracking"])


@router.post("", response_model=MoodEntryOut, status_code=status.HTTP_201_CREATED)
def create_mood_entry(
    payload: MoodEntryCreate,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    entry = MoodEntry(
        patient_profile_id=profile.id,
        mood_value=payload.mood_value,
        note_ar=payload.note_ar,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("", response_model=list[MoodEntryOut])
def list_mood_entries(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    query = db.query(MoodEntry).filter(MoodEntry.patient_profile_id == profile.id)

    if start_date:
        query = query.filter(MoodEntry.recorded_at >= start_date)
    if end_date:
        query = query.filter(MoodEntry.recorded_at <= end_date + timedelta(days=1))

    return query.order_by(MoodEntry.recorded_at.desc()).all()


@router.get("/trend", response_model=list[MoodTrendPoint])
def mood_trend(
    days: int = Query(default=30, ge=1, le=365),
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    start_date = date.today() - timedelta(days=days)

    rows = (
        db.query(
            func.date(MoodEntry.recorded_at).label("day"),
            func.avg(MoodEntry.mood_value).label("avg_mood"),
        )
        .filter(MoodEntry.patient_profile_id == profile.id, MoodEntry.recorded_at >= start_date)
        .group_by(func.date(MoodEntry.recorded_at))
        .order_by(func.date(MoodEntry.recorded_at))
        .all()
    )

    return [MoodTrendPoint(date=row.day, average_mood=float(row.avg_mood)) for row in rows]
