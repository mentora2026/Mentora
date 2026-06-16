"""
Step 5 Admin Dashboard backend tests: patient detail and interview detail
endpoints added to support the admin dashboard's patient/interview views.
"""

import uuid

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


@pytest.fixture
def admin_headers():
    r = client.post("/api/v1/auth/login", json={"email": "admin@platform.example", "password": "ChangeMe123!"})
    assert r.status_code == 200
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
def patient_with_session():
    email = f"admintest_{uuid.uuid4().hex[:8]}@example.com"
    r = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd!", "full_name": "مريض لوحة التحكم"},
    )
    assert r.status_code == 201
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}

    me = client.get("/api/v1/auth/me", headers=headers).json()

    conditions = client.get("/api/v1/conditions", headers=headers).json()
    cancer = next(c for c in conditions if c["code"] == "cancer")
    client.post(
        "/api/v1/patients/me/conditions",
        json={"chronic_condition_id": cancer["id"], "is_primary": True},
        headers=headers,
    )

    r = client.post("/api/v1/interviews/start", json={"trigger_type": "manual"}, headers=headers)
    session_id = r.json()["session"]["id"]

    for _ in range(20):
        r = client.post(
            f"/api/v1/interviews/{session_id}/answer",
            json={"answer_text_ar": "أشعر بقلق من المستقبل وحزن شديد بسبب وضعي الصحي"},
            headers=headers,
        )
        if r.json()["is_session_ended"]:
            break

    return {"user_id": me["id"], "session_id": session_id, "headers": headers}


def test_patient_detail_endpoint(admin_headers, patient_with_session):
    user_id = patient_with_session["user_id"]
    r = client.get(f"/api/v1/admin/users/{user_id}/patient-detail", headers=admin_headers)
    assert r.status_code == 200
    data = r.json()

    assert data["user_id"] == user_id
    assert any(c["code"] == "cancer" for c in data["conditions"])
    assert len(data["interview_sessions"]) >= 1
    assert len(data["risk_history"]) >= 1
    assert 1 <= data["risk_history"][0]["risk_level"] <= 5


def test_admin_interview_detail_endpoint(admin_headers, patient_with_session):
    session_id = patient_with_session["session_id"]
    r = client.get(f"/api/v1/admin/interviews/{session_id}", headers=admin_headers)
    assert r.status_code == 200
    data = r.json()

    assert data["id"] == session_id
    assert data["patient_full_name"] == "مريض لوحة التحكم"
    assert len(data["conversation"]) > 0
    assert len(data["answers"]) > 0
    # At least one answer should have a sentiment label from the Step 3 engine.
    assert any(a["sentiment_label"] is not None for a in data["answers"])
    assert data["risk_assessment"] is not None
    assert 1 <= data["risk_assessment"]["risk_level"] <= 5


def test_risk_monitoring_includes_user_id(admin_headers, patient_with_session):
    r = client.get("/api/v1/admin/risk-monitoring", headers=admin_headers)
    assert r.status_code == 200
    entries = r.json()
    assert any(e["user_id"] == patient_with_session["user_id"] for e in entries)


def test_patient_detail_requires_admin(patient_with_session):
    user_id = patient_with_session["user_id"]
    headers = patient_with_session["headers"]
    r = client.get(f"/api/v1/admin/users/{user_id}/patient-detail", headers=headers)
    assert r.status_code == 403
