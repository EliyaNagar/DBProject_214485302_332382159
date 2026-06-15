# Webapp Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all emojis, collapse the webapp palette to three colors (Ink/Paper/Teal) plus a reserved red, add a live KPI dashboard, and cut DB connect latency via pool tuning + boot warmup.

**Architecture:** Next.js 15 App Router webapp (`stageE/webapp`). DB access goes through a singleton `pg.Pool` in `src/lib/db.ts`. The dashboard adds a pure-logic lib (`src/lib/dashboard.ts`, unit-tested), a `GET /api/dashboard` route, and a client page. Palette/emoji changes are CSS + markup edits. Pool warmup uses Next's stable `src/instrumentation.ts` `register()` hook.

**Tech Stack:** Next.js 15.1.6, React 19, `pg` 8, recharts 2, vitest 2, TypeScript 5.

> All commands run from `stageE/webapp`. All paths below are relative to `stageE/webapp` unless noted. The middleware matcher already protects `/api/dashboard` (it excludes only `api/login` and static assets), so no middleware change is needed. Next 15 supports `instrumentation.ts` natively — no `experimental` config flag required.

---

## File Structure

Modified:
- `src/lib/db.ts` — pool options + `warmPool()`
- `src/app/globals.css` — palette collapse + stat-card styles
- `src/components/Sidebar.tsx` — emoji removal
- `src/app/(app)/dashboard/page.tsx` — rewritten as KPI dashboard
- `src/app/(app)/data/page.tsx` — emoji removal (TopBar + 4 buttons)
- `src/app/(app)/reports/page.tsx` — emoji removal (TopBar + run button)
- `src/app/(app)/actions/page.tsx` — emoji removal + drop dead `color` field
- `src/app/login/page.tsx` — emoji removal

New:
- `src/instrumentation.ts` — boot warmup
- `src/lib/dashboard.ts` — KPI SQL + `parseKpis`
- `src/app/api/dashboard/route.ts` — dashboard API
- `tests/dashboard.test.ts` — `parseKpis` + SQL constant tests

---

### Task 1: Tune the DB pool and add `warmPool()`

**Files:**
- Modify: `src/lib/db.ts:12-30`

- [ ] **Step 1: Add pool options and a warmup export**

Replace the `getPool` function body's `new Pool({...})` call (lines 23-27) and add a `warmPool` export right after `getPool`. The final `getPool`/`warmPool` block must read exactly:

```ts
function getPool(): Pool {
  if (!pool) {
    // Strip any `sslmode` query param: recent pg versions treat sslmode=require
    // as verify-full, which overrides our `ssl` option and rejects the Supabase
    // pooler's certificate chain. We want libpq's "require" semantics — encrypt
    // without CA verification — which the explicit `ssl` object below provides
    // (parity with the Python app's sslmode=require behavior).
    const connectionString = (process.env.DATABASE_URL ?? "").replace(
      /([?&])sslmode=[^&]*(&|$)/i,
      (_m, pre: string, post: string) => (pre === "?" && post === "" ? "" : pre)
    );
    pool = new Pool({
      connectionString,
      ssl: { rejectUnauthorized: false },
      max: 5,
      keepAlive: true,            // keep TCP sockets alive — avoids handshake churn
      idleTimeoutMillis: 30_000,  // keep warm clients ~30s (pg default 10s goes cold fast)
      connectionTimeoutMillis: 8_000, // fail a stuck connect fast instead of hanging
    });
  }
  return pool;
}

/** Opens and releases one connection to pre-warm the pool (errors swallowed). */
export async function warmPool(): Promise<void> {
  try {
    const client = await getPool().connect();
    client.release();
  } catch (e) {
    console.error("DB warmup failed:", (e as Error).message);
  }
}
```

- [ ] **Step 2: Verify the file still type-checks**

Run: `npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/lib/db.ts
git commit -m "perf: tune pg pool (keepAlive, idle/connect timeouts) and add warmPool"
```

---

### Task 2: Warm the pool at server boot

**Files:**
- Create: `src/instrumentation.ts`

- [ ] **Step 1: Create the instrumentation hook**

```ts
// Next.js calls register() once when the server process boots.
// We pre-warm the DB pool so the first user request (e.g. login) is hot.
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { warmPool } = await import("@/lib/db");
    await warmPool();
  }
}
```

- [ ] **Step 2: Verify type-check**

Run: `npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Verify the hook runs on boot**

Run: `npm run dev` and watch startup logs. Expected: server starts with no "DB warmup failed" error (a successful warmup logs nothing). Stop the server after confirming.

- [ ] **Step 4: Commit**

```bash
git add src/instrumentation.ts
git commit -m "perf: warm DB pool at server boot via instrumentation hook"
```

---

### Task 3: Dashboard KPI logic (TDD)

**Files:**
- Create: `src/lib/dashboard.ts`
- Test: `tests/dashboard.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/dashboard.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { parseKpis, DASHBOARD_KPI_SQL, TREATMENTS_BY_DEPT_SQL } from "@/lib/dashboard";

describe("dashboard KPIs", () => {
  it("maps a DB row by index and computes occupancy %", () => {
    // order: patients, staff, departments, treatments_30d, total_beds, occupied_beds
    const k = parseKpis([120, 30, 5, 42, 80, 20]);
    expect(k.patients).toBe(120);
    expect(k.staff).toBe(30);
    expect(k.departments).toBe(5);
    expect(k.treatments30d).toBe(42);
    expect(k.totalBeds).toBe(80);
    expect(k.occupiedBeds).toBe(20);
    expect(k.occupancyPct).toBe(25);
  });

  it("occupancyPct is 0 when there are no beds", () => {
    expect(parseKpis([0, 0, 0, 0, 0, 0]).occupancyPct).toBe(0);
  });

  it("coerces string/null DB values to numbers", () => {
    const k = parseKpis(["120", null, "5", "0", "80", "40"]);
    expect(k.patients).toBe(120);
    expect(k.staff).toBe(0);
    expect(k.occupancyPct).toBe(50);
  });

  it("KPI SQL references the expected tables", () => {
    expect(DASHBOARD_KPI_SQL).toContain("PATIENT");
    expect(DASHBOARD_KPI_SQL).toContain("MEDICAL_STAFF");
    expect(DASHBOARD_KPI_SQL).toContain("DEPARTMENT");
    expect(DASHBOARD_KPI_SQL).toContain("TREATMENT");
  });

  it("chart SQL is a SELECT", () => {
    expect(TREATMENTS_BY_DEPT_SQL.toUpperCase()).toContain("SELECT");
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm test -- dashboard`
Expected: FAIL — cannot resolve `@/lib/dashboard`.

- [ ] **Step 3: Implement `src/lib/dashboard.ts`**

```ts
export interface DashboardKpis {
  patients: number;
  staff: number;
  departments: number;
  treatments30d: number;
  totalBeds: number;
  occupiedBeds: number;
  occupancyPct: number;
}

// All KPIs in a single round trip. Column order is consumed positionally by
// parseKpis, so do not reorder without updating parseKpis.
export const DASHBOARD_KPI_SQL = `
  SELECT
    (SELECT COUNT(*) FROM PATIENT)                                            AS patients,
    (SELECT COUNT(*) FROM MEDICAL_STAFF)                                      AS staff,
    (SELECT COUNT(*) FROM DEPARTMENT)                                         AS departments,
    (SELECT COUNT(*) FROM TREATMENT
       WHERE Treatment_Date >= NOW() - INTERVAL '30 days')                    AS treatments_30d,
    (SELECT COALESCE(SUM(NumOfBeds), 0) FROM DEPARTMENT)                      AS total_beds,
    (SELECT COUNT(DISTINCT Patient_ID) FROM TREATMENT
       WHERE Treatment_Date >= NOW() - INTERVAL '2 month')                    AS occupied_beds
`;

// Treatments per department (label + count) for the dashboard bar chart.
export const TREATMENTS_BY_DEPT_SQL = `
  SELECT
    'מחלקה ' || d.DepID            AS "מחלקה",
    COUNT(t.Treatment_Date)        AS "טיפולים"
  FROM DEPARTMENT d
  LEFT JOIN ATTENDING_DOCTOR ad ON d.DepID = ad.DepID
  LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
  GROUP BY d.DepID
  ORDER BY d.DepID
`;

/** Maps a positional KPI row (see DASHBOARD_KPI_SQL) to a typed object. */
export function parseKpis(row: unknown[]): DashboardKpis {
  const n = (v: unknown) => Number(v) || 0;
  const patients = n(row[0]);
  const staff = n(row[1]);
  const departments = n(row[2]);
  const treatments30d = n(row[3]);
  const totalBeds = n(row[4]);
  const occupiedBeds = n(row[5]);
  const occupancyPct = totalBeds > 0 ? Math.round((occupiedBeds / totalBeds) * 100) : 0;
  return { patients, staff, departments, treatments30d, totalBeds, occupiedBeds, occupancyPct };
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- dashboard`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add src/lib/dashboard.ts tests/dashboard.test.ts
git commit -m "feat: add dashboard KPI SQL and parseKpis with tests"
```

---

### Task 4: Dashboard API route

**Files:**
- Create: `src/app/api/dashboard/route.ts`

- [ ] **Step 1: Implement the route**

```ts
import { NextResponse } from "next/server";
import { runSelect } from "@/lib/db";
import { DASHBOARD_KPI_SQL, TREATMENTS_BY_DEPT_SQL, parseKpis } from "@/lib/dashboard";

export async function GET() {
  try {
    const [kpiRes, chart] = await Promise.all([
      runSelect(DASHBOARD_KPI_SQL),
      runSelect(TREATMENTS_BY_DEPT_SQL),
    ]);
    const kpis = parseKpis(kpiRes.rows[0] ?? []);
    return NextResponse.json({ kpis, chart });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 500 });
  }
}
```

- [ ] **Step 2: Verify type-check**

Run: `npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/app/api/dashboard/route.ts
git commit -m "feat: add GET /api/dashboard returning KPIs and chart data"
```

---

### Task 5: Collapse palette to three colors + add stat-card styles

**Files:**
- Modify: `src/app/globals.css` (lines 13-16, 62-64, 110, 129, 143, 207, 209, 218, 223; add stat-card block)

- [ ] **Step 1: Remove the extra color tokens**

Delete these four lines (13-16):

```css
  --accent: #c2613d;
  --accent-tint: #f1ddd2;
  --green: #2f7d5b;
  --amber: #a96a12;
```

- [ ] **Step 2: Point the color-coded buttons at teal**

Replace lines 62-64:

```css
.btn-accent { background: var(--primary); }
.btn-green { background: var(--primary); }
.btn-amber { background: var(--primary); }
```

- [ ] **Step 3: Replace remaining `var(--accent)` emphasis usages with teal**

In `.topbar-eyebrow` (line 110), `.sidebar-brand small` (line 129), and `.login-badge` (line 218): change `color: var(--accent);` to `color: var(--primary);`.
In `.nav-link.active::before` (line 143) and `.tile::before` (line 223): change `background: var(--accent);` to `background: var(--primary);`.

- [ ] **Step 4: Fix toast status colors (keep red for errors only)**

Replace lines 207 and 209:

```css
.toast.success { border-inline-start-color: var(--primary); }
```
```css
.toast.warning { border-inline-start-color: var(--ink-soft); }
```

(`.toast.error` stays `var(--red)`, `.toast.info` stays `var(--primary)`.)

- [ ] **Step 5: Add stat-card styles**

Append after the `.tile-desc` rule (after line 225):

```css
.stat-card { display: flex; flex-direction: column; gap: 6px; }
.stat-value { font-family: var(--font-display); font-size: 38px; font-weight: 700; line-height: 1; color: var(--primary); }
.stat-label { font-size: 13px; font-weight: 600; letter-spacing: .04em; color: var(--ink-soft); }
```

- [ ] **Step 6: Verify no removed tokens remain**

Run: `grep -rnE -- '--accent|--green|--amber' src/`
Expected: no output (zero matches).

- [ ] **Step 7: Commit**

```bash
git add src/app/globals.css
git commit -m "style: collapse palette to ink/paper/teal (+reserved red) and add stat cards"
```

---

### Task 6: Rebuild the dashboard page as a KPI dashboard

**Files:**
- Modify: `src/app/(app)/dashboard/page.tsx` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```tsx
"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import ReportChart from "@/components/ReportChart";
import { useToast } from "@/components/Toast";
import type { GridResult } from "@/types";
import type { DashboardKpis } from "@/lib/dashboard";

const TILES = [
  { href: "/data", title: "ניהול נתונים", desc: "הוספה, עדכון, מחיקה ושליפה מכל 14 הטבלאות." },
  { href: "/reports", title: "דוחות ושאילתות", desc: "הרצת שאילתות שלב ב' עם תרשימים." },
  { href: "/actions", title: "פעולות מתקדמות", desc: "פונקציות ופרוצדורות שלב ד'." },
];

const STATS: { key: keyof DashboardKpis; label: string; suffix?: string }[] = [
  { key: "patients", label: "מטופלים" },
  { key: "staff", label: "צוות רפואי" },
  { key: "departments", label: "מחלקות" },
  { key: "treatments30d", label: "טיפולים (30 ימים)" },
  { key: "occupancyPct", label: "תפוסת מיטות", suffix: "%" },
];

export default function DashboardPage() {
  const toast = useToast();
  const [kpis, setKpis] = useState<DashboardKpis | null>(null);
  const [chart, setChart] = useState<GridResult | null>(null);

  useEffect(() => {
    fetch("/api/dashboard")
      .then(async (r) => {
        const data = await r.json();
        if (!r.ok) throw new Error(data.message);
        setKpis(data.kpis);
        setChart(data.chart);
      })
      .catch((e) => toast.show("error", (e as Error).message));
  }, [toast]);

  return (
    <>
      <TopBar title="מערכת ניהול בית חולים — לוח בקרה" />

      <div className="dashboard-grid stagger" style={{ marginBottom: 24 }}>
        {STATS.map((s) => (
          <Card key={s.key}>
            <div className="stat-card">
              <span className="stat-value">
                {kpis ? kpis[s.key] : "—"}{kpis && s.suffix ? s.suffix : ""}
              </span>
              <span className="stat-label">{s.label}</span>
            </div>
          </Card>
        ))}
      </div>

      {chart && chart.rows.length > 0 && (
        <Card style={{ marginBottom: 24 }}>
          <h2 style={{ marginTop: 0, fontSize: 20 }}>טיפולים לפי מחלקה</h2>
          <ReportChart data={chart} labelColumn="מחלקה" valueColumn="טיפולים" />
        </Card>
      )}

      <div className="dashboard-grid stagger">
        {TILES.map((t) => (
          <Link key={t.href} href={t.href} className="tile">
            <Card interactive>
              <h2 className="tile-title">{t.title}</h2>
              <p className="tile-desc">{t.desc}</p>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}
```

- [ ] **Step 2: Verify type-check**

Run: `npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Manually verify the dashboard renders**

Run: `npm run dev`, log in, open `/dashboard`. Expected: five KPI stat cards show numbers, a teal "טיפולים לפי מחלקה" bar chart renders, and the three navigation tiles appear below. Stop the server after confirming.

- [ ] **Step 4: Commit**

```bash
git add "src/app/(app)/dashboard/page.tsx"
git commit -m "feat: rebuild dashboard as live KPI + chart landing page"
```

---

### Task 7: Remove all emojis

**Files:**
- Modify: `src/components/Sidebar.tsx` (lines 6-9, 24, 37)
- Modify: `src/app/(app)/data/page.tsx` (lines 137, 144-147)
- Modify: `src/app/(app)/reports/page.tsx` (line 40, 47)
- Modify: `src/app/(app)/actions/page.tsx` (interface line 10, data lines 14/17/23/29, TopBar line 73, log lines 58/61/67)
- Modify: `src/app/login/page.tsx` (line 38)

- [ ] **Step 1: Sidebar — strip emojis from nav, brand, logout**

Replace the `NAV` array (lines 5-10):

```tsx
const NAV = [
  { href: "/dashboard", label: "ראשי" },
  { href: "/data", label: "ניהול נתונים" },
  { href: "/reports", label: "דו\"חות" },
  { href: "/actions", label: "פעולות מתקדמות" },
];
```

Replace the brand text (line 24) `🏥 בית חולים` with `בית חולים`.
Replace the logout button text (line 37) `🚪 התנתק` with `התנתק`.

- [ ] **Step 2: Data page — TopBar + toolbar buttons**

Replace line 137 TopBar title with `title="ניהול נתונים — כל הטבלאות"`.
Replace the four toolbar buttons (lines 144-147):

```tsx
          <button className="btn btn-accent" onClick={() => loadGrid(tableKey)}>רענן</button>
          <button className="btn btn-green" onClick={startInsert}>הוסף</button>
          <button className="btn btn-amber" onClick={startUpdate}>עדכן</button>
          <button className="btn btn-red" onClick={deleteRecord}>מחק</button>
```

- [ ] **Step 3: Reports page — TopBar + run button**

Replace line 40 TopBar title with `title="דוחות מערכת — הרצת שאילתות"`.
Replace line 47 run button with:

```tsx
          <button className="btn btn-green" onClick={run}>הרץ שאילתה</button>
```

- [ ] **Step 4: Actions page — drop dead `color` field, TopBar, log strings**

Remove `color: string;` from the `ActionUi` interface (line 10) so it reads:

```tsx
interface ActionUi { name: string; title: string; signature: string; params: ActionParam[]; }
```

Remove the `color: "var(--accent)",` / `color: "var(--amber)",` fragments from all four `ACTIONS` entries (lines 14, 17, 23, 29). For example the first entry becomes:

```tsx
  { name: "calculate_patient_bill", title: "פונקציה: חישוב חשבונית מטופל",
    signature: "calculate_patient_bill(patient_id)",
    params: [{ name: "patient_id", label: "מזהה מטופל:", default: "328308725" }] },
```

Apply the same removal to the other three entries (delete only the `color: "..."` token, keep everything else on those lines).

Replace line 73 TopBar title with `title="פעולות מתקדמות — פונקציות ופרוצדורות"`.
Replace the three log `append(...)` strings (lines 58, 61, 67):

```tsx
      append(`תוצאה: ${data.scalar}`);
```
```tsx
      append(`${a.title}:`);
```
```tsx
      append(`התקבלו ${data.grid.rows.length} שורות (ראה טבלה למטה).`);
```

- [ ] **Step 5: Login page — title**

Replace line 38 with:

```tsx
        <h1 className="login-title">כניסה למערכת</h1>
```

- [ ] **Step 6: Verify zero emojis remain**

Run: `grep -rnP '[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}\x{2190}-\x{21FF}\x{2300}-\x{23FF}]' src/`
Expected: no output (zero matches).

- [ ] **Step 7: Verify type-check**

Run: `npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add src/components/Sidebar.tsx "src/app/(app)/data/page.tsx" "src/app/(app)/reports/page.tsx" "src/app/(app)/actions/page.tsx" src/app/login/page.tsx
git commit -m "style: remove all emojis from the webapp UI"
```

---

### Task 8: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `npm test`
Expected: all suites pass (existing + new `dashboard.test.ts`).

- [ ] **Step 2: Production build**

Run: `npm run build`
Expected: build completes with no type or lint errors.

- [ ] **Step 3: Confirm palette + emoji invariants**

Run: `grep -rnE -- '--accent|--green|--amber' src/` → expect no output.
Run: `grep -rnP '[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}\x{2190}-\x{21FF}\x{2300}-\x{23FF}]' src/` → expect no output.

- [ ] **Step 4: Manual smoke test**

Run: `npm run dev`. Log in (note first login should feel fast thanks to boot warmup), visit dashboard (KPIs + chart + tiles), data (CRUD buttons all teal except red delete), reports, actions. Confirm: no emojis anywhere, red appears only on delete/error toast. Stop the server.

- [ ] **Step 5: Final commit (if any uncommitted verification fixes)**

```bash
git add -A
git commit -m "chore: webapp polish verification fixes" || echo "nothing to commit"
```

---

## Self-Review Notes

- **Spec coverage:** §1 palette → Task 5; §2 emoji removal → Task 7; §3 dashboard → Tasks 3,4,6; §4 DB optimization → Tasks 1,2 (+ batched KPI query in Task 3). Middleware change from the spec was found unnecessary (matcher already covers `/api/dashboard`) and is documented in the header.
- **Type consistency:** `DashboardKpis` (Task 3) is imported and used by the page (Task 6) and parsed in the route (Task 4). `parseKpis`, `DASHBOARD_KPI_SQL`, `TREATMENTS_BY_DEPT_SQL` names are identical across tasks. Chart columns `"מחלקה"`/`"טיפולים"` match between `TREATMENTS_BY_DEPT_SQL` and the page's `ReportChart` props.
- **Button-class strategy:** kept `btn-accent`/`btn-green`/`btn-amber` class names but aliased them to teal in CSS (Task 5) — the lower-risk path flagged in the spec, avoiding edits to every button call site.
