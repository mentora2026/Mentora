import uuid

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as PgEnum
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import ActivityLevel, Gender, SocialSupportLevel, UserRole


def gen_uuid():
    return uuid.uuid4()


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone_number = Column(String(20), unique=True, nullable=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(150), nullable=False)
    role = Column(
        PgEnum(UserRole, name="user_role", create_type=True),
        nullable=False,
        default=UserRole.patient,
    )
    is_active = Column(Boolean, nullable=False, default=True)
    preferred_language = Column(String(10), default="ar")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    patient_profile = relationship("PatientProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="actor")


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    gender = Column(PgEnum(Gender, name="gender", create_type=True), nullable=True)
    disease_duration_months = Column(Numeric, nullable=True)
    medications = Column(Text, nullable=True)
    sleep_hours_avg = Column(Numeric(3, 1), nullable=True)
    activity_level = Column(PgEnum(ActivityLevel, name="activity_level", create_type=True), nullable=True)
    social_support_level = Column(
        PgEnum(SocialSupportLevel, name="social_support_level", create_type=True), nullable=True
    )
    medical_background = Column(Text, nullable=True)
    onboarding_completed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="patient_profile")
    conditions = relationship("PatientCondition", back_populates="patient_profile", cascade="all, delete-orphan")
    interview_sessions = relationship("InterviewSession", back_populates="patient_profile", cascade="all, delete-orphan")
    mood_entries = relationship("MoodEntry", back_populates="patient_profile", cascade="all, delete-orphan")
    risk_assessments = relationship("RiskAssessment", back_populates="patient_profile", cascade="all, delete-orphan")
    patient_recommendations = relationship(
        "PatientRecommendation", back_populates="patient_profile", cascade="all, delete-orphan"
    )
    reports = relationship("Report", back_populates="patient_profile", cascade="all, delete-orphan")


class ChronicCondition(Base):
    __tablename__ = "chronic_conditions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    code = Column(String(50), unique=True, nullable=False)
    name_en = Column(String(100), nullable=False)
    name_ar = Column(String(100), nullable=False)
    description_ar = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    knowledge_config_json = Column(JSONB, nullable=True)

    patient_links = relationship("PatientCondition", back_populates="chronic_condition")
    interview_questions = relationship("InterviewQuestion", back_populates="chronic_condition")
    recommendations = relationship("Recommendation", back_populates="chronic_condition")
    content_items = relationship("ContentLibraryItem", back_populates="chronic_condition")


class PatientCondition(Base):
    __tablename__ = "patient_conditions"
    __table_args__ = (UniqueConstraint("patient_profile_id", "chronic_condition_id", name="uq_patient_condition"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    patient_profile_id = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False)
    chronic_condition_id = Column(UUID(as_uuid=True), ForeignKey("chronic_conditions.id"), nullable=False)
    diagnosed_at = Column(Date, nullable=True)
    is_primary = Column(Boolean, default=False)

    patient_profile = relationship("PatientProfile", back_populates="conditions")
    chronic_condition = relationship("ChronicCondition", back_populates="patient_links")
