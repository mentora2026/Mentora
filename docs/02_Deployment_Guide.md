# Deployment Guide

This guide covers running the full platform (backend, mobile app, admin
dashboard) locally and in a basic production-like setup (Docker + a hosting
provider such as Render or Railway, per Step 1 Section 9).

---

## 1. Prerequisites

| Component | Requirement |
|---|---|
| Backend | Docker + Docker Compose (recommended), or Python 3.12 + PostgreSQL 16 |
| Admin Dashboard | Node.js 18+ and npm |
| Mobile App | Flutter SDK (stable, Dart >= 3.6) |

---

## 2. Backend

### 2.1 Local development (Docker - recommended)

```bash
cd backend
cp .env.example .env
```

Edit `.env` and set a strong `SECRET_KEY` (any long random string - e.g.
`openssl rand -hex 32`). Leave `DATABASE_URL` as-is; `docker-compose.yml`
overrides it to point at the `db` service.

```bash
docker compose up --build
```

This starts:
- `db`: PostgreSQL 16 on port 5432 (with a healthcheck)
- `backend`: FastAPI on port 8000

Seed reference data (chronic conditions, sample interview questions,
recommendations, and a default admin account):

```bash
docker compose exec backend python -m app.seed
```

Verify:

```bash
curl http://localhost:8000/
```

Interactive API docs: `http://localhost:8000/docs`
(OpenAPI JSON: `http://localhost:8000/openapi.json`, also exported as
`docs/openapi.json` in this repository for offline reference).

### 2.2 Local development (without Docker)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Ensure PostgreSQL is running locally and a `psych_platform` database exists
export DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:5432/psych_platform"

python -m app.seed
uvicorn app.main:app --reload
```

### 2.3 Optional: Real Hugging Face sentiment model

By default the Sentiment Analysis Engine runs in lexicon-only mode (no extra
dependencies). To use the real Arabic sentiment model:

```bash
pip install -r requirements-ai.txt
```

In `.env`:

```ini
ENABLE_HF_SENTIMENT=true
HF_SENTIMENT_MODEL=CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment
```

### 2.4 Optional: LLM Wrapper (Arabic rephrasing/summaries)

In `.env`:

```ini
ENABLE_LLM=true
LLM_PROVIDER=anthropic
LLM_API_KEY=sk-ant-...
LLM_MODEL=claude-sonnet-4-6
```

If `ENABLE_LLM=false` (default) or the API call fails for any reason, the
platform falls back to deterministic Arabic templates - no functionality is
lost.

### 2.5 Production Deployment (Render / Railway)

The Step 1 design recommends Render or Railway for deployment. General steps
for either platform:

1. **Database**: provision a managed PostgreSQL instance. Copy its connection
   string into `DATABASE_URL` (format:
   `postgresql+psycopg2://user:pass@host:port/dbname`).
2. **Web service**: deploy the `backend/` directory using the provided
   `Dockerfile`. Set environment variables from `.env.example`, especially:
   - `SECRET_KEY` - generate a new strong value, never reuse the dev default.
   - `DATABASE_URL` - the managed database's connection string.
   - `ENVIRONMENT=production`, `DEBUG=false`.
3. **CORS**: in `app/main.py`, replace `allow_origins=["*"]` with the actual
   origins of your deployed admin dashboard and any web clients.
4. **Seed data**: run `python -m app.seed` once via the platform's shell/console
   feature (or a one-off job) after the first deploy.
5. **Migrations**: `app.seed` calls `Base.metadata.create_all()`, which is
   sufficient for this project's scope. For ongoing schema changes, use
   Alembic (`alembic upgrade head`) instead - `alembic/env.py` is already
   wired to `DATABASE_URL` and the full model metadata.

---

## 3. Admin Dashboard

```bash
cd admin-dashboard
cp .env.example .env
```

Set `VITE_API_BASE_URL` to the backend's URL (e.g.
`http://localhost:8000/api/v1` for local dev, or
`https://your-backend.onrender.com/api/v1` in production).

```bash
npm install
npm run dev       # development server on http://localhost:5173
```

### Production build

```bash
npm run build     # outputs to dist/
npm run preview   # serve the production build locally for a final check
```

Deploy the contents of `dist/` to any static host (Netlify, Vercel, Render
static site, etc.). Since `VITE_API_BASE_URL` is baked in at build time, set
it in the hosting provider's environment variables *before* running
`npm run build`.

Log in with the seeded admin account: `admin@platform.example` /
`ChangeMe123!` - **change this password immediately** in any non-local
environment (there is currently no "change password" UI in the dashboard;
update it directly via `POST /api/v1/auth/change-password` using a tool like
`curl` or the `/docs` interactive UI, while authenticated as that account).

---

## 4. Mobile App

```bash
cd mobile
flutter create .     # generates android/, ios/, etc. (one-time)
flutter pub get
```

Edit `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = "http://10.0.2.2:8000/api/v1"; // Android emulator -> host localhost
```

- Physical device: use your machine's LAN IP.
- Production: use the deployed backend's HTTPS URL.

```bash
flutter run
```

For app store distribution, follow standard Flutter release steps
(`flutter build apk` / `flutter build ios`) - not covered here as it's
outside this project's academic scope.

---

## 5. Environment Variable Reference

### Backend (`.env`, see `backend/.env.example`)

| Variable | Default | Notes |
|---|---|---|
| `SECRET_KEY` | _(placeholder)_ | **Must** be changed for any non-local use |
| `ALGORITHM` | `HS256` | JWT signing algorithm |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `7` | |
| `DATABASE_URL` | local Docker Postgres | |
| `INTERVIEW_MIN_QUESTIONS` | `5` | Depth/Termination Controller |
| `INTERVIEW_MAX_QUESTIONS` | `15` | |
| `ENABLE_HF_SENTIMENT` | `false` | Requires `requirements-ai.txt` |
| `HF_SENTIMENT_MODEL` | CAMeL-Lab AraBERT sentiment | |
| `SENTIMENT_EMOTION_THRESHOLD` | `0.5` | Escalation confidence threshold |
| `ENABLE_LLM` | `false` | |
| `LLM_PROVIDER` | `anthropic` | |
| `LLM_API_KEY` | _(empty)_ | |
| `LLM_MODEL` | `claude-sonnet-4-6` | |
| `FCM_SERVER_KEY` | _(empty)_ | Not yet wired up (see `mobile/README.md` Section 7) |

### Admin Dashboard (`.env`, see `admin-dashboard/.env.example`)

| Variable | Default | Notes |
|---|---|---|
| `VITE_API_BASE_URL` | `http://localhost:8000/api/v1` | Baked in at build time |

---

## 6. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `401 Unauthorized` immediately after login on mobile/admin | Clock skew between client and server | Ensure both have correct system time (JWT `exp`/`iat` are time-based) |
| Admin login rejected with "هذا الحساب لا يملك صلاحية..." | Logging in with a `patient` account | Use the seeded `admin@platform.example` account or promote a user's role directly in the database |
| `/admin/*` returns `403` for a seemingly-valid admin token | Token issued before a role change | Log out and back in to get a fresh token with the updated role claim |
| Mobile app can't reach backend on Android emulator | Using `localhost` instead of `10.0.2.2` | Update `ApiConstants.baseUrl` |
| `ENABLE_HF_SENTIMENT=true` but sentiment still looks lexicon-based | `requirements-ai.txt` not installed, or model download failed | Check backend logs; the engine silently falls back to lexicon mode on any load error |
