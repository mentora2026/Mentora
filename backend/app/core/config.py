from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Central application configuration loaded from environment variables / .env file.
    """

    APP_NAME: str = "Adaptive Psychological Monitoring Platform"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    SEED_ON_STARTUP: bool = False

    # Security
    SECRET_KEY: str = "change-this-to-a-long-random-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Database
    DATABASE_URL: str = "postgresql+psycopg2://postgres:postgres@db:5432/psych_platform"

    # Firebase Cloud Messaging
    FCM_SERVER_KEY: str = ""

    # AI / NLP - Sentiment Analysis (Step 3)
    HF_SENTIMENT_MODEL: str = "CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment"
    ENABLE_HF_SENTIMENT: bool = False  # set true once the model is available/downloaded
    SENTIMENT_EMOTION_THRESHOLD: float = 0.5  # confidence above which an emotion triggers escalation

    # AI / LLM Wrapper (Step 3) - used ONLY for rephrasing, summarization, and explanation text
    ENABLE_LLM: bool = False
    LLM_PROVIDER: str = "nvidia"
    LLM_BASE_URL: str = "https://integrate.api.nvidia.com/v1"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "deepseek-ai/deepseek-v4-pro"

    # Interview engine tuning
    INTERVIEW_MIN_QUESTIONS: int = 5
    INTERVIEW_MAX_QUESTIONS: int = 15

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


settings = Settings()
