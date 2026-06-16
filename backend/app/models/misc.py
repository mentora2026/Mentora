import uuid

from sqlalchemy import (
    ARRAY,
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as PgEnum
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import (
    ContentType,
    MoodSource,
    NotificationStatus,
    NotificationType,
    RecommendationCategory,
    ReportType,
)
from app.models.patient import gen_uuid


class MoodEntry(Base):
    __tablename__ = "mood_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    patient_profile_id = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False)
    mood_value = Column(SmallInteger, nullable=False)
    note_ar = Column(Text, nullable=True)
    source = Column(PgEnum(MoodSource, name="mood_source", create_type=True), default=MoodSource.manual)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())

    patient_profile = relationship("PatientProfile", back_populates="mood_entries")


class RiskAssessment(Base):
    __tablename__ = "risk_assessments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    patient_profile_id = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False)
    interview_session_id = Column(UUID(as_uuid=True), ForeignKey("interview_sessions.id"), nullable=False, unique=True)

    risk_level = Column(SmallInteger, nullable=False)  # CHECK 1..5 enforced at DB level via migration
    anxiety_score = Column(Numeric(4, 2), nullable=False)
    stress_score = Column(Numeric(4, 2), nullable=False)
    sadness_score = Column(Numeric(4, 2), nullable=False)
    burnout_score = Column(Numeric(4, 2), nullable=False)
    sleep_quality_score = Column(Numeric(4, 2), nullable=False)
    adherence_score = Column(Numeric(4, 2), nullable=False)
    composite_score = Column(Numeric(5, 2), nullable=False)

    explanation_ar = Column(Text, nullable=False)
    explanation_factors_json = Column(JSONB, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    patient_profile = relationship("PatientProfile", back_populates="risk_assessments")
    interview_session = relationship(
        "InterviewSession", back_populates="risk_assessment", foreign_keys=[interview_session_id]
    )
    patient_recommendations = relationship("PatientRecommendation", back_populates="risk_assessment")


class Recommendation(Base):
    __tablename__ = "recommendations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    category = Column(PgEnum(RecommendationCategory, name="recommendation_category", create_type=True), nullable=False)
    chronic_condition_id = Column(UUID(as_uuid=True), ForeignKey("chronic_conditions.id"), nullable=True)
    applicable_risk_levels = Column(ARRAY(SmallInteger), nullable=False)
    title_ar = Column(String(255), nullable=False)
    content_ar = Column(Text, nullable=False)
    media_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    chronic_condition = relationship("ChronicCondition", back_populates="recommendations")
    patient_links = relationship("PatientRecommendation", back_populates="recommendation")


class PatientRecommendation(Base):
    __tablename__ = "patient_recommendations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    patient_profile_id = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False)
    recommendation_id = Column(UUID(as_uuid=True), ForeignKey("recommendations.id"), nullable=False)
    risk_assessment_id = Column(UUID(as_uuid=True), ForeignKey("risk_assessments.id"), nullable=True)
    delivered_at = Column(DateTime(timezone=True), server_default=func.now())
    is_viewed = Column(Boolean, default=False)
    is_helpful_feedback = Column(Boolean, nullable=True)

    patient_profile = relationship("PatientProfile", back_populates="patient_recommendations")
    recommendation = relationship("Recommendation", back_populates="patient_links")
    risk_assessment = relationship("RiskAssessment", back_populates="patient_recommendations")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(PgEnum(NotificationType, name="notification_type", create_type=True), nullable=False)
    title_ar = Column(String(255), nullable=False)
    body_ar = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    scheduled_for = Column(DateTime(timezone=True), nullable=True)
    status = Column(PgEnum(NotificationStatus, name="notification_status", create_type=True), default=NotificationStatus.pending)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")


class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    patient_profile_id = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False)
    report_type = Column(PgEnum(ReportType, name="report_type", create_type=True), nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    summary_ar = Column(Text, nullable=False)
    metrics_json = Column(JSONB, nullable=False)
    generated_at = Column(DateTime(timezone=True), server_default=func.now())

    patient_profile = relationship("PatientProfile", back_populates="reports")


class ContentLibraryItem(Base):
    __tablename__ = "content_library"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    content_type = Column(PgEnum(ContentType, name="content_type", create_type=True), nullable=False)
    key = Column(String(150), nullable=False)
    chronic_condition_id = Column(UUID(as_uuid=True), ForeignKey("chronic_conditions.id"), nullable=True)
    title_ar = Column(String(255), nullable=True)
    body_ar = Column(Text, nullable=False)
    is_published = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    chronic_condition = relationship("ChronicCondition", back_populates="content_items")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    actor_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    action = Column(String(100), nullable=False)
    target_table = Column(String(100), nullable=False)
    target_id = Column(UUID(as_uuid=True), nullable=False)
    metadata_json = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    actor = relationship("User", back_populates="audit_logs")
