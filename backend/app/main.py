from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.seed import seed

API_DESCRIPTION = """
**Adaptive Psychological Monitoring and Support Platform for Chronic Disease
Patients Using Conversational AI** — Backend API.

This API powers an Arabic-language adaptive conversational interviewer that
monitors the psychological wellbeing of chronic-disease patients, classifies
psychological risk (Levels 1-5), and delivers personalized, non-diagnostic
support content.

### Language Rule
All technical fields (enums, IDs, timestamps) are in English. All
human-readable content returned to clients - chatbot messages, notifications,
recommendations, risk explanations - is in Arabic (`*_ar` fields).

### Authentication
Most endpoints require a JWT access token:
`Authorization: Bearer <access_token>`. Obtain one via `POST /auth/login` or
`POST /auth/register`. Tokens expire after `ACCESS_TOKEN_EXPIRE_MINUTES`
(default 30 min); use `POST /auth/refresh` with the refresh token to renew.

### Roles
- **patient**: default role for registered users; can access `/patients/*`,
  `/interviews/*`, `/mood-entries`, `/risk-assessments`, `/recommendations`,
  `/notifications`, `/reports/*`.
- **admin** / **clinical_supervisor**: can additionally access `/admin/*`.

### Ethical & Safety Notes
- This platform is **not a diagnostic medical system** and does not replace a
  doctor or mental health professional.
- The Adaptive Interview Engine and Risk Assessment Engine are hybrid
  rule-based + AI systems (see Step 1/3 architecture docs); risk levels are
  always system-computed and explainable (`explanation_ar`,
  `explanation_factors_json`).
- If crisis/self-harm language is detected during an interview, the session
  is immediately ended, the patient receives a supportive message and a
  `professional_help` recommendation, and admins/clinical supervisors receive
  a `risk_alert_admin` notification.
"""

TAGS_METADATA = [
    {"name": "Health", "description": "Service health check."},
    {"name": "Authentication", "description": "Registration, login, token refresh, and account management."},
    {
        "name": "Patient Profile",
        "description": "Patient profile management and the master list of chronic conditions.",
    },
    {
        "name": "Adaptive Interview",
        "description": (
            "The Adaptive Interview Engine: starts and progresses a conversational "
            "psychological assessment session, one question at a time, adapting "
            "based on the patient's chronic condition(s), sentiment, and history."
        ),
    },
    {"name": "Mood Tracking", "description": "Lightweight, high-frequency self-reported mood logging."},
    {
        "name": "Risk Assessment",
        "description": (
            "Read-only access to risk assessments produced after each completed "
            "interview session (risk level 1-5, sub-scores, Arabic explanation)."
        ),
    },
    {
        "name": "Recommendations",
        "description": "Personalized, non-diagnostic recommendations delivered based on risk level and chronic condition.",
    },
    {"name": "Notifications", "description": "In-app notifications and FCM device registration."},
    {"name": "Reports & Analytics", "description": "Daily/weekly/monthly summaries, mood trend, and risk progression."},
    {
        "name": "Admin Dashboard",
        "description": (
            "Endpoints for `admin` / `clinical_supervisor` roles: user management, "
            "risk monitoring, interview review, recommendation/content management, "
            "platform analytics, and audit logs."
        ),
    },
]

app = FastAPI(
    title=settings.APP_NAME,
    description=API_DESCRIPTION,
    version="1.0.0",
    openapi_tags=TAGS_METADATA,
)

# CORS - permissive for development; restrict allowed origins in production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")


@app.on_event("startup")
def seed_on_startup() -> None:
    if settings.SEED_ON_STARTUP:
        seed()


@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "app": settings.APP_NAME, "environment": settings.ENVIRONMENT}
