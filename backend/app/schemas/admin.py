import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict

from app.models.enums import SessionStatus, TriggerType, UserRole
from app.schemas.interview import ChatMessageOut


class AdminUserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str
    role: UserRole
    is_active: bool
    created_at: datetime


class UserStatusUpdate(BaseModel):
    is_active: bool


class RiskMonitoringEntry(BaseModel):
    patient_profile_id: uuid.UUID
    user_id: uuid.UUID
    user_full_name: str
    latest_risk_level: Optional[int] = None
    latest_assessment_at: Optional[datetime] = None


class AuditLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    actor_user_id: Optional[uuid.UUID] = None
    action: str
    target_table: str
    target_id: uuid.UUID
    metadata_json: Optional[dict[str, Any]] = None
    created_at: datetime


class AdminAnalyticsOverview(BaseModel):
    total_patients: int
    active_patients_last_7_days: int
    risk_level_distribution: dict[str, int]
    total_sessions_last_30_days: int


# ---------------------------------------------------------------------------
# Admin patient detail (Step 5: Admin Dashboard "/users/:id" view)
# ---------------------------------------------------------------------------
class AdminConditionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    code: str
    name_ar: str
    is_primary: bool


class AdminInterviewSessionSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    status: SessionStatus
    trigger_type: TriggerType
    started_at: datetime
    ended_at: Optional[datetime] = None
    total_questions_asked: int
    risk_level: Optional[int] = None


class AdminRiskAssessmentSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    risk_level: int
    composite_score: Decimal
    created_at: datetime


class AdminPatientDetail(BaseModel):
    user_id: uuid.UUID
    full_name: str
    email: str
    is_active: bool
    created_at: datetime

    patient_profile_id: uuid.UUID
    onboarding_completed: bool
    activity_level: Optional[str] = None
    social_support_level: Optional[str] = None
    sleep_hours_avg: Optional[Decimal] = None
    disease_duration_months: Optional[Decimal] = None

    conditions: list[AdminConditionOut] = []
    interview_sessions: list[AdminInterviewSessionSummary] = []
    risk_history: list[AdminRiskAssessmentSummary] = []


# ---------------------------------------------------------------------------
# Admin interview session detail (Step 5: Admin Dashboard "/interviews/:id")
# ---------------------------------------------------------------------------
class AdminAnswerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    question_text_ar_snapshot: str
    answer_text_ar: Optional[str] = None
    answer_value_numeric: Optional[Decimal] = None
    sentiment_label: Optional[str] = None
    sentiment_score: Optional[Decimal] = None
    sequence_order: int


class AdminRiskAssessmentDetail(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
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


class AdminInterviewDetail(BaseModel):
    id: uuid.UUID
    patient_profile_id: uuid.UUID
    patient_full_name: str
    status: SessionStatus
    trigger_type: TriggerType
    started_at: datetime
    ended_at: Optional[datetime] = None
    total_questions_asked: int
    session_summary_ar: Optional[str] = None
    conversation: list[ChatMessageOut] = []
    answers: list[AdminAnswerOut] = []
    risk_assessment: Optional[AdminRiskAssessmentDetail] = None
