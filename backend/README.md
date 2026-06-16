# Backend — Adaptive Psychological Monitoring and Support Platform

Step 3 deliverable: AI Engine Development, built on top of the Step 2 FastAPI
backend. Implements the Hybrid AI Architecture from Step 1 Section 7/9:

- **Sentiment Analysis Engine** (`app/services/sentiment_engine.py`): hybrid
  Hugging Face Arabic sentiment model + curated Arabic emotion lexicon,
  classifying each free-text answer as `anxiety | stress | sadness | burnout |
  frustration | positive | neutral`.
- **Crisis Language Detection** (`app/services/crisis_detection.py`): safety
  override per Step 1 Section 7.5 - forces Risk Level 5 and alerts admins.
- **Risk Assessment Engine** (`app/services/risk_engine.py`): now computes
  dimension scores from real sentiment labels + Disease Knowledge Layer
  adjustments (`emotional_patterns` / `risk_indicators`).
- **Adaptive Interview Engine** (`app/services/interview_engine.py`): adds
  sentiment-driven escalation (probing deeper into a disease-relevant category
  when a strong emotion is detected) and LLM-assisted question rephrasing.
- **LLM Wrapper** (`app/services/llm_wrapper.py`): Arabic question rephrasing,
  session summarization, and risk-explanation refinement - with safe
  template-based fallbacks when no LLM is configured.

> **Practical-by-design**: every AI component degrades gracefully. With
> `ENABLE_HF_SENTIMENT=false` (default) and `ENABLE_LLM=false` (default), the
> platform runs fully on lexicon + rule-based logic - no GPU, model download,
> or API key required. Enabling either setting transparently upgrades the
> corresponding component without any API changes.

## 1. Tech Stack

- **Framework**: FastAPI
- **ORM**: SQLAlchemy 2.0
- **Database**: PostgreSQL 16
- **Auth**: JWT (access + refresh tokens), bcrypt password hashing
- **Migrations**: Alembic

## 2. Project Structure

```
backend/
├── app/
│   ├── core/            # config, database session, security (JWT/hashing)
│   ├── models/           # SQLAlchemy ORM models (16 tables from Step 1 schema)
│   ├── schemas/          # Pydantic request/response schemas
│   ├── api/v1/            # API route modules (auth, patients, interviews, ...)
│   ├── services/          # Adaptive Interview Engine, Risk Engine, Recommendation Engine
│   ├── seed.py             # seed script: chronic conditions, sample questions, recommendations, admin user
│   └── main.py             # FastAPI app entrypoint
├── alembic/                # database migrations
├── tests/                  # smoke tests
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

## 3. Running with Docker (recommended)

```bash
cd backend
cp .env.example .env
# edit .env and set a strong SECRET_KEY

docker compose up --build
```

This starts PostgreSQL and the FastAPI app on `http://localhost:8000`.

Then seed the database (in a separate terminal):

```bash
docker compose exec backend python -m app.seed
```

Interactive API docs are available at `http://localhost:8000/docs`.

## 4. Running Locally (without Docker)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Make sure PostgreSQL is running and a database named `psych_platform` exists
export DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:5432/psych_platform"

python -m app.seed          # create tables + seed reference data
uvicorn app.main:app --reload
```

## 5. Database Migrations (Alembic)

The schema can also be created/evolved via Alembic instead of
`Base.metadata.create_all()` (used by `app.seed` for convenience):

```bash
alembic revision --autogenerate -m "initial schema"
alembic upgrade head
```

## 6. Default Seed Accounts

After running `python -m app.seed`:

| Role  | Email                     | Password      |
|-------|---------------------------|----------------|
| Admin | admin@platform.example    | ChangeMe123!   |

> Change this password immediately in any non-local environment.

## 7. Key API Groups (see `/docs` for full schema)

| Group | Prefix |
|---|---|
| Authentication | `/api/v1/auth` |
| Patient Profile | `/api/v1/patients`, `/api/v1/conditions` |
| Adaptive Interview | `/api/v1/interviews` |
| Mood Tracking | `/api/v1/mood-entries` |
| Risk Assessment | `/api/v1/risk-assessments` |
| Recommendations | `/api/v1/recommendations` |
| Notifications | `/api/v1/notifications`, `/api/v1/devices` |
| Reports & Analytics | `/api/v1/reports` |
| Admin Dashboard | `/api/v1/admin` |

## 8. Admin Dashboard Endpoints (Step 5)

In addition to the groups above, `app/api/v1/admin.py` provides:

- `GET /admin/users/{user_id}/patient-detail` - full patient profile,
  conditions, interview history, and risk-assessment history.
- `GET /admin/interviews/{session_id}` - full conversation transcript,
  per-answer sentiment labels, and the resulting risk assessment.
- `GET /admin/risk-monitoring`, `/admin/recommendations`,
  `/admin/content-library`, `/admin/analytics/overview`, `/admin/audit-logs`.

See `admin-dashboard/README.md` for the corresponding frontend.

## 9. AI Engine Configuration (Step 3)

All AI settings live in `.env` (see `.env.example`):

| Setting | Default | Description |
|---|---|---|
| `ENABLE_HF_SENTIMENT` | `false` | When `true`, loads the Hugging Face Arabic sentiment model (`HF_SENTIMENT_MODEL`) on first use. Requires `pip install -r requirements-ai.txt`. |
| `HF_SENTIMENT_MODEL` | `CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment` | Arabic sentiment model used for polarity detection. |
| `SENTIMENT_EMOTION_THRESHOLD` | `0.5` | Confidence above which a detected emotion triggers Question Selector escalation. |
| `ENABLE_LLM` | `false` | When `true`, enables the LLM Wrapper (Arabic rephrasing, summaries, explanations) via Anthropic's API. |
| `LLM_API_KEY` | _(empty)_ | API key for the configured LLM provider. |
| `LLM_MODEL` | `claude-sonnet-4-6` | Model used for Arabic generation tasks. |

### How it works without any AI keys/models (default)

- **Sentiment**: a curated Arabic emotion lexicon (anxiety, stress, sadness,
  burnout, frustration, positive) directly classifies each free-text answer.
- **Question rephrasing / summaries / explanations**: deterministic
  Arabic templates are used (see `_template_session_summary_ar`, etc.).
- The full Adaptive Interview Engine — including disease-aware escalation
  and crisis-language detection — works identically in this mode.

### Enabling the real Hugging Face model

```bash
pip install -r requirements-ai.txt
# in .env:
ENABLE_HF_SENTIMENT=true
```

### Enabling the LLM Wrapper

```bash
# in .env:
ENABLE_LLM=true
LLM_API_KEY=sk-ant-...
```

## 10. Running the Test Suite (Step 6)

```bash
# Unit tests only (pure logic, no database needed - instant)
pytest -m unit -v

# Integration tests only (require a seeded PostgreSQL database via DATABASE_URL)
pytest -m integration -v

# Everything
pytest -v
```

Test files:

- `tests/test_risk_engine_unit.py` (unit): Risk Assessment Logic - score-to-level
  mapping (Step 1 Section 7.5 boundaries/trend escalation) and Arabic
  explanation generation.
- `tests/test_recommendation_engine_unit.py` (unit): Recommendation Engine
  selection logic (Step 1 Section 8.2) - risk-level filtering, disease-specific
  vs generic prioritization, recently-delivered exclusion, top-N limiting.
- `tests/test_interview_engine_unit.py` (unit): Adaptive Interview Engine -
  Disease Knowledge Layer priority-category merging, dominant-emotion
  extraction, and the depth/termination controller's rules (Step 1 Section 5.2.4).
- `tests/test_sentiment_engine_unit.py` (unit): Sentiment Analysis Engine -
  per-emotion classification (anxiety/stress/sadness/burnout/frustration/positive),
  edge cases (empty/None/long input), and graceful degradation when the
  Hugging Face model is disabled.
- `tests/test_e2e_smoke.py` (integration): Step 2 end-to-end flow (auth, profile,
  interview, risk, recommendations, mood, reports, admin access control).
- `tests/test_ai_engine.py` (integration): Step 3 AI engine tests - sentiment
  classification within a live session, crisis-language detection, disease-aware
  escalation, and sentiment-driven risk scoring (including a full crisis-language
  scenario that forces Risk Level 5 and triggers an admin notification +
  `professional_help` recommendation).
- `tests/test_admin_dashboard.py` (integration): Step 5 admin endpoints -
  patient detail, interview detail with sentiment annotations, risk monitoring,
  and admin-only access control.

`tests/conftest.py` automatically tags every file ending in `_unit.py` with
the `unit` marker and everything else with `integration`.

## 11. Next Steps (Step 7)

- Final documentation: consolidated setup guide, API reference, and academic
  report sections (methodology, results, ethics) covering the full platform
  (backend, AI engine, mobile app, admin dashboard).
