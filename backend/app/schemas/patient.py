import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.models.enums import ActivityLevel, Gender, SocialSupportLevel


class ChronicConditionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name_en: str
    name_ar: str
    description_ar: Optional[str] = None


class PatientConditionCreate(BaseModel):
    chronic_condition_id: uuid.UUID
    diagnosed_at: Optional[date] = None
    is_primary: bool = False


class PatientConditionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    chronic_condition: ChronicConditionOut
    diagnosed_at: Optional[date] = None
    is_primary: bool


class PatientProfileUpdate(BaseModel):
    date_of_birth: Optional[date] = None
    gender: Optional[Gender] = None
    disease_duration_months: Optional[Decimal] = None
    medications: Optional[str] = None
    sleep_hours_avg: Optional[Decimal] = None
    activity_level: Optional[ActivityLevel] = None
    social_support_level: Optional[SocialSupportLevel] = None
    medical_background: Optional[str] = None


class PatientProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    date_of_birth: Optional[date] = None
    gender: Optional[Gender] = None
    disease_duration_months: Optional[Decimal] = None
    medications: Optional[str] = None
    sleep_hours_avg: Optional[Decimal] = None
    activity_level: Optional[ActivityLevel] = None
    social_support_level: Optional[SocialSupportLevel] = None
    medical_background: Optional[str] = None
    onboarding_completed: bool
    created_at: datetime
    conditions: list[PatientConditionOut] = []
