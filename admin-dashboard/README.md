# Admin Dashboard — Adaptive Psychological Monitoring and Support Platform

Step 5 deliverable: a React + Vite admin web dashboard implementing the
Admin Dashboard Structure defined in Step 1 (Section 11), in Arabic with RTL
layout, for admins and clinical supervisors monitoring the platform.

## 1. Tech Stack

- **Framework**: React 18 + Vite
- **Styling**: Tailwind CSS (custom design tokens - see "Design" below)
- **Routing**: `react-router-dom`
- **Charts**: `recharts` (risk-level distribution bar chart)
- **Auth**: JWT (access + refresh), stored in `localStorage`, with automatic
  refresh-token retry on 401 (mirrors the mobile app's `ApiClient`)

## 2. Setup

```bash
cd admin-dashboard
cp .env.example .env   # set VITE_API_BASE_URL if not using the default
npm install
npm run dev
```

Open `http://localhost:5173`. Log in with the seeded admin account (see
`backend/README.md`): `admin@platform.example` / `ChangeMe123!`.

### Build for production

```bash
npm run build
npm run preview   # serve the production build locally
```

## 3. Backend Requirements

This dashboard consumes the `/api/v1/admin/*` endpoints from the Step 2/3/5
backend. Two endpoints were added in Step 5 specifically for this dashboard
(see `backend/app/api/v1/admin.py` and `backend/app/schemas/admin.py`):

- `GET /admin/users/{user_id}/patient-detail` - profile, chronic conditions,
  interview session history, and risk-assessment history for a single patient.
- `GET /admin/interviews/{session_id}` - now returns the full conversation,
  per-answer sentiment labels/scores (from the Step 3 AI engine), and the
  associated risk assessment with its explanation and sub-scores.
- `GET /admin/risk-monitoring` entries now include `user_id` (in addition to
  `patient_profile_id`) so the dashboard can link directly to the patient
  detail page.
- `GET /admin/recommendations` (and create/update) now return the full
  `AdminRecommendationOut` shape, including `applicable_risk_levels`,
  `chronic_condition_id`, and `is_active`.

All other endpoints were already implemented in Step 2.

## 4. Pages

| Route | Page | Description |
|---|---|---|
| `/login` | Login | Admin/clinical-supervisor sign-in. Non-admin accounts are rejected. |
| `/` | نظرة عامة (Overview) | Stat cards (total patients, active last 7 days, sessions last 30 days) + risk-level distribution bar chart. |
| `/risk-monitoring` | مراقبة الخطر | Patients sorted by latest risk level (highest first), with a banner highlighting Level 4-5 patients needing urgent review. Click a row → patient detail. |
| `/users` | المستخدمون | All users (patients, admins, supervisors). Activate/deactivate accounts. Click a patient row → patient detail. |
| `/users/:userId` | ملف المريض | Profile summary, chronic conditions, full risk-assessment history, and interview session history. Click a session → interview detail. |
| `/interviews/:sessionId` | تفاصيل الجلسة | Full conversation transcript, session summary, per-answer sentiment analysis table, and the resulting risk assessment with sub-scores and explanation. Flags crisis-language detection. |
| `/recommendations` | التوصيات | CRUD for the recommendation catalog (category, target risk levels, optional disease, content). Activate/deactivate entries. |
| `/content-library` | المحتوى التعليمي | Create and list educational content/articles/tips, optionally tied to a chronic condition. |
| `/audit-logs` | سجل التدقيق | Read-only log of administrative actions (e.g., user activation/deactivation). |

## 5. Design

The visual language follows the `frontend-design` skill's principles: a
distinct palette and typographic pairing rather than default Tailwind/shadcn
styling, suited to a clinical monitoring tool for Arabic-speaking staff.

- **Palette**: deep teal (`#0F3D3E`) as the anchor/sidebar color, warm paper
  background (`#F6F5F1`) instead of stark white, muted sage for secondary
  text, and a terracotta accent (`#C9622D`) reserved for alerts/high risk.
- **Typography**: "Amiri" (Arabic-supporting serif) for headings/display text,
  "IBM Plex Sans Arabic" for body text, "IBM Plex Mono" for tabular numbers
  (scores, IDs, dates).
- **Signature element - the "risk spine"**: a thin vertical color bar
  (`RiskSpine` component), color-coded 1-5, used consistently on patient rows
  in Risk Monitoring and on risk-history rows in the patient detail page. The
  same 5-color scale drives the `RiskBadge` component and the Overview bar
  chart, creating one consistent visual vocabulary for "risk" throughout the
  dashboard.
- **RTL**: `<html dir="rtl">`, sidebar on the right, all Arabic UI text.

## 6. Notes

- Only `admin` and `clinical_supervisor` roles can log in; patient accounts
  are rejected with an Arabic error message.
- The dashboard does not implement patient-level write actions beyond
  activate/deactivate (no manual risk-level overrides), consistent with
  Step 1's "Transparent risk scoring" and "Ethical AI recommendations"
  requirements - risk levels are always system-computed.
