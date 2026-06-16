# Final System Architecture
## Adaptive Psychological Monitoring and Support Platform for Chronic Disease Patients Using Conversational AI

> Step 7 deliverable. This document describes the system **as built** across
> Steps 2-6, consolidating and updating the original Step 1 design
> (`Step1_Architecture_Design.md`) where implementation diverged or was
> extended.

---

## 1. Overview

The platform consists of four deliverables, each independently runnable:

| Component | Location | Technology | Step |
|---|---|---|---|
| Backend API | `backend/` | FastAPI + PostgreSQL + SQLAlchemy | 2, 3, 5 |
| Mobile App (patients) | `mobile/` | Flutter (Arabic/RTL) | 4 |
| Admin Dashboard | `admin-dashboard/` | React + Vite + Tailwind (Arabic/RTL) | 5 |
| Test Suite | `backend/tests/`, `mobile/test/` | pytest, flutter_test | 6 |

```
┌─────────────────────────┐      ┌──────────────────────────┐
│   Flutter Mobile App     │      │   Admin Dashboard (React)  │
│   (patients, Arabic/RTL) │      │   (admins, Arabic/RTL)     │
└────────────┬─────────────┘      └──────────────┬─────────────┘
             │ HTTPS + JWT                         │ HTTPS + JWT
             ▼                                     ▼
        ┌─────────────────────────────────────────────┐
        │             FastAPI Backend (/api/v1)         │
        │  ┌─────────────┐  ┌────────────────────────┐ │
        │  │ Core Services│  │ AI / NLP Engine Modules │ │
        │  │ (auth, CRUD, │  │ - Adaptive Interview    │ │
        │  │  reports,    │◄►│ - Sentiment Analysis    │ │
        │  │  admin)      │  │ - Risk Engine           │ │
        │  │              │  │ - Recommendation Engine │ │
        │  │              │  │ - LLM Wrapper           │ │
        │  └─────────────┘  └────────────────────────┘ │
        └───────────────────────┬───────────────────────┘
                                  │
                          ┌───────▼────────┐
                          │   PostgreSQL    │
                          │   (16 tables)   │
                          └─────────────────┘
```

This matches the Step 1 "modular monolith + AI service layer" design: the AI
engine modules live under `backend/app/services/` as plain Python modules
imported directly by the API layer - no separate microservice, exactly as
anticipated in Step 1 Section 1.3 for the academic-scope deployment.

---

## 2. Backend (`backend/`)

### 2.1 Layout

```
backend/
├── app/
│   ├── core/        # config, database session, JWT/password security
│   ├── models/       # 16 SQLAlchemy ORM models (matches Step 1 schema)
│   ├── schemas/       # Pydantic request/response schemas
│   ├── api/v1/         # route modules: auth, patients, interviews, mood,
│   │                    # risk, recommendations, notifications, reports, admin
│   ├── services/        # Adaptive Interview Engine, Sentiment Engine,
│   │                      # Crisis Detection, Risk Engine, Recommendation
│   │                      # Engine, LLM Wrapper
│   ├── seed.py            # reference data: 6 chronic conditions + Disease
│   │                        # Knowledge Layer configs, sample questions,
│   │                        # recommendations, default admin account
│   └── main.py             # FastAPI app, OpenAPI metadata, CORS
├── alembic/                 # DB migrations (optional; app.seed also works)
├── tests/                    # 74 tests (58 unit + 16 integration)
├── requirements.txt
├── requirements-ai.txt       # optional Hugging Face / torch
├── Dockerfile
└── docker-compose.yml
```

### 2.2 Database Schema

All 16 tables from the Step 1 design are implemented exactly as specified,
with one intentional normalization: `chronic_conditions` (master list) is
separated from `patient_conditions` (patient-condition junction table) to
correctly support many-to-many relationships, as noted in Step 1 Section 2.4.

Two columns were added beyond the original schema, both additive and
non-breaking:

- `chronic_conditions.knowledge_config_json` (JSONB) - stores the Disease
  Knowledge Layer configuration (priority categories, emotional patterns,
  risk indicators) per Step 1 Section 6.2, editable without redeployment.
- `interview_sessions.context_state_json` (JSONB) - the Adaptive Interview
  Engine's Context Manager working memory (covered categories, emotion
  history, escalation state) per Step 1 Section 5.2.1.

### 2.3 API

43 endpoints across 10 tagged groups (see `docs/openapi.json` or `GET /docs`
for the full interactive reference). All response models use `*_ar` fields
for any text shown to the patient/admin.

### 2.4 AI Engine Modules (`app/services/`)

| Module | Role | Step |
|---|---|---|
| `interview_engine.py` | Adaptive Interview Engine: Context Manager, rule-based Question Selector with Disease Knowledge Layer priorities, sentiment-driven escalation, Depth/Termination Controller, crisis override | 2, 3 |
| `sentiment_engine.py` | Hybrid sentiment/emotion classifier: optional Hugging Face Arabic model + curated Arabic emotion lexicon fallback | 3 |
| `crisis_detection.py` | Keyword-based self-harm/suicidal-language safety override | 3 |
| `risk_engine.py` | Computes 6 sub-scores + composite score from sentiment labels and Disease Knowledge Layer adjustments; maps to Risk Level 1-5 with Arabic explanation | 2, 3 |
| `recommendation_engine.py` | Filters/scores the recommendation catalog by risk level, chronic condition, and recent-delivery history | 2 |
| `llm_wrapper.py` | Arabic question rephrasing, session summarization, risk-explanation refinement via Anthropic API (optional; template fallback otherwise) | 3 |

#### Practical hybrid design (Step 1 Section 7 realized)

- **Rule-based logic** controls interview flow, termination, recommendation
  filtering, and risk-level boundaries - deterministic and explainable.
- **Sentiment analysis** runs in lexicon-only mode by default
  (`ENABLE_HF_SENTIMENT=false`); setting it to `true` (after
  `pip install -r requirements-ai.txt`) swaps in a real Hugging Face Arabic
  model with zero API changes.
- **LLM usage** is opt-in (`ENABLE_LLM=false` by default) and scoped strictly
  to rephrasing/summarization/explanation text, never to risk classification
  or recommendation selection - matching Step 1's "avoid making the entire
  system dependent on LLMs."

### 2.5 Risk Classification (Step 1 Section 8 realized)

```
composite_score (0-100) = 10 x sum( wi x dimension_i )
```

where dimensions are anxiety, stress, sadness, burnout (driven by sentiment
labels/scores on free-text answers) and `(10 - sleep_quality)`,
`(10 - adherence)` (driven by `scale_1_5` answers). Weights:
anxiety/stress/burnout = 0.20, sadness = 0.15, sleep/adherence = 0.125 each.

| Composite Score | Trend | Risk Level |
|---|---|---|
| 0-20 | any | **1 - Stable** |
| 21-40 | stable | **2 - Mild Concern** |
| 21-40 | worsening (>= previous) | **3 - Moderate Risk** |
| 41-65 | stable | **3 - Moderate Risk** |
| 41-65 | worsening | **4 - High Risk** |
| 66-85 | any | **4 - High Risk** |
| 86-100, or crisis language detected | any | **5 - Critical Attention Required** |

Every assessment stores `explanation_factors_json` (machine-readable: scores,
emotion counts, disease adjustments applied, trend, crisis flag) and
`explanation_ar` (human-readable Arabic, LLM-refined if enabled).

---

## 3. Mobile App (`mobile/`)

Flutter app implementing the Step 1 Section 10 structure. Key architectural
points:

- **State management**: `provider` package; one `ChangeNotifier` per feature
  area (`AuthProvider`, `InterviewProvider`, `MoodProvider`, etc.).
- **Networking**: a single `ApiClient` attaches JWT, retries once on 401 after
  refreshing the token, and converts backend error `detail` (Arabic) into
  `ApiException`.
- **Localization**: `AppStrings` centralizes all Arabic UI text; app-wide
  `Directionality: rtl` and `locale: ar`.
- **Adaptive Interview chat**: renders the full conversation as chat bubbles,
  supports both free-text and 1-5 scale answers, shows a typing indicator,
  and surfaces the closing message (including the crisis-support message)
  with a "start new session" action.

---

## 4. Admin Dashboard (`admin-dashboard/`)

React + Vite + Tailwind, also Arabic/RTL, for `admin` /
`clinical_supervisor` roles. Distinct visual identity (deep teal + warm
paper palette, Amiri/IBM Plex Sans Arabic typography, a recurring "risk
spine" color element for risk levels 1-5) per the `frontend-design` skill
guidance - deliberately not a default-Tailwind look.

Two backend endpoints were added specifically to support this dashboard
(Step 5, non-breaking additions):

- `GET /admin/users/{user_id}/patient-detail` - profile + conditions +
  interview history + risk history for one patient.
- `GET /admin/interviews/{session_id}` (enhanced) - full transcript,
  per-answer sentiment labels, and the risk assessment with sub-scores.

---

## 5. Testing (Step 6 realized)

```bash
cd backend && pytest -m unit          # 58 tests, no DB, <1s
cd backend && pytest -m integration   # 16 tests, needs seeded PostgreSQL
cd mobile && flutter test              # 5 widget/unit test files
```

Unit tests target pure functions extracted from the AI engine modules
(`score_to_level`, `filter_and_score_candidates`,
`build_priority_category_order`, `top_emotions`, `SentimentEngine.analyze`,
`InterviewEngine._should_terminate`). Integration tests exercise the full
HTTP API including a complete crisis-language scenario.

---

## 6. Deployment

See `docs/DEPLOYMENT.md` for the full guide. Summary:

```bash
cd backend
cp .env.example .env   # set SECRET_KEY
docker compose up --build
docker compose exec backend python -m app.seed
```

Backend: `http://localhost:8000` (interactive docs at `/docs`). The admin
dashboard and mobile app point at this URL via `VITE_API_BASE_URL` /
`ApiConstants.baseUrl` respectively.

---

## 7. Divergences from the Step 1 Design (Summary)

| Step 1 Design | As Built | Reason |
|---|---|---|
| Single `chronic_conditions` table for patient<->disease | Split into `chronic_conditions` (master) + `patient_conditions` (junction) | Correct many-to-many modeling (flagged as intentional in Step 1 Section 2.4) |
| AI engine as separate logical service | Implemented as Python modules within the same FastAPI app | Matches Step 1's own fallback recommendation for academic scope (Section 1.3) |
| Admin dashboard tech "TBD" | React + Vite + Tailwind | Lightweight, fast to build, good Arabic/RTL + charting (recharts) support |
| `/admin/interviews/:id` returns raw conversation only | Returns conversation + per-answer sentiment + risk assessment | Needed for meaningful "interview monitoring" (Step 1 Section 11.2) |
