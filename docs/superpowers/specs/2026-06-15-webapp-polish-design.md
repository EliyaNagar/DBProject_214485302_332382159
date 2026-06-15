# Webapp Polish: 3-Color Palette, Emoji Removal, KPI Dashboard, DB Connect Speedup

Date: 2026-06-15
Scope: `stageE/webapp` (Next.js) only. The Python tkinter app is untouched.

## Goal

Four related improvements to the hospital-management webapp:

1. Remove every emoji from the UI.
2. Collapse the palette to **three colors** (Ink, Paper, Teal) plus one **reserved
   red** used only for destructive/error states.
3. Replace the basic 3-tile launcher with a **professional KPI dashboard**
   (live stat cards + one chart, with the nav tiles kept below).
4. **Reduce DB connect latency** by tuning the pg pool and warming it at boot.

These are the design decisions confirmed during brainstorming:
- Target: webapp only.
- Palette: Ink + Paper are two of the three colors, Teal is the third; red is
  retained strictly for errors/destructive actions.
- Dashboard: live KPIs + a chart, **and** keep the existing navigation tiles.
- DB: warm the pool at server boot (one persistent idle connection is acceptable
  against the Supabase pooler on port 6543).

## Non-goals

- No changes to the Python desktop app or `stageE/DAL/database.py`.
- No new icon font/library (keeps the palette pure and the bundle minimal).
- No new reports/queries beyond the dashboard KPIs.
- No auth/session changes.

---

## 1. Three-color palette

Current `globals.css` defines 7 hues: `--primary` (teal), `--accent`
(terracotta), `--green`, `--amber`, `--red`, on warm paper/ink neutrals.

**Target palette (exactly three colors + reserved red):**

| Token        | Hex       | Role                                                      |
|--------------|-----------|-----------------------------------------------------------|
| Ink          | `#16302b` | Text, sidebar background, table headers                   |
| Paper        | `#f3efe6` | Page background, surfaces (with existing `--surface*` tints) |
| Teal (brand) | `#0f6b62` | Primary buttons, active nav, eyebrows, tile accent, chart fill |
| Red (reserved)| `#b23b2e`| **Only** destructive actions (delete) and error toasts    |

**Changes:**
- Remove `--accent`, `--accent-tint`, `--green`, `--amber` tokens.
- Everywhere `--accent` (terracotta) was used for emphasis — `.topbar-eyebrow`,
  `.sidebar-brand small`, `.nav-link.active::before`, `.tile::before`,
  `.login-badge` — switch to teal (`--primary`).
- Button variants: `.btn-accent`, `.btn-green`, `.btn-amber` collapse to the
  primary teal style. `.btn-red` stays (delete). `.btn-ghost` stays (neutral
  secondary). Keep the class names as aliases mapping to teal so call sites need
  minimal churn, OR update call sites — implementation plan will pick the lower-risk
  path (alias the classes to avoid touching every button).
- Toasts: `.toast.success` border → teal; `.toast.warning` border → ink;
  `.toast.error` keeps red; `.toast.info` keeps teal.
- Existing neutral tints (`--surface`, `--surface-2`, `--line`, `--paper-2`,
  `--ink-soft`) are shades of Ink/Paper and remain — they are not additional
  "colors."

Visual identity stays the warm "Clinical Editorial" look, just monochromatic-brand.

## 2. Emoji removal

16 emoji occurrences across: `Sidebar.tsx` (brand, 4 nav labels, logout),
`dashboard/page.tsx` (3 tiles), `data/page.tsx` (TopBar + 4 buttons),
`reports/page.tsx` (TopBar), `actions/page.tsx` (TopBar + 3 log strings),
`login/page.tsx` (title).

**Strategy:** delete the emoji glyph and any leftover leading space; keep the
existing Hebrew text labels. Nav becomes clean typographic links (consistent with
the editorial system). No icons substituted. The actions-page log strings
(`💰 תוצאה:`, `✅`, `📋`) drop the emoji and keep the text prefix.

Verification: a repo-wide emoji grep over `stageE/webapp/src` must return zero
matches after the change.

## 3. Professional KPI dashboard

Replace `dashboard/page.tsx` content with an analytics landing page:

**Layout (top → bottom):**
1. `TopBar` (no emoji).
2. **KPI stat-card row** — `dashboard-grid` of stat cards:
   - Total patients
   - Total medical staff
   - Departments
   - Treatments in the last 30 days
   - Bed occupancy % (occupied beds / total beds across departments)
3. **Chart** — "treatments per department" bar chart (teal), via existing
   `ReportChart` (`labelColumn`/`valueColumn` shape).
4. **Navigation tiles** — the existing 3 launcher tiles (data / reports / actions),
   emoji removed, kept below the analytics.

**Data flow:**
- New `src/lib/dashboard.ts` exports:
  - `DASHBOARD_KPI_SQL` — a single query returning all scalar KPIs in one row
    (using subselect aggregates / `COUNT FILTER`), so KPIs are **one round trip**.
  - `TREATMENTS_BY_DEPT_SQL` — chart query (dept label, treatment count).
  - A small `parseKpis(row)` helper mapping the row to a typed `DashboardKpis`
    object (unit-testable without a DB).
- New `src/app/api/dashboard/route.ts` — `GET`: runs the KPI query and the chart
  query, returns `{ kpis, chart: GridResult }`. Auth-gated like other app routes
  (middleware already protects `(app)` + relevant `/api`; confirm `/api/dashboard`
  is covered, extend matcher if needed).
- `dashboard/page.tsx` becomes a client component that fetches `/api/dashboard`
  on mount, shows the KPI cards + chart, with a lightweight loading state and an
  error toast on failure (red).

**New stat-card styling:** add a `.stat-card` / `.stat-value` / `.stat-label`
block to `globals.css` (Ink/Paper/Teal only). Reuse `.card` as the base.

KPI numbers are display-only; no drill-down in this iteration (YAGNI).

## 4. DB connect optimization

Current `getPool()` in `src/lib/db.ts`: `max: 5`, no keepAlive, no idle/connect
timeouts, lazily created on first request, and `login` calls `canConnect()`
(open+release) on the critical path.

**Changes to `src/lib/db.ts`:**
- Pool options add:
  - `keepAlive: true` — keep TCP sockets alive, avoiding handshake churn.
  - `idleTimeoutMillis: 30_000` — keep warm clients ~30s between requests
    (pg default is 10s, which lets the pool go cold quickly).
  - `connectionTimeoutMillis: 8_000` — fail a stuck connect fast instead of
    hanging the login spinner.
  - keep `max: 5`.
- Export a `warmPool()` that does one `connect()`/`release()` (swallowing errors)
  so the first real request is hot.

**New `src/instrumentation.ts`:**
- Next.js `register()` hook calls `warmPool()` once at server boot (Node runtime
  only — guard on `process.env.NEXT_RUNTIME === "nodejs"`).
- Ensure `instrumentationHook`/instrumentation is enabled for the Next version in
  use (App Router supports `instrumentation.ts` at `src/`); confirm during
  implementation and add the config flag only if the installed Next version needs it.

**Dashboard batching:** KPIs in one SQL round trip (see §3) instead of N queries —
the largest per-page latency win.

`canConnect()` in login stays (it's the parity check), but with a warm pool it
resolves immediately.

---

## Testing & verification

- **Unit (vitest):** new `tests/dashboard.test.ts` — `parseKpis` maps a sample row
  to the typed KPI object; KPI/chart SQL constants are non-empty and reference the
  expected tables. Existing tests must still pass.
- **Palette:** grep `globals.css` and `src/**` for removed tokens
  (`--accent`, `--green`, `--amber`) → zero references remain.
- **Emoji:** repo-wide emoji grep over `stageE/webapp/src` → zero matches.
- **Build:** `npm run build` (or `next build`) succeeds; `npm run lint` clean.
- **Manual:** login is responsive; dashboard shows KPI cards + chart; delete
  button + error toast are the only red elements; no emoji anywhere.

## Files

Modified:
- `src/app/globals.css`
- `src/components/Sidebar.tsx`
- `src/app/(app)/dashboard/page.tsx`
- `src/app/(app)/data/page.tsx`
- `src/app/(app)/reports/page.tsx`
- `src/app/(app)/actions/page.tsx`
- `src/app/login/page.tsx`
- `src/lib/db.ts`
- `src/middleware.ts` (only if `/api/dashboard` isn't already matched)

New:
- `src/instrumentation.ts`
- `src/app/api/dashboard/route.ts`
- `src/lib/dashboard.ts`
- `tests/dashboard.test.ts`
