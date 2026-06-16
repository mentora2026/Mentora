"""
Basic end-to-end smoke test for the Step 2 backend.

Requires a running PostgreSQL instance reachable via DATABASE_URL and a
freshly-seeded database (`python -m app.seed`).

Run with: pytest tests/test_e2e_smoke.py -v
"""

import uuid

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


@pytest.fixture(scope="module")
def patient_headers():
    email = f"patient_{uuid.uuid4().hex[:8]}@example.com"
    r = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd!", "full_name": "مريض تجريبي"},
    )
    assert r.status_code == 201
    token = r.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_get_profile(patient_headers):
    r = client.get("/api/v1/patients/me", headers=patient_headers)
    assert r.status_code == 200


def test_list_chronic_conditions():
    r = client.get("/api/v1/conditions")
    assert r.status_code == 200
    assert len(r.json()) >= 1


def test_full_interview_flow(patient_headers):
    r = client.post("/api/v1/interviews/start", json={"trigger_type": "manual"}, headers=patient_headers)
    assert r.status_code == 201
    session_id = r.json()["session"]["id"]

    for _ in range(25):
        r = client.post(
            f"/api/v1/interviews/{session_id}/answer",
            json={"answer_text_ar": "أشعر بأنني بخير بشكل عام."},
            headers=patient_headers,
        )
        assert r.status_code == 200
        if r.json()["is_session_ended"]:
            break
    else:
        pytest.fail("Interview session did not terminate within 25 turns")

    r = client.get("/api/v1/risk-assessments/latest", headers=patient_headers)
    assert r.status_code == 200
    assert 1 <= r.json()["risk_level"] <= 5

    r = client.get("/api/v1/recommendations/me", headers=patient_headers)
    assert r.status_code == 200
    assert len(r.json()) > 0


def test_admin_endpoints_require_admin_role(patient_headers):
    r = client.get("/api/v1/admin/users", headers=patient_headers)
    assert r.status_code == 403
