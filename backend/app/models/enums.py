import enum


class UserRole(str, enum.Enum):
    patient = "patient"
    admin = "admin"
    clinical_supervisor = "clinical_supervisor"


class Gender(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"


class ActivityLevel(str, enum.Enum):
    sedentary = "sedentary"
    light = "light"
    moderate = "moderate"
    active = "active"


class SocialSupportLevel(str, enum.Enum):
    none = "none"
    low = "low"
    medium = "medium"
    high = "high"


class SessionStatus(str, enum.Enum):
    in_progress = "in_progress"
    completed = "completed"
    abandoned = "abandoned"


class TriggerType(str, enum.Enum):
    daily_checkin = "daily_checkin"
    manual = "manual"
    follow_up = "follow_up"
    scheduled = "scheduled"


class QuestionCategory(str, enum.Enum):
    anxiety = "anxiety"
    stress = "stress"
    sadness = "sadness"
    burnout = "burnout"
    sleep = "sleep"
    adherence = "adherence"
    social_isolation = "social_isolation"
    adaptation = "adaptation"
    general = "general"


class QuestionType(str, enum.Enum):
    open_text = "open_text"
    scale_1_5 = "scale_1_5"
    yes_no = "yes_no"
    multiple_choice = "multiple_choice"


class ChatSender(str, enum.Enum):
    bot = "bot"
    patient = "patient"


class MoodSource(str, enum.Enum):
    manual = "manual"
    interview_derived = "interview_derived"


class RecommendationCategory(str, enum.Enum):
    breathing_exercise = "breathing_exercise"
    relaxation = "relaxation"
    sleep_tip = "sleep_tip"
    stress_management = "stress_management"
    motivational = "motivational"
    educational = "educational"
    professional_help = "professional_help"
    direct_supervisor = "direct_supervisor"
    ai_personalized = "ai_personalized"


class NotificationType(str, enum.Enum):
    daily_checkin = "daily_checkin"
    follow_up = "follow_up"
    mood_reminder = "mood_reminder"
    recommendation_alert = "recommendation_alert"
    engagement = "engagement"
    risk_alert_admin = "risk_alert_admin"


class NotificationStatus(str, enum.Enum):
    pending = "pending"
    sent = "sent"
    failed = "failed"


class ReportType(str, enum.Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"


class ContentType(str, enum.Enum):
    article = "article"
    tip = "tip"
    faq = "faq"
    onboarding_text = "onboarding_text"
    ui_label = "ui_label"
