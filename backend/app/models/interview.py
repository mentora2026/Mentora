import uuid

from sqlalchemy import (
    Column,
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
    ChatSender,
    QuestionCategory,
    QuestionType,
    SessionStatus,
    TriggerType,
)
from app.models.patient import gen_uuid


class InterviewQuestion(Base):
    __tablename__ = "interview_questions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    chronic_condition_id = Column(UUID(as_uuid=True), ForeignKey("chronic_conditions.id"), nullable=True)
    category = Column(PgEnum(QuestionCategory, name="question_category", create_type=True), nullable=False)
    question_text_ar = Column(Text, nullable=False)
    question_type = Column(PgEnum(QuestionType, name="question_type", create_type=True), nullable=False)
    options_json = Column(JSONB, nullable=True)
    difficulty_depth = Column(SmallInteger, nullable=False, default=1)
    is_template = Column(Integer, default=1)  # 1 = true, kept simple for boolean-like flag
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    chronic_condition = relationship("ChronicCondition", back_populates="interview_questions")
    answers = relationship("InterviewAnswer", back_populates="interview_question")


class InterviewSession(Base):
    __tablename__ = "interview_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    patient_profile_id = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    ended_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(PgEnum(SessionStatus, name="session_status", create_type=True), default=SessionStatus.in_progress)
    trigger_type = Column(PgEnum(TriggerType, name="trigger_type", create_type=True), nullable=False)
    total_questions_asked = Column(Integer, default=0)
    session_summary_ar = Column(Text, nullable=True)
    risk_assessment_id = Column(UUID(as_uuid=True), ForeignKey("risk_assessments.id"), nullable=True)

    # context_state holds the Adaptive Interview Engine's working memory for this session
    # (covered categories, emotional indicator accumulators, etc.) - used heavily in Step 3.
    context_state_json = Column(JSONB, nullable=True)

    patient_profile = relationship("PatientProfile", back_populates="interview_sessions")
    answers = relationship(
        "InterviewAnswer",
        back_populates="interview_session",
        cascade="all, delete-orphan",
        order_by="InterviewAnswer.sequence_order",
    )
    conversation = relationship(
        "ChatbotConversation",
        back_populates="interview_session",
        cascade="all, delete-orphan",
        order_by="ChatbotConversation.message_order",
    )
    risk_assessment = relationship(
        "RiskAssessment", back_populates="interview_session", uselist=False, foreign_keys="RiskAssessment.interview_session_id"
    )


class InterviewAnswer(Base):
    __tablename__ = "interview_answers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    interview_session_id = Column(UUID(as_uuid=True), ForeignKey("interview_sessions.id", ondelete="CASCADE"), nullable=False)
    interview_question_id = Column(UUID(as_uuid=True), ForeignKey("interview_questions.id"), nullable=True)
    question_text_ar_snapshot = Column(Text, nullable=False)
    answer_text_ar = Column(Text, nullable=True)
    answer_value_numeric = Column(Numeric(5, 2), nullable=True)
    sentiment_label = Column(String(50), nullable=True)
    sentiment_score = Column(Numeric(4, 3), nullable=True)
    sequence_order = Column(Integer, nullable=False)
    asked_at = Column(DateTime(timezone=True), server_default=func.now())

    interview_session = relationship("InterviewSession", back_populates="answers")
    interview_question = relationship("InterviewQuestion", back_populates="answers")


class ChatbotConversation(Base):
    __tablename__ = "chatbot_conversations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    interview_session_id = Column(UUID(as_uuid=True), ForeignKey("interview_sessions.id", ondelete="CASCADE"), nullable=False)
    sender = Column(PgEnum(ChatSender, name="chat_sender", create_type=True), nullable=False)
    message_text_ar = Column(Text, nullable=False)
    message_order = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    interview_session = relationship("InterviewSession", back_populates="conversation")
