# Hospital AI Receptionist

AI-powered hospital receptionist platform that helps patients book appointments and assists doctors with schedules, patient prep summaries, and escalation management.

## Features

- **AI Receptionist Chat** — Patients can book appointments, find doctors, get hospital info, and escalate to human staff
- **Doctor Dashboard** — Daily schedule, patient prep summaries, check-in actions, escalation inbox
- **Patient Intake** — Pre-visit forms that generate doctor prep summaries
- **Role-based Auth** — Patient, doctor, receptionist, and admin roles
- **Audit Logging** — Foundation for HIPAA-ready compliance tracking

## Tech Stack

- **Frontend:** Next.js 15, React, Tailwind CSS
- **Backend:** FastAPI, SQLAlchemy, JWT auth
- **Database:** PostgreSQL (production) / SQLite (local dev)
- **AI:** OpenAI tool-calling agent (demo mode fallback when no API key)

## Quick Start (Local)

### 1. Backend

```bash
cd /workspace
pip install -r apps/api/requirements.txt
export PYTHONPATH=/workspace
export DATABASE_URL=sqlite:///./hospital_ai.db
export DEMO_MODE=true
uvicorn apps.api.main:app --reload --port 8000
```

### 2. Frontend

```bash
cd apps/web
npm install
npm run dev
```

Open http://localhost:3000

### 3. Docker (with PostgreSQL)

```bash
docker compose up --build
```

## Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@citycare.com | admin123 |
| Doctor | dr.smith@citycare.com | doctor123 |
| Receptionist | reception@citycare.com | reception123 |
| Patient | alice@email.com | patient123 |

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/register` | Register |
| GET | `/api/doctors` | List doctors |
| GET | `/api/appointments` | List appointments |
| POST | `/api/appointments` | Create appointment |
| POST | `/api/chat` | AI receptionist chat |
| GET | `/api/doctors/{id}/schedule` | Doctor schedule |
| POST | `/api/appointments/{id}/intake` | Submit intake form |
| GET | `/api/escalations` | List escalations |
| GET | `/api/admin/audit-logs` | Audit logs (admin) |

## Environment Variables

Copy `apps/api/.env.example` to `apps/api/.env`:

```
DATABASE_URL=sqlite:///./hospital_ai.db
JWT_SECRET=change-me-in-production
OPENAI_API_KEY=          # Optional — uses demo mode if empty
DEMO_MODE=true
CORS_ORIGINS=http://localhost:3000
```

For the web app:

```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## HIPAA Hardening Path (Phase 3)

Before handling real patient data in production:

1. Execute BAAs with cloud and LLM vendors
2. Enable encryption at rest and TLS in transit
3. Add MFA and session timeouts for staff
4. Implement row-level PHI access controls
5. Store audit logs in tamper-evident storage
6. Define data retention and breach notification procedures

See `apps/api/security.py` for the full checklist and PHI audit helpers.

## Project Structure

```
├── apps/
│   ├── api/          # FastAPI backend
│   └── web/          # Next.js frontend
├── ai/
│   ├── agent.py      # AI receptionist orchestration
│   ├── prompts/      # System prompts
│   └── tools/        # Tool definitions & handlers
├── db/
│   └── seed/         # SQL seed reference
└── docker-compose.yml
```
