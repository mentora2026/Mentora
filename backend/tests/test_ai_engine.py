"""
Step 3 AI Engine tests: sentiment analysis, disease-aware escalation,
crisis-language safety override, and risk scoring driven by sentiment.

Requires a running PostgreSQL instance reachable via DATABASE_URL and a
freshly-seeded database (`python -m app.seed`).
"""

import uuid

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.crisis_detection import contains_crisis_language
from app.services.sentiment_engine import sentiment_engine

client = TestClient(app)


# ---------------------------------------------------------------------------
# Unit tests: Sentiment Engine
# ---------------------------------------------------------------------------
def test_sentiment_engine_detects_anxiety():
    result = sentiment_engine.analyze("أشعر بقلق شديد وخوف من المستقبل")
    assert result.label == "anxiety"
    assert result.score > 0


def test_sentiment_engine_detects_burnout():
    result = sentiment_engine.analyze("أنا مرهق جداً وتعبت من المتابعة المستمرة، ما عندي طاقة")
    assert result.label == "burnout"


def test_sentiment_engine_detects_positive():
    result = sentiment_engine.analyze("الحمدلله أنا بخير ومتحسن هذه الأيام")
    assert result.label == "positive"


def test_sentiment_engine_handles_empty_text():
    result = sentiment_engine.analyze("")
    assert result.label == "neutral"
    assert result.score == 0.0


# ---------------------------------------------------------------------------
# Unit tests: Crisis Detection
# ---------------------------------------------------------------------------
def test_crisis_detection_positive():
    assert contains_crisis_language("أحياناً أفكر في الانتحار ولا أرى فائدة من أي شيء")


def test_crisis_detection_negative():
    assert not contains_crisis_language("أشعر بالتعب اليوم لكنني بخير بشكل عام")


# ---------------------------------------------------------------------------
# Integration: full interview with consistently anxious/burnout answers
# should escalate within the diabetes-specific category and produce a
# non-trivial risk level with sentiment-driven explanation factors.
# ---------------------------------------------------------------------------
@pytest.fixture
def diabetic_patient_headers():
    email = f"diabetic_{uuid.uuid4().hex[:8]}@example.com"
    r = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd!", "full_name": "مريض السكري"},
    )
    assert r.status_code == 201
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    conditions = client.get("/api/v1/conditions", headers=headers).json()
    diabetes = next(c for c in conditions if c["code"] == "diabetes")
    r = client.post(
        "/api/v1/patients/me/conditions",
        json={"chronic_condition_id": diabetes["id"], "is_primary": True},
        headers=headers,
    )
    assert r.status_code == 201
    return headers


def test_interview_with_negative_sentiment_produces_elevated_risk(diabetic_patient_headers):
    headers = diabetic_patient_headers

    r = client.post("/api/v1/interviews/start", json={"trigger_type": "manual"}, headers=headers)
    assert r.status_code == 201
    session_id = r.json()["session"]["id"]

    negative_reply = "أشعر بإرهاق شديد وقلق دائم من تدهور حالتي، وتعبت من المتابعة المستمرة للعلاج."

    for _ in range(20):
        r = client.post(
            f"/api/v1/interviews/{session_id}/answer",
            json={"answer_text_ar": negative_reply},
            headers=headers,
        )
        assert r.status_code == 200
        data = r.json()
        if data["is_session_ended"]:
            break
    else:
        pytest.fail("Interview did not terminate")

    risk = client.get("/api/v1/risk-assessments/latest", headers=headers).json()
    assert risk["risk_level"] >= 2
    assert risk["explanation_factors_json"]["method"] == "step3_sentiment_driven"
    # At least one negative emotion should have been detected and counted.
    emotion_counts = risk["explanation_factors_json"]["emotion_label_counts"]
    assert any(k in emotion_counts for k in ("anxiety", "burnout", "stress"))


def test_crisis_language_forces_level_5_and_ends_session():
    email = f"crisis_{uuid.uuid4().hex[:8]}@example.com"
    r = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd!", "full_name": "مريض بحاجة دعم"},
    )
    assert r.status_code == 201
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}

    r = client.post("/api/v1/interviews/start", json={"trigger_type": "manual"}, headers=headers)
    session_id = r.json()["session"]["id"]

    r = client.post(
        f"/api/v1/interviews/{session_id}/answer",
        json={"answer_text_ar": "أفكر في الانتحار ولا أرى فائدة من حياتي بعد الآن"},
        headers=headers,
    )
    assert r.status_code == 200
    data = r.json()
    assert data["is_session_ended"] is True

    risk = client.get("/api/v1/risk-assessments/latest", headers=headers).json()
    assert risk["risk_level"] == 5
    assert risk["explanation_factors_json"]["crisis_language_detected"] is True

    # Patient should receive a professional_help recommendation.
    recs = client.get("/api/v1/recommendations/me", headers=headers).json()
    categories = [r["recommendation"]["category"] for r in recs]
    assert "professional_help" in categories
