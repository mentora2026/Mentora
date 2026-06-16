# Academic Report Sections
## Adaptive Psychological Monitoring and Support Platform for Chronic Disease Patients Using Conversational AI

> This document provides the Methodology, Results, and Ethical
> Considerations sections intended for inclusion in the graduation project
> report. It complements (and cross-references) `01_Final_Architecture.md`,
> which covers technical architecture in depth.

---

## 1. Methodology

### 1.1 Problem Statement

Patients with chronic diseases (diabetes, hypertension, heart disease, kidney
failure, cancer, asthma) face elevated risk of anxiety, depression, burnout,
and treatment non-adherence, but psychological wellbeing is rarely monitored
between clinical visits. This project investigates whether an adaptive,
conversational AI interviewer - one that adjusts its questions based on a
patient's chronic condition(s) and real-time emotional responses - can
provide continuous, low-burden psychological monitoring and surface
actionable risk signals to clinical staff.

### 1.2 Development Approach

The project was executed in seven sequential steps, each producing a
reviewable, working artifact before proceeding:

1. Architecture & Design - database schema (16 tables), REST API design,
   Adaptive Interview Engine design, Disease Knowledge Layer, Risk Assessment
   Logic, Recommendation Engine logic.
2. Backend Development - FastAPI + PostgreSQL implementation of the schema
   and CRUD APIs, with rule-based placeholder engines, verified via a full
   end-to-end manual test (register, profile, conditions, interview, risk,
   recommendations, mood, reports, admin).
3. AI Engine Development - replaced placeholders with the Sentiment Analysis
   Engine (hybrid Hugging Face model + Arabic lexicon), Crisis Detection, a
   sentiment-driven Risk Engine, and an escalation-aware Adaptive Interview
   Engine, plus an optional LLM Wrapper for Arabic text refinement.
4. Mobile Application - Flutter patient app (Arabic/RTL), 44 Dart files,
   covering authentication, onboarding, the adaptive chat interface, mood
   tracking, recommendations, and reports with charts.
5. Admin Dashboard - React + Vite + Tailwind web dashboard for
   admin/clinical_supervisor roles, with two new backend endpoints added to
   support patient-detail and interview-detail views.
6. Testing - 74 backend tests (58 unit covering pure AI-engine logic plus 16
   integration covering full API flows including a crisis scenario), plus 5
   Flutter widget/unit test files.
7. Documentation - this report, the final architecture write-up, a
   deployment guide, and an Arabic user manual.

### 1.3 Hybrid Rule-Based + AI Design

A central methodological decision was to make the system hybrid rather than
purely LLM-driven, for three reasons: first, explainability - clinical staff
need to understand why a patient was classified at a given risk level;
second, safety - crisis detection must be deterministic and not depend on a
model's probabilistic output; third, practicality - the system must function
fully offline or without paid API access for academic evaluation.

Concretely:

- Interview flow control (which category to ask about next, when to
  escalate, when to stop) is rule-based, driven by a per-disease "Disease
  Knowledge Layer" configuration (priority categories, emotional patterns,
  risk indicators, stored as JSON per chronic condition).
- Sentiment classification is the one genuinely "AI" component: it runs in a
  lexicon-based mode by default (curated Arabic keyword lists per emotion -
  anxiety, stress, sadness, burnout, frustration, positive), with an optional
  drop-in Hugging Face Arabic sentiment model
  (CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment) when
  ENABLE_HF_SENTIMENT=true.
- Crisis detection is a deterministic keyword-match safety net that overrides
  all other logic and forces Risk Level 5.
- LLM usage (Anthropic API) is strictly limited to rephrasing and summarizing
  Arabic text for readability, never to classification decisions - and the
  system is fully functional with ENABLE_LLM=false (the default).

### 1.4 Risk Scoring Methodology

The Risk Engine computes six 0-10 dimension scores (anxiety, stress, sadness,
burnout, sleep quality, treatment adherence) from the interview's sentiment
labels and scale_1_5 answers, applies per-disease weight adjustments from the
Disease Knowledge Layer (for example, for diabetes a "burnout" signal also
slightly elevates the "adherence" concern), and combines them into a 0-100
composite score using fixed weights (anxiety, stress, and burnout weighted at
0.20 each, sadness at 0.15, sleep and adherence at 0.125 each). The composite
score, combined with the trend versus the patient's previous assessment, maps
to one of five risk levels via fixed thresholds (see
`01_Final_Architecture.md`, Section 2.5). This mapping (`score_to_level`) was
implemented as a pure function specifically so its boundary behavior could be
exhaustively unit-tested.

### 1.5 Recommendation Selection Methodology

After each completed interview, the Recommendation Engine selects up to three
items from an admin-curated catalog by excluding items not applicable to the
patient's new risk level, excluding disease-specific items for diseases the
patient doesn't have, excluding items delivered within the last seven days,
ranking disease-specific items above generic items, and taking the top three.
This selection logic (`filter_and_score_candidates`) is also a pure function,
unit-tested against nine scenarios covering each rule in isolation and in
combination.

---

## 2. Results

### 2.1 Functional Completeness

All seven planned steps were completed and verified:

| Deliverable | Status | Verification |
|---|---|---|
| Database schema (16 tables) | Complete | `app.seed` creates and populates all tables; verified via SQLAlchemy model introspection |
| REST API (43 endpoints, 10 groups) | Complete | OpenAPI schema generation verified; interactive docs at `/docs` |
| Adaptive Interview Engine | Complete | End-to-end test drives a full session with escalation |
| Sentiment Analysis Engine | Complete | 6 emotion categories classified correctly in lexicon mode; HF model swap-in verified to not change the API contract |
| Crisis Detection | Complete | Dedicated test confirms crisis language leads to Level 5, an admin notification, and a professional_help recommendation |
| Risk Assessment Engine | Complete | All 11 score-to-level boundary/trend combinations unit-tested |
| Recommendation Engine | Complete | 9 unit tests cover filtering, prioritization, and limits |
| Mobile App (Flutter, Arabic/RTL) | Complete | 44 Dart files; manual structural review (no Flutter SDK in build sandbox) |
| Admin Dashboard (React, Arabic/RTL) | Complete | `npm run build` succeeds; live end-to-end test against running backend covering all 10 endpoint groups |
| Test Suite | Complete | 74/74 backend tests pass (`pytest -m unit` and `-m integration`); 5 Flutter test files |

### 2.2 Test Results Summary

```
$ pytest -m unit -q
58 passed in 0.85s

$ pytest -m integration -q
16 passed in 5.12s

$ pytest -q
74 passed in 5.25s
```

Test breakdown by area:

| Area | Unit Tests | Integration Tests |
|---|---|---|
| Risk Engine (score_to_level, explanations) | 18 | - |
| Recommendation Engine (selection logic) | 9 | - |
| Interview Engine (category ordering, termination, emotion aggregation) | 16 | - |
| Sentiment Engine (per-emotion classification, edge cases) | 15 | - |
| End-to-end API flow (Step 2) | - | 4 |
| AI Engine integration (sentiment, crisis, escalation - Step 3) | - | 8 |
| Admin dashboard endpoints (Step 5) | - | 4 |

### 2.3 Illustrative Scenario: Crisis Language Detection

A dedicated integration test (`test_crisis_language_forces_risk_level_5` in
`tests/test_ai_engine.py`) submits an answer containing explicit
self-harm-related Arabic phrasing during an otherwise-normal interview. The
observed behavior matches the design exactly:

1. `InterviewEngine.submit_answer` detects the crisis keywords via
   `crisis_detection.py` before any other processing.
2. The session is immediately ended (`is_session_ended=true`,
   `total_questions_asked` frozen at its current value).
3. The Risk Engine is invoked with `crisis_detected=True`, which
   short-circuits `score_to_level` to return `(5, "crisis_language_detected")`
   regardless of the computed composite score.
4. A `professional_help`-category recommendation is created for the patient.
5. A `risk_alert_admin` notification is created for all `admin` and
   `clinical_supervisor` users.

### 2.4 Illustrative Scenario: Disease-Aware Escalation

A second integration test drives a diabetes patient through several answers
expressing burnout-related sentiment. Because the diabetes
`knowledge_config_json.emotional_patterns` maps "burnout" to an "adherence"
follow-up, the Question Selector's next question specifically probes
medication/treatment adherence - demonstrably different from the question
sequence a non-diabetic patient with the same sentiment history would
receive. This confirms the Disease Knowledge Layer meaningfully alters
interview content, not just risk scoring.

### 2.5 Known Limitations

- **Sentiment accuracy**: the default lexicon-based classifier is a curated
  keyword approach, not a trained classifier; it handles clear emotional
  language well but may miss subtle or sarcastic expressions. The optional
  Hugging Face model (`ENABLE_HF_SENTIMENT=true`) improves this but requires
  additional dependencies (`requirements-ai.txt`, including PyTorch) not
  installed by default.
- **Mobile app build verification**: the development sandbox had no network
  access to Flutter's package/SDK infrastructure, so the mobile app could not
  be compiled or run in an emulator during development. All 44 Dart files
  were manually reviewed for syntax correctness, brace/parenthesis balance,
  and Flutter API compatibility (including SDK-version-sensitive APIs like
  `Color.withValues` and `DropdownButtonFormField`), but a `flutter run` and
  `flutter test` pass on a developer machine is recommended before
  submission.
- **Push notifications**: `POST /devices/register` exists on the backend and
  is wired into the mobile repository layer, but FCM integration (Firebase
  setup, token retrieval, permission requests) was deferred - see
  `mobile/README.md` Section 7 for the remaining steps.
- **Single-database deployment**: the system is a modular monolith (per Step
  1's own academic-scope recommendation), not a distributed microservice
  architecture. This is appropriate for the project's scale but would need
  revisiting for a multi-tenant production deployment.

---

## 3. Ethical Considerations

### 3.1 Non-Diagnostic Framing

Every patient-facing surface (mobile app disclaimer text, risk-level labels,
recommendation content) explicitly frames the platform as not providing
medical or psychological diagnosis. The Arabic disclaimer
(`AppStrings.disclaimer` in the mobile app, and repeated in the user manual)
states this directly, and risk levels are labeled with severity-neutral terms
("stable", "mild concern", and so on) rather than clinical diagnostic terms.

### 3.2 Crisis Safety Design

The crisis-detection override (Section 2.3) was designed so that no
sentiment score, risk threshold, or LLM call can suppress it - it is the
first check performed on every answer, implemented as a simple keyword match
specifically so its behavior is predictable and auditable. When triggered:

- The patient receives an immediate, warm, non-judgmental message
  acknowledging their experience and ending the session.
- A `professional_help` recommendation is attached.
- Clinical staff are notified immediately via the admin notification system.

This mirrors general AI-safety guidance that systems handling potential
self-harm signals should prioritize connecting the person to human support
over continuing any automated interaction.

### 3.3 Data Privacy and Access Control

- All interview content, mood entries, and risk assessments are tied to a
  `patient_profile_id` and accessible only to the patient themselves via
  JWT-authenticated `/patients/me`-scoped endpoints, and to `admin` /
  `clinical_supervisor` roles via `/admin/*` endpoints, enforced by FastAPI
  dependency injection (`get_current_patient_profile`, admin role checks).
- Passwords are hashed with bcrypt (via `passlib`), never stored in
  plaintext.
- JWTs are short-lived (30 minutes by default) with a separate longer-lived
  refresh token, limiting the window of exposure if a token is leaked.
- The admin dashboard explicitly rejects login from `patient`-role accounts
  client-side, in addition to server-side role checks on `/admin/*`.

### 3.4 Transparency and Explainability

Every risk assessment includes both a machine-readable
`explanation_factors_json` (dimension scores, which factors contributed, the
trend, and whether crisis language was detected) and a human-readable
`explanation_ar` describing why the patient received that classification in
plain Arabic. This directly supports the Step 1 requirement for transparent
risk scoring and allows clinical staff to audit automated classifications
rather than treat them as an opaque black box.

### 3.5 Avoiding Over-Reliance on AI

Per the project's design philosophy (Section 1.3) and consistent with general
AI-safety best practice, the system is explicitly designed to augment, not
replace, human clinical judgment:

- Risk Level 5 always triggers a human notification - the system never
  attempts to handle a crisis autonomously beyond the immediate supportive
  message and session termination.
- Recommendations are informational/self-help in nature (breathing exercises,
  sleep tips, educational content) except at high risk levels, where the
  recommendation itself is to seek professional help - the system does not
  attempt to provide therapy.
- The admin dashboard's patient-detail and interview-detail views are
  designed for human review of every AI-generated classification, not as a
  replacement for that review.

### 3.6 Language and Accessibility

All patient- and admin-facing content is in Arabic with correct RTL layout,
reflecting the target user population. This was treated as a first-class
requirement throughout: `AppStrings` centralizes around eighty Arabic UI
strings in the mobile app specifically so translation consistency could be
reviewed in one place, and the admin dashboard's typography (Amiri plus IBM
Plex Sans Arabic) was chosen for Arabic legibility rather than using default
Latin-first web fonts.
