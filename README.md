# Adaptive Psychological Monitoring and Support Platform for Chronic Disease Patients Using Conversational AI

Bachelor's graduation project. An Arabic-language platform that uses an
adaptive conversational AI interviewer to monitor the psychological wellbeing
of chronic-disease patients, classify psychological risk (Levels 1-5), and
deliver personalized, non-diagnostic support content - with a clinical
monitoring dashboard for admin/clinical-supervisor staff.

---

## Project Structure

```
.
├── backend/              Step 2, 3, 5 - FastAPI + PostgreSQL API and AI engine
├── mobile/               Step 4       - Flutter patient app (Arabic/RTL)
├── admin-dashboard/      Step 5       - React admin/clinical dashboard (Arabic/RTL)
├── docs/                 Step 7       - this documentation set
└── Step1_Architecture_Design.md       Original design document
```

Each subfolder has its own `README.md` with setup instructions specific to
that component.

---

## Documentation Index (`docs/`)

| Document | Contents |
|---|---|
| `01_Final_Architecture.md` | As-built system architecture, database schema notes, AI engine module reference, risk-classification formula, and a summary of where the implementation diverged from the original Step 1 design (and why). |
| `02_Deployment_Guide.md` | Step-by-step setup for the backend (Docker and non-Docker), admin dashboard, and mobile app, plus a full environment-variable reference and troubleshooting table. |
| `03_User_Manual_AR.md` | Arabic-language user manual for both patients (mobile app) and admin/clinical staff (dashboard), including an FAQ. |
| `04_Academic_Report_Sections.md` | Methodology, Results, and Ethical Considerations sections for the graduation report. |
| `openapi.json` | Exported OpenAPI 3.1 specification (43 endpoints, 10 tagged groups) - also available live at `/docs` and `/openapi.json` when the backend is running. |

---

## Quick Start

```bash
# 1. Backend
cd backend
cp .env.example .env   # set SECRET_KEY
docker compose up --build
docker compose exec backend python -m app.seed

# 2. Admin Dashboard (new terminal)
cd admin-dashboard
cp .env.example .env
npm install && npm run dev
# -> http://localhost:5173, login: admin@platform.example / ChangeMe123!

# 3. Mobile App (new terminal)
cd mobile
flutter create .
flutter pub get
flutter run
```

See `docs/02_Deployment_Guide.md` for full details, environment variables,
and production deployment notes.

---

## Running the Tests

```bash
# Backend: 74 tests (58 unit, no DB needed; 16 integration, needs seeded PostgreSQL)
cd backend
pytest -m unit -v
pytest -m integration -v

# Mobile: widget/unit tests
cd mobile
flutter test
```

---

## Key Design Principles

1. Arabic-first: every user-facing string (chatbot messages, notifications,
   recommendations, risk explanations, UI labels) is in Arabic with correct
   RTL layout, in both the mobile app and the admin dashboard.
2. Hybrid rule-based + AI: interview flow, risk-level boundaries, and
   recommendation filtering are deterministic and explainable; sentiment
   analysis and optional LLM-based text refinement are the AI components,
   both with safe fallback modes (`ENABLE_HF_SENTIMENT=false`,
   `ENABLE_LLM=false` by default).
3. Non-diagnostic and crisis-safe: the platform never claims to diagnose; a
   deterministic crisis-language detector overrides all other logic, ends the
   session supportively, and immediately notifies clinical staff.
4. Explainable risk scoring: every risk assessment includes both a
   machine-readable factor breakdown and a human-readable Arabic explanation.
5. Tested: 74 backend tests plus 5 mobile test files, separated into fast
   unit tests (pure AI-engine logic) and integration tests (full API flows).

---

## Status

All 7 planned steps are complete:

- [x] Step 1: Architecture & Design
- [x] Step 2: Backend Development
- [x] Step 3: AI Engine Development
- [x] Step 4: Mobile Application
- [x] Step 5: Admin Dashboard
- [x] Step 6: Testing
- [x] Step 7: Documentation
