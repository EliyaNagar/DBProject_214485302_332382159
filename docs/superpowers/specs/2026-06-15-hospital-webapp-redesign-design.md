# Hospital Management System — Web App Redesign (Next.js)

**Date:** 2026-06-15
**Status:** Approved design (pre-plan)

## 1. Summary

Rebuild the existing Python/Tkinter desktop hospital-management app (stage E) as a
professional **web application** using **Next.js (App Router) + TypeScript**, while
**reusing the existing Supabase Postgres database unchanged** (all 14 tables, stored
functions, procedures, and the salary trigger). The goal is a polished, modern,
RTL Hebrew UI with full feature parity — no new database logic.

## 2. Goals & Non-Goals

### Goals
- Full feature parity with the current desktop app (Login, CRUD, Reports, Actions).
- Professional visual design: rounded corners, refined medical blue/teal palette,
  clean Hebrew typography, modern components.
- Single-window app shell with persistent navigation (replacing the multi-popup model).
- Metadata-driven CRUD that serves all 14 tables from one generic UI (as today).
- Run locally via `npm run dev`.

### Non-Goals
- No database schema changes.
- No changes to the SQL of queries, functions, or procedures.
- No new reports, tables, or features beyond current parity (plus the agreed charts).
- No production-grade auth (keep the existing simple admin/1234 gate, web-shaped).
- No deployment/hosting setup (local run only).

## 3. Feature Parity Checklist

Mirrors the current `stageE` app:

1. **Login** — username/password (`admin` / `1234`), plus a DB-connectivity check.
   On success, set a session cookie and route to the dashboard.
2. **Dashboard** — landing screen with navigation and a welcome message.
3. **CRUD** — generic, metadata-driven UI over all 14 tables:
   - Grid view per table (uses the existing display `SELECT`s with JOINs that show
     friendly names instead of IDs).
   - Insert / Update / Delete.
   - Foreign keys rendered as dropdowns showing names (storing IDs).
   - Fixed-option selects (e.g. blood type, shift type).
   - Composite primary keys supported.
   - Update flow: enter PK → load existing row → edit (PK locked) → save.
   - Auto columns (e.g. `SALARY_AUDIT.Audit_ID`) excluded from insert forms.
4. **Reports** — the 5 stage-B queries (doctor efficiency, available beds, drug
   revenue, elderly risk, blood-type distribution), shown as tables; aggregate
   reports also get a simple chart.
5. **Actions** — the 4 stage-D subprograms:
   - `calculate_patient_bill(patient_id)` → scalar.
   - `get_department_roster_cursor(dep_id, min_salary)` → REF CURSOR → rows.
   - `apply_salary_bonus_by_performance(min_treatments, bonus_percent)` →
     procedure returning NOTICE messages.
   - `reassign_doctor_department(doc_id, new_dep_id)` → procedure returning NOTICEs.
   - Per-action parameter form + an output/log panel.

The 14 tables: PERSON, MEDICAL_STAFF, DEPARTMENT, SHIFT, LAB, PATIENT,
ATTENDING_DOCTOR, MEDICATION, TREATMENT, MEDICATIONS_GIVEN, NURSE, RESEARCHER,
ADDRESS, SALARY_AUDIT.

## 4. Architecture

### Stack
- **Next.js (App Router) + TypeScript**, full-stack.
- **Database access:** `pg` (node-postgres) connection pool, used only server-side
  in Route Handlers (`/api/...`). Connects to the existing Supabase Postgres pooler.
- **Charts:** a lightweight React charting library (e.g. Recharts) for the aggregate
  reports.
- **Hebrew web font:** Heebo or Assistant (Google Fonts), full RTL.

### Data layer (port of `DAL/database.py`)
A server-only TS module reproduces the existing DAL helpers 1:1:
- `runSelect(sql, params)` → `{ columns, rows }`
- `fetchRow(table, pkCols, pkVals)` → single row object or null
- `insertRow(table, data)`
- `updateRow(table, pkCols, pkVals, data)` → affected count
- `deleteRow(table, pkCols, pkVals)` → affected count
- `callScalarFunction(sql, params)` → single value
- `callProcedure(callSql, params)` → array of NOTICE messages
- `fetchRefcursor(funcSql, params, cursorName)` → `{ columns, rows }` (runs the
  function and `FETCH ALL` inside one transaction, matching the current logic)

REF CURSOR and NOTICE-capture behavior are fully reproducible with `pg`
(`client.query` for the cursor in a transaction; `client.on('notice', ...)` for
procedure messages).

### Metadata & query modules (ports)
- `db_metadata.py` → a TS metadata module describing each table's label, primary key,
  display `SELECT`, and editable columns (type, pk, fk query, fixed options, auto).
  This drives the single generic CRUD UI.
- `reports_logic.py` REPORTS dict → a TS module of report definitions (key, label,
  description, SQL, and chart hint where applicable).

### Configuration
- DB credentials move from hardcoded values into `.env.local`
  (`DATABASE_URL` / discrete host/port/user/password). No behavior change.

### API surface (Route Handlers)
- `POST /api/login` — verify credentials + DB connectivity; set session cookie.
- `POST /api/logout`
- `GET  /api/tables` — list of tables (key + label).
- `GET  /api/tables/[key]` — grid data (display SELECT).
- `GET  /api/tables/[key]/meta` — column metadata + FK options for forms.
- `POST /api/tables/[key]` — insert.
- `PUT  /api/tables/[key]` — update (pk + data).
- `DELETE /api/tables/[key]` — delete (pk).
- `GET  /api/tables/[key]/row` — fetch single row by PK (update flow).
- `GET  /api/reports` — report list.
- `POST /api/reports/[key]/run` — run report → columns/rows.
- `POST /api/actions/[name]` — run a specific function/procedure with params.

### Auth/session
- Simple cookie-based session set on successful login; Next.js middleware redirects
  unauthenticated users to `/login`. Mirrors today's gate; not production auth.

## 5. App Structure & Navigation

Single app shell replacing the multi-popup-window model:
- **Right-side sidebar** (RTL): Dashboard · ניהול נתונים (CRUD) · דו"חות · פעולות
  מתקדמות · התנתק.
- **Top bar:** app title + logged-in username.
- **Main content** swaps per route: `/login`, `/dashboard`, `/data`, `/reports`,
  `/actions`.

## 6. Visual Design

Driven by the frontend-design skill at implementation time; direction fixed here:
- **Rounded corners** on cards, buttons, inputs, table containers, modals.
- **Palette:** professional medical **blue/teal** primary on a soft slate background;
  white rounded cards with soft shadows; semantic action colors — green (save),
  amber (update), red (delete).
- **Typography:** clean Hebrew web font (Heebo/Assistant), full RTL layout.
- **Components:**
  - Data table: sticky header, zebra rows, rounded container (replaces Treeview).
  - Modal dialog for add/edit (replaces `FormDialog`), with FK/option selects and
    basic required-field validation.
  - Toast notifications (replace `messagebox` info/error/warning).
  - Output/log panel for Actions.
  - Simple charts for aggregate reports.

## 7. Component Boundaries

- **DAL module** — only place that talks to Postgres; pure functions, testable.
- **Metadata module** — declarative table descriptions; no DB calls.
- **Reports module** — declarative report definitions.
- **Route Handlers** — thin: parse request → call DAL → return JSON; map DB errors
  to user-facing messages.
- **UI components** — presentational, reusable (Table, Modal, Toast, Sidebar, Card,
  Form fields, Chart). Pages compose them and call the API.

## 8. Error Handling

- DAL throws on failure; Route Handlers catch and return a JSON error with a Hebrew
  message (mirroring current `messagebox.showerror` text where relevant).
- UI surfaces errors as toasts; empty result sets show an informational message
  (matching "no rows" behavior today).

## 9. Testing

- Unit-test the DAL helpers and metadata/report modules against the live DB (or a
  test schema) for the core operations and the REF CURSOR/NOTICE paths.
- Manual verification of each screen against the parity checklist.

## 10. Open Questions

None outstanding. (Stack: Next.js + TS; charts: yes for aggregate reports; delivery:
local `npm run dev` — all decided during brainstorming.)
