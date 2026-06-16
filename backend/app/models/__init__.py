"""
Aggregates all SQLAlchemy models so that `Base.metadata` is fully populated
when this package is imported (required for Alembic autogenerate and
for `Base.metadata.create_all`).
"""

from app.core.database import Base  # noqa: F401

from app.models.patient import (  # noqa: F401
    User,
    PatientProfile,
    ChronicCondition,
    PatientCondition,
)
from app.models.interview import (  # noqa: F401
    InterviewQuestion,
    InterviewSession,
    InterviewAnswer,
    ChatbotConversation,
)
from app.models.misc import (  # noqa: F401
    MoodEntry,
    RiskAssessment,
    Recommendation,
    PatientRecommendation,
    Notification,
    Report,
    ContentLibraryItem,
    AuditLog,
)

__all__ = [
    "Base",
    "User",
    "PatientProfile",
    "ChronicCondition",
    "PatientCondition",
    "InterviewQuestion",
    "InterviewSession",
    "InterviewAnswer",
    "ChatbotConversation",
    "MoodEntry",
    "RiskAssessment",
    "Recommendation",
    "PatientRecommendation",
    "Notification",
    "Report",
    "ContentLibraryItem",
    "AuditLog",
]
