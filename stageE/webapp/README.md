# Hospital Management System — Web App

Next.js + TypeScript rebuild of the stage-E desktop app. Reuses the existing
Supabase Postgres database unchanged.

## Setup
1. `cd stageE/webapp && npm install`
2. Copy `.env.example` to `.env.local` and fill in `DATABASE_URL`, `APP_USERNAME`,
   `APP_PASSWORD`, `SESSION_SECRET`.
3. `npm run dev` → open http://localhost:3000
4. Log in with the credentials in `.env.local` (default `admin` / `1234`).

## Scripts
- `npm run dev` — development server
- `npm test` — unit tests (query builders, metadata, reports, session)
- `npm run build` — production build

## Structure
- `src/lib` — DAL (`db.ts`), pure query builders, metadata, reports, actions, session
- `src/app/api` — Route Handlers (login, tables CRUD, reports, actions)
- `src/app/(app)` — authed screens (dashboard, data, reports, actions)
- `src/components` — Sidebar, TopBar, DataTable, Modal, FormField, Toast, ReportChart
