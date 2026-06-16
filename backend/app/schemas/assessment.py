import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import MoodSource, ReportType


class MoodEntryCreate(BaseModel):
    mood_value: int = Field(ge=1, le=5)
    note_ar: Optional[str] = None


class MoodEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    mood_value: int
    note_ar: Optional[str] = None
    source: MoodSource
    recorded_at: datetime


class MoodTrendPoint(BaseModel):
    date: date
    average_mood: float


class RiskAssessmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    interview_session_id: uuid.UUID
    risk_level: int
    anxiety_score: Decimal
    stress_score: Decimal
    sadness_score: Decimal
    burnout_score: Decimal
    sleep_quality_score: Decimal
    adherence_score: Decimal
    composite_score: Decimal
    explanation_ar: str
    explanation_factors_json: dict[str, Any]
    created_at: datetime


class RiskProgressionPoint(BaseModel):
    date: datetime
    risk_level: int
    composite_score: Decimal


class ReportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    report_type: ReportType
    period_start: date
    period_end: date
    summary_ar: str
    metrics_json: dict[str, Any]
    generated_at: datetime
