# Hospital Management System — Web App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the stage-E Tkinter hospital app as a professional Next.js + TypeScript web app with full feature parity, reusing the existing Supabase Postgres database unchanged.

**Architecture:** Next.js App Router with server-side Route Handlers that talk to Postgres via `pg`. A pure-function DAL (query builders + thin execution wrappers) is unit-tested with Vitest. Metadata/reports/actions are declarative TS modules ported 1:1 from the Python BL. The UI is a single RTL Hebrew app shell (sidebar + topbar) with Dashboard, CRUD, Reports, and Actions screens.

**Tech Stack:** Next.js 15 (App Router), TypeScript, `pg` (node-postgres), Vitest, Recharts, Google Font "Heebo". Run locally with `npm run dev`.

---

## File Structure

All new code lives in a new `webapp/` directory at the repo root. The existing `stageE/` Python app is left untouched.

```
webapp/
  package.json
  tsconfig.json
  next.config.mjs
  vitest.config.ts
  .gitignore
  .env.example                      # template (committed)
  .env.local                        # real credentials (gitignored)
  src/
    middleware.ts                   # auth gate
    types.ts                        # shared TS types
    lib/
      queryBuilders.ts              # PURE sql builders (unit tested)
      db.ts                         # pg pool + execution wrappers
      metadata.ts                   # port of db_metadata.py (14 tables)
      reports.ts                    # port of reports_logic.py (5 reports)
      actions.ts                    # the 4 stage-D subprograms
      session.ts                    # cookie session helpers (unit tested)
    app/
      globals.css                   # theme tokens + base styles
      layout.tsx                    # root layout: html lang=he dir=rtl, font
      login/page.tsx
      (app)/layout.tsx              # authed shell: sidebar + topbar
      (app)/dashboard/page.tsx
      (app)/data/page.tsx           # generic CRUD
      (app)/reports/page.tsx
      (app)/actions/page.tsx
      api/
        login/route.ts
        logout/route.ts
        tables/route.ts             # GET list
        tables/[key]/route.ts       # GET grid, POST insert, PUT update, DELETE
        tables/[key]/meta/route.ts  # GET column meta + fk options
        tables/[key]/row/route.ts   # GET single row by pk
        reports/route.ts            # GET report list
        reports/[key]/run/route.ts  # POST run
        actions/[name]/route.ts     # POST run a function/procedure
    components/
      Sidebar.tsx
      TopBar.tsx
      Card.tsx
      DataTable.tsx
      Modal.tsx
      FormField.tsx
      Toast.tsx                     # ToastProvider + useToast
      ReportChart.tsx
  tests/
    queryBuilders.test.ts
    metadata.test.ts
    reports.test.ts
    session.test.ts
```

---

## Task 1: Scaffold the Next.js project and tooling

**Files:**
- Create: `webapp/package.json`
- Create: `webapp/tsconfig.json`
- Create: `webapp/next.config.mjs`
- Create: `webapp/vitest.config.ts`
- Create: `webapp/.gitignore`
- Create: `webapp/.env.example`
- Create: `webapp/.env.local`
- Create: `webapp/src/app/globals.css` (placeholder, fleshed out in Task 3)
- Create: `webapp/src/app/layout.tsx` (placeholder, fleshed out in Task 3)
- Create: `webapp/src/app/page.tsx` (temporary redirect target)

- [ ] **Step 1: Create `webapp/package.json`**

```json
{
  "name": "hospital-webapp",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "next": "15.1.6",
    "pg": "^8.13.1",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "recharts": "^2.15.0"
  },
  "devDependencies": {
    "@types/node": "^22.10.0",
    "@types/pg": "^8.11.10",
    "@types/react": "19.0.0",
    "@types/react-dom": "19.0.0",
    "typescript": "^5.7.0",
    "vitest": "^2.1.8"
  }
}
```

- [ ] **Step 2: Create `webapp/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "ES2022"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 3: Create `webapp/next.config.mjs`**

```js
/** @type {import('next').NextConfig} */
const nextConfig = {};
export default nextConfig;
```

- [ ] **Step 4: Create `webapp/vitest.config.ts`**

```ts
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
```

- [ ] **Step 5: Create `webapp/.gitignore`**

```
node_modules
.next
.env.local
*.tsbuildinfo
next-env.d.ts
```

- [ ] **Step 6: Create `webapp/.env.example`**

```
# Copy to .env.local and fill in. Values below match the existing stageE app.
DATABASE_URL=postgresql://USER:PASSWORD@HOST:6543/postgres?sslmode=require
# Demo login (parity with the Tkinter app)
APP_USERNAME=admin
APP_PASSWORD=1234
# Secret used to sign the session cookie
SESSION_SECRET=change-me-to-a-long-random-string
```

- [ ] **Step 7: Create `webapp/.env.local` with the real DB values (from `stageE/DAL/database.py`)**

```
DATABASE_URL=postgresql://postgres.pslxaejgkeloehflbxit:EliyaDavid123!@aws-1-eu-central-1.pooler.supabase.com:6543/postgres?sslmode=require
APP_USERNAME=admin
APP_PASSWORD=1234
SESSION_SECRET=dev-secret-please-change-0123456789abcdef
```

- [ ] **Step 8: Create a temporary `webapp/src/app/globals.css`**

```css
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
```

- [ ] **Step 9: Create a temporary `webapp/src/app/layout.tsx`**

```tsx
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
```

- [ ] **Step 10: Create a temporary `webapp/src/app/page.tsx`**

```tsx
import { redirect } from "next/navigation";

export default function Home() {
  redirect("/dashboard");
}
```

- [ ] **Step 11: Install dependencies and verify the dev server boots**

Run: `cd webapp && npm install`
Expected: dependencies install with no errors.

Run: `cd webapp && npm run build`
Expected: `next build` completes (the home route redirects; that is fine).

- [ ] **Step 12: Commit**

```bash
git add webapp/package.json webapp/tsconfig.json webapp/next.config.mjs webapp/vitest.config.ts webapp/.gitignore webapp/.env.example webapp/src/app
git commit -m "chore: scaffold Next.js webapp"
```

(Note: `.env.local` is intentionally not committed — it is gitignored.)

---

## Task 2: Shared types and the pure query builders (TDD)

The Python DAL builds SQL strings inline. We extract that string-building into **pure functions** so it can be unit-tested without a database. Execution wrappers (Task 3) call these builders.

**Files:**
- Create: `webapp/src/types.ts`
- Create: `webapp/src/lib/queryBuilders.ts`
- Test: `webapp/tests/queryBuilders.test.ts`

- [ ] **Step 1: Create shared types `webapp/src/types.ts`**

```ts
export interface GridResult {
  columns: string[];
  rows: unknown[][];
}

export interface ColumnMeta {
  name: string;
  label: string;
  type: "text" | "int" | "decimal" | "date" | "timestamp";
  pk: boolean;
  fk: string | null;       // SQL returning (value, label) for a dropdown
  options: string[] | null; // fixed option list
  auto: boolean;            // SERIAL / auto column, excluded from insert
}

export interface TableMeta {
  key: string;
  label: string;
  pk: string[];
  select: string;
  columns: ColumnMeta[];
}

export interface ReportDef {
  key: string;
  label: string;
  desc: string;
  sql: string;
  chart?: { type: "bar"; labelColumn: string; valueColumn: string };
}

export interface BuiltQuery {
  sql: string;
  params: unknown[];
}
```

- [ ] **Step 2: Write the failing test `webapp/tests/queryBuilders.test.ts`**

```ts
import { describe, it, expect } from "vitest";
import {
  buildInsert,
  buildUpdate,
  buildDelete,
  buildFetchRow,
} from "@/lib/queryBuilders";

describe("buildInsert", () => {
  it("builds a parameterized insert", () => {
    const q = buildInsert("PERSON", { ID: 1, FirstName: "Dana" });
    expect(q.sql).toBe("INSERT INTO PERSON (ID, FirstName) VALUES ($1, $2)");
    expect(q.params).toEqual([1, "Dana"]);
  });
});

describe("buildUpdate", () => {
  it("excludes pk columns from SET and uses them in WHERE", () => {
    const q = buildUpdate(
      "MEDICAL_STAFF",
      ["id"],
      [5],
      { id: 5, Salary: 9000, Email: "a@b.c" }
    );
    expect(q.sql).toBe(
      "UPDATE MEDICAL_STAFF SET Salary = $1, Email = $2 WHERE id = $3"
    );
    expect(q.params).toEqual([9000, "a@b.c", 5]);
  });
});

describe("buildDelete", () => {
  it("builds a composite-key delete", () => {
    const q = buildDelete("ADDRESS", ["city", "street"], ["Haifa", "Herzl"]);
    expect(q.sql).toBe("DELETE FROM ADDRESS WHERE city = $1 AND street = $2");
    expect(q.params).toEqual(["Haifa", "Herzl"]);
  });
});

describe("buildFetchRow", () => {
  it("selects all columns by pk", () => {
    const q = buildFetchRow("PATIENT", ["id"], [9]);
    expect(q.sql).toBe("SELECT * FROM PATIENT WHERE id = $1");
    expect(q.params).toEqual([9]);
  });
});
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd webapp && npx vitest run tests/queryBuilders.test.ts`
Expected: FAIL — cannot resolve `@/lib/queryBuilders` / functions not defined.

- [ ] **Step 4: Implement `webapp/src/lib/queryBuilders.ts`**

```ts
import type { BuiltQuery } from "@/types";

export function buildInsert(table: string, data: Record<string, unknown>): BuiltQuery {
  const cols = Object.keys(data);
  const placeholders = cols.map((_, i) => `$${i + 1}`).join(", ");
  const sql = `INSERT INTO ${table} (${cols.join(", ")}) VALUES (${placeholders})`;
  return { sql, params: cols.map((c) => data[c]) };
}

export function buildUpdate(
  table: string,
  pkCols: string[],
  pkVals: unknown[],
  data: Record<string, unknown>
): BuiltQuery {
  const setCols = Object.keys(data).filter((c) => !pkCols.includes(c));
  const setClause = setCols.map((c, i) => `${c} = $${i + 1}`).join(", ");
  const where = pkCols
    .map((c, i) => `${c} = $${setCols.length + i + 1}`)
    .join(" AND ");
  const params = [...setCols.map((c) => data[c]), ...pkVals];
  return { sql: `UPDATE ${table} SET ${setClause} WHERE ${where}`, params };
}

export function buildDelete(
  table: string,
  pkCols: string[],
  pkVals: unknown[]
): BuiltQuery {
  const where = pkCols.map((c, i) => `${c} = $${i + 1}`).join(" AND ");
  return { sql: `DELETE FROM ${table} WHERE ${where}`, params: [...pkVals] };
}

export function buildFetchRow(
  table: string,
  pkCols: string[],
  pkVals: unknown[]
): BuiltQuery {
  const where = pkCols.map((c, i) => `${c} = $${i + 1}`).join(" AND ");
  return { sql: `SELECT * FROM ${table} WHERE ${where}`, params: [...pkVals] };
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd webapp && npx vitest run tests/queryBuilders.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add webapp/src/types.ts webapp/src/lib/queryBuilders.ts webapp/tests/queryBuilders.test.ts
git commit -m "feat: add shared types and pure SQL query builders with tests"
```

---

## Task 3: The pg execution layer (DAL)

Ports `DAL/database.py` execution behavior to `pg`, including REF CURSOR and NOTICE capture. These functions touch the live DB, so they are verified manually (Step 7), not in CI unit tests.

**Files:**
- Create: `webapp/src/lib/db.ts`

- [ ] **Step 1: Create the pool and select/select-helpers in `webapp/src/lib/db.ts`**

```ts
import { Pool, type PoolClient } from "pg";
import {
  buildInsert,
  buildUpdate,
  buildDelete,
  buildFetchRow,
} from "@/lib/queryBuilders";
import type { GridResult } from "@/types";

let pool: Pool | null = null;

function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 5,
    });
  }
  return pool;
}

/** Returns true if a connection can be opened (parity with verify_login's check). */
export async function canConnect(): Promise<boolean> {
  try {
    const client = await getPool().connect();
    client.release();
    return true;
  } catch {
    return false;
  }
}

/** Runs a SELECT and returns { columns, rows } (rows as arrays, like Tkinter grid). */
export async function runSelect(sql: string, params: unknown[] = []): Promise<GridResult> {
  const res = await getPool().query({ text: sql, values: params, rowMode: "array" });
  const columns = res.fields.map((f) => f.name);
  return { columns, rows: res.rows as unknown[][] };
}
```

- [ ] **Step 2: Add CRUD execution wrappers to `webapp/src/lib/db.ts`**

```ts
export async function fetchRow(
  table: string,
  pkCols: string[],
  pkVals: unknown[]
): Promise<Record<string, unknown> | null> {
  const q = buildFetchRow(table, pkCols, pkVals);
  const res = await getPool().query(q.sql, q.params);
  return res.rows[0] ?? null;
}

export async function insertRow(table: string, data: Record<string, unknown>): Promise<void> {
  const q = buildInsert(table, data);
  await getPool().query(q.sql, q.params);
}

export async function updateRow(
  table: string,
  pkCols: string[],
  pkVals: unknown[],
  data: Record<string, unknown>
): Promise<number> {
  const q = buildUpdate(table, pkCols, pkVals, data);
  const res = await getPool().query(q.sql, q.params);
  return res.rowCount ?? 0;
}

export async function deleteRow(
  table: string,
  pkCols: string[],
  pkVals: unknown[]
): Promise<number> {
  const q = buildDelete(table, pkCols, pkVals);
  const res = await getPool().query(q.sql, q.params);
  return res.rowCount ?? 0;
}
```

- [ ] **Step 3: Add the stored-function / procedure wrappers to `webapp/src/lib/db.ts`**

```ts
/** Calls a function returning a single scalar (e.g. calculate_patient_bill). */
export async function callScalarFunction(
  sql: string,
  params: unknown[]
): Promise<unknown> {
  const res = await getPool().query({ text: sql, values: params, rowMode: "array" });
  const first = res.rows[0] as unknown[] | undefined;
  return first ? first[0] : null;
}

/** Calls a CALL procedure and returns the NOTICE messages it emitted. */
export async function callProcedure(
  callSql: string,
  params: unknown[]
): Promise<string[]> {
  const client: PoolClient = await getPool().connect();
  const notices: string[] = [];
  const onNotice = (n: { message?: string }) => {
    if (n.message) notices.push(n.message.trim());
  };
  try {
    (client as unknown as { on: (e: string, cb: typeof onNotice) => void }).on(
      "notice",
      onNotice
    );
    await client.query(callSql, params);
    return notices;
  } finally {
    client.release();
  }
}

/**
 * Calls a function returning a REF CURSOR, opens it and FETCHes ALL rows in one
 * transaction (parity with fetch_refcursor_function).
 */
export async function fetchRefcursor(
  funcSql: string,
  params: unknown[],
  cursorName: string
): Promise<GridResult> {
  const client = await getPool().connect();
  try {
    await client.query("BEGIN");
    await client.query(funcSql, params);
    const res = await client.query({
      text: `FETCH ALL IN "${cursorName}"`,
      rowMode: "array",
    });
    await client.query("COMMIT");
    const columns = res.fields.map((f) => f.name);
    return { columns, rows: res.rows as unknown[][] };
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}
```

- [ ] **Step 4: Add a temporary smoke-test script `webapp/scripts/smoke.mjs`**

```js
import "dotenv/config";
import { canConnect, runSelect } from "../src/lib/db.ts";

const ok = await canConnect();
console.log("canConnect:", ok);
const r = await runSelect("SELECT COUNT(*) FROM PERSON");
console.log("PERSON columns:", r.columns, "rows:", r.rows);
process.exit(0);
```

(If running the `.ts` directly is awkward, instead verify connectivity through the running app in Step 7. Delete this script before committing.)

- [ ] **Step 5: Verify connectivity from inside the app (deferred to Task 8 login)**

The cleanest connectivity check happens through the login route in Task 8. If you want an earlier check, temporarily add a `console.log(await canConnect())` to a route. Expected: `true`.

- [ ] **Step 6: Type-check**

Run: `cd webapp && npx tsc --noEmit`
Expected: no type errors in `db.ts`.

- [ ] **Step 7: Commit**

```bash
git add webapp/src/lib/db.ts
git commit -m "feat: add pg execution layer (CRUD, scalar fn, procedure notices, ref cursor)"
```

(Do not commit `scripts/smoke.mjs` — remove it after use.)

---

## Task 4: Metadata module (port of `db_metadata.py`) (TDD)

Ports all 14 table definitions. The test guards integrity (count, required fields) rather than re-asserting every string.

**Files:**
- Create: `webapp/src/lib/metadata.ts`
- Test: `webapp/tests/metadata.test.ts`

- [ ] **Step 1: Write the failing test `webapp/tests/metadata.test.ts`**

```ts
import { describe, it, expect } from "vitest";
import { TABLES, getTableMeta, tableList } from "@/lib/metadata";

describe("metadata", () => {
  it("defines all 14 tables", () => {
    expect(Object.keys(TABLES)).toHaveLength(14);
  });

  it("every table has a label, non-empty pk, select, and columns", () => {
    for (const [key, t] of Object.entries(TABLES)) {
      expect(t.label, `${key} label`).toBeTruthy();
      expect(t.pk.length, `${key} pk`).toBeGreaterThan(0);
      expect(t.select, `${key} select`).toContain("SELECT");
      expect(t.columns.length, `${key} columns`).toBeGreaterThan(0);
    }
  });

  it("every pk column name exists in that table's columns (case-insensitive)", () => {
    for (const [key, t] of Object.entries(TABLES)) {
      const names = t.columns.map((c) => c.name.toLowerCase());
      for (const pk of t.pk) {
        expect(names, `${key} pk ${pk}`).toContain(pk.toLowerCase());
      }
    }
  });

  it("tableList returns key+label pairs", () => {
    const list = tableList();
    expect(list.find((x) => x.key === "PERSON")?.label).toContain("Person");
  });

  it("getTableMeta throws on unknown key", () => {
    expect(() => getTableMeta("NOPE")).toThrow();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd webapp && npx vitest run tests/metadata.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `webapp/src/lib/metadata.ts` (FK queries + helper)**

```ts
import type { ColumnMeta, TableMeta } from "@/types";

const FK_PERSON =
  "SELECT ID, FirstName || ' ' || LastName FROM PERSON ORDER BY FirstName, LastName";
const FK_STAFF =
  "SELECT ms.ID, p.FirstName || ' ' || p.LastName FROM MEDICAL_STAFF ms JOIN PERSON p ON ms.ID = p.ID ORDER BY p.FirstName";
const FK_DOCTOR =
  "SELECT ad.Doctor_ID, p.FirstName || ' ' || p.LastName FROM ATTENDING_DOCTOR ad JOIN PERSON p ON ad.Doctor_ID = p.ID ORDER BY p.FirstName";
const FK_PATIENT =
  "SELECT pa.ID, p.FirstName || ' ' || p.LastName FROM PATIENT pa JOIN PERSON p ON pa.ID = p.ID ORDER BY p.FirstName";
const FK_DEPT =
  "SELECT DepID, 'מחלקה ' || DepID || ' (' || NumOfBeds || ' מיטות)' FROM DEPARTMENT ORDER BY DepID";
const FK_LAB = "SELECT LabID, Lab_Name FROM LAB ORDER BY Lab_Name";
const FK_MED = "SELECT M_ID, M_Name FROM MEDICATION ORDER BY M_Name";

function col(
  name: string,
  label: string,
  type: ColumnMeta["type"] = "text",
  opts: Partial<Pick<ColumnMeta, "pk" | "fk" | "options" | "auto">> = {}
): ColumnMeta {
  return {
    name,
    label,
    type,
    pk: opts.pk ?? false,
    fk: opts.fk ?? null,
    options: opts.options ?? null,
    auto: opts.auto ?? false,
  };
}
```

- [ ] **Step 4: Add the 14 table definitions to `webapp/src/lib/metadata.ts`**

Port each entry verbatim from `stageE/BL/db_metadata.py`. Append:

```ts
export const TABLES: Record<string, TableMeta> = {
  PERSON: {
    key: "PERSON",
    label: "אנשים (Person)",
    pk: ["id"],
    select:
      'SELECT ID AS "מזהה", FirstName AS "שם פרטי", LastName AS "שם משפחה", PhoneNum AS "טלפון", City AS "עיר", Street AS "רחוב", HouseNumber AS "מס\' בית", ApartmentNumber AS "דירה" FROM PERSON ORDER BY ID',
    columns: [
      col("ID", 'מזהה (ת"ז)', "int", { pk: true }),
      col("FirstName", "שם פרטי"),
      col("LastName", "שם משפחה"),
      col("PhoneNum", "טלפון"),
      col("City", "עיר"),
      col("Street", "רחוב"),
      col("HouseNumber", "מספר בית", "int"),
      col("ApartmentNumber", "מספר דירה", "int"),
    ],
  },
  MEDICAL_STAFF: {
    key: "MEDICAL_STAFF",
    label: "צוות רפואי (Medical Staff)",
    pk: ["id"],
    select:
      'SELECT ms.ID AS "מזהה", p.FirstName || \' \' || p.LastName AS "שם העובד", ms.Salary AS "שכר", ms.Email AS "אימייל", ms.HireDate AS "תאריך גיוס" FROM MEDICAL_STAFF ms JOIN PERSON p ON ms.ID = p.ID ORDER BY p.FirstName',
    columns: [
      col("ID", "עובד", "int", { pk: true, fk: FK_PERSON }),
      col("Salary", "שכר", "decimal"),
      col("Email", "אימייל"),
      col("HireDate", "תאריך גיוס", "date"),
    ],
  },
  DEPARTMENT: {
    key: "DEPARTMENT",
    label: "מחלקות (Department)",
    pk: ["depid"],
    select:
      'SELECT DepID AS "מזהה מחלקה", PhoneNum AS "טלפון", NumOfBeds AS "מספר מיטות" FROM DEPARTMENT ORDER BY DepID',
    columns: [
      col("DepID", "מזהה מחלקה", "int", { pk: true }),
      col("PhoneNum", "טלפון"),
      col("NumOfBeds", "מספר מיטות", "int"),
    ],
  },
  SHIFT: {
    key: "SHIFT",
    label: "משמרות (Shift)",
    pk: ["staff_id", "shift_date", "starttime"],
    select:
      'SELECT s.Staff_ID AS "מזהה עובד", p.FirstName || \' \' || p.LastName AS "שם העובד", s.Shift_Date AS "תאריך", s.StartTime AS "התחלה", s.EndTime AS "סיום" FROM SHIFT s JOIN PERSON p ON s.Staff_ID = p.ID ORDER BY s.Shift_Date DESC',
    columns: [
      col("Staff_ID", "עובד", "int", { pk: true, fk: FK_STAFF }),
      col("Shift_Date", "תאריך משמרת", "date", { pk: true }),
      col("StartTime", "שעת התחלה", "timestamp", { pk: true }),
      col("EndTime", "שעת סיום", "timestamp"),
    ],
  },
  LAB: {
    key: "LAB",
    label: "מעבדות (Lab)",
    pk: ["labid"],
    select:
      'SELECT LabID AS "מזהה", Lab_Name AS "שם המעבדה", NumOfTechnicians AS "מספר טכנאים" FROM LAB ORDER BY Lab_Name',
    columns: [
      col("LabID", "מזהה מעבדה", "int", { pk: true }),
      col("Lab_Name", "שם המעבדה"),
      col("NumOfTechnicians", "מספר טכנאים", "int"),
    ],
  },
  PATIENT: {
    key: "PATIENT",
    label: "מטופלים (Patient)",
    pk: ["id"],
    select:
      'SELECT pa.ID AS "מזהה", p.FirstName || \' \' || p.LastName AS "שם המטופל", pa.BirthDate AS "תאריך לידה", pa.BloodType AS "סוג דם" FROM PATIENT pa JOIN PERSON p ON pa.ID = p.ID ORDER BY p.FirstName',
    columns: [
      col("ID", "אדם", "int", { pk: true, fk: FK_PERSON }),
      col("BirthDate", "תאריך לידה", "date"),
      col("BloodType", "סוג דם", "text", {
        options: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
      }),
    ],
  },
  ATTENDING_DOCTOR: {
    key: "ATTENDING_DOCTOR",
    label: "רופאים מטפלים (Attending Doctor)",
    pk: ["doctor_id"],
    select:
      'SELECT ad.Doctor_ID AS "מזהה", p.FirstName || \' \' || p.LastName AS "שם הרופא", \'מחלקה \' || ad.DepID AS "מחלקה" FROM ATTENDING_DOCTOR ad JOIN PERSON p ON ad.Doctor_ID = p.ID ORDER BY p.FirstName',
    columns: [
      col("Doctor_ID", "רופא (מתוך הצוות)", "int", { pk: true, fk: FK_STAFF }),
      col("DepID", "מחלקה", "int", { fk: FK_DEPT }),
    ],
  },
  MEDICATION: {
    key: "MEDICATION",
    label: "תרופות (Medication)",
    pk: ["m_id"],
    select:
      'SELECT M_ID AS "מזהה", M_Name AS "שם התרופה", Price AS "מחיר" FROM MEDICATION ORDER BY M_Name',
    columns: [
      col("M_ID", "מזהה תרופה", "int", { pk: true }),
      col("M_Name", "שם התרופה"),
      col("Price", "מחיר", "decimal"),
    ],
  },
  TREATMENT: {
    key: "TREATMENT",
    label: "טיפולים (Treatment)",
    pk: ["patient_id", "doctor_id", "treatment_date"],
    select:
      'SELECT pp.FirstName || \' \' || pp.LastName AS "מטופל", dp.FirstName || \' \' || dp.LastName AS "רופא", t.Treatment_Date AS "תאריך הטיפול" FROM TREATMENT t JOIN PERSON pp ON t.Patient_ID = pp.ID JOIN PERSON dp ON t.Doctor_ID = dp.ID ORDER BY t.Treatment_Date DESC',
    columns: [
      col("Patient_ID", "מטופל", "int", { pk: true, fk: FK_PATIENT }),
      col("Doctor_ID", "רופא", "int", { pk: true, fk: FK_DOCTOR }),
      col("Treatment_Date", "תאריך הטיפול", "timestamp", { pk: true }),
    ],
  },
  MEDICATIONS_GIVEN: {
    key: "MEDICATIONS_GIVEN",
    label: "תרופות שניתנו (Medications Given)",
    pk: ["m_id", "patient_id", "doctor_id", "treatment_date"],
    select:
      'SELECT m.M_Name AS "תרופה", pp.FirstName || \' \' || pp.LastName AS "מטופל", dp.FirstName || \' \' || dp.LastName AS "רופא", mg.Treatment_Date AS "תאריך" FROM MEDICATIONS_GIVEN mg JOIN MEDICATION m ON mg.M_ID = m.M_ID JOIN PERSON pp ON mg.Patient_ID = pp.ID JOIN PERSON dp ON mg.Doctor_ID = dp.ID ORDER BY mg.Treatment_Date DESC',
    columns: [
      col("M_ID", "תרופה", "int", { pk: true, fk: FK_MED }),
      col("Patient_ID", "מטופל", "int", { pk: true, fk: FK_PATIENT }),
      col("Doctor_ID", "רופא", "int", { pk: true, fk: FK_DOCTOR }),
      col("Treatment_Date", "תאריך הטיפול", "timestamp", { pk: true }),
    ],
  },
  NURSE: {
    key: "NURSE",
    label: "אחיות (Nurse)",
    pk: ["nurse_id"],
    select:
      'SELECT n.Nurse_ID AS "מזהה", p.FirstName || \' \' || p.LastName AS "שם האח/ות", n.ShiftType AS "סוג משמרת", n.Specialization AS "התמחות", \'מחלקה \' || n.DepID AS "מחלקה" FROM NURSE n JOIN PERSON p ON n.Nurse_ID = p.ID ORDER BY p.FirstName',
    columns: [
      col("Nurse_ID", "אח/ות (מתוך הצוות)", "int", { pk: true, fk: FK_STAFF }),
      col("ShiftType", "סוג משמרת", "text", {
        options: ["Morning", "Afternoon", "Night"],
      }),
      col("Specialization", "התמחות"),
      col("DepID", "מחלקה", "int", { fk: FK_DEPT }),
    ],
  },
  RESEARCHER: {
    key: "RESEARCHER",
    label: "חוקרים (Researcher)",
    pk: ["researcher_id"],
    select:
      'SELECT r.Researcher_ID AS "מזהה", p.FirstName || \' \' || p.LastName AS "שם החוקר", r.Research_Field AS "תחום מחקר", r.StartDate AS "תאריך תחילה", l.Lab_Name AS "מעבדה" FROM RESEARCHER r JOIN PERSON p ON r.Researcher_ID = p.ID JOIN LAB l ON r.LabID = l.LabID ORDER BY p.FirstName',
    columns: [
      col("Researcher_ID", "חוקר (מתוך הצוות)", "int", { pk: true, fk: FK_STAFF }),
      col("Research_Field", "תחום מחקר"),
      col("StartDate", "תאריך תחילה", "date"),
      col("LabID", "מעבדה", "int", { fk: FK_LAB }),
    ],
  },
  ADDRESS: {
    key: "ADDRESS",
    label: "כתובות (Address)",
    pk: ["city", "street", "housenumber", "apartmentnumber"],
    select:
      'SELECT City AS "עיר", Street AS "רחוב", HouseNumber AS "מס\' בית", ApartmentNumber AS "דירה" FROM ADDRESS ORDER BY City, Street',
    columns: [
      col("City", "עיר", "text", { pk: true }),
      col("Street", "רחוב", "text", { pk: true }),
      col("HouseNumber", "מספר בית", "int", { pk: true }),
      col("ApartmentNumber", "מספר דירה", "int", { pk: true }),
    ],
  },
  SALARY_AUDIT: {
    key: "SALARY_AUDIT",
    label: 'ביקורת שכר (Salary Audit) - מתעדכן ע"י טריגר',
    pk: ["audit_id"],
    select:
      'SELECT sa.Audit_ID AS "מזהה", p.FirstName || \' \' || p.LastName AS "עובד", sa.Old_Salary AS "שכר ישן", sa.New_Salary AS "שכר חדש", sa.Change_Date AS "מועד השינוי" FROM SALARY_AUDIT sa JOIN PERSON p ON sa.Staff_ID = p.ID ORDER BY sa.Change_Date DESC',
    columns: [
      col("Audit_ID", "מזהה", "int", { pk: true, auto: true }),
      col("Staff_ID", "עובד", "int", { fk: FK_STAFF }),
      col("Old_Salary", "שכר ישן", "decimal"),
      col("New_Salary", "שכר חדש", "decimal"),
      col("Change_Date", "מועד השינוי", "timestamp"),
    ],
  },
};

export function getTableMeta(key: string): TableMeta {
  const t = TABLES[key];
  if (!t) throw new Error(`Unknown table: ${key}`);
  return t;
}

export function tableList(): { key: string; label: string }[] {
  return Object.values(TABLES).map((t) => ({ key: t.key, label: t.label }));
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd webapp && npx vitest run tests/metadata.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add webapp/src/lib/metadata.ts webapp/tests/metadata.test.ts
git commit -m "feat: port table metadata for all 14 tables with integrity tests"
```

---

## Task 5: Reports module (port of `reports_logic.py`) (TDD)

**Files:**
- Create: `webapp/src/lib/reports.ts`
- Test: `webapp/tests/reports.test.ts`

- [ ] **Step 1: Write the failing test `webapp/tests/reports.test.ts`**

```ts
import { describe, it, expect } from "vitest";
import { REPORTS, getReport, reportList } from "@/lib/reports";

describe("reports", () => {
  it("defines the 5 stage-B reports", () => {
    expect(Object.keys(REPORTS)).toHaveLength(5);
  });

  it("each report has a label, desc and SELECT sql", () => {
    for (const [key, r] of Object.entries(REPORTS)) {
      expect(r.label, `${key} label`).toBeTruthy();
      expect(r.desc, `${key} desc`).toBeTruthy();
      expect(r.sql.toUpperCase(), `${key} sql`).toContain("SELECT");
    }
  });

  it("blood_type report has a bar chart hint", () => {
    expect(REPORTS.blood_type.chart?.type).toBe("bar");
  });

  it("getReport throws on unknown key", () => {
    expect(() => getReport("nope")).toThrow();
  });

  it("reportList returns key/label/desc", () => {
    expect(reportList().find((r) => r.key === "available_beds")).toBeTruthy();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd webapp && npx vitest run tests/reports.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `webapp/src/lib/reports.ts`**

Port the 5 SQL strings verbatim from `stageE/BL/reports_logic.py`. Add chart hints for the two aggregate reports (`blood_type`, `drug_revenue`).

```ts
import type { ReportDef } from "@/types";

export const REPORTS: Record<string, ReportDef> = {
  doctor_efficiency: {
    key: "doctor_efficiency",
    label: "דירוג כלכליות רופאים (שאילתה 1)",
    desc: "כמות טיפולים מול שכר - מי הרופא היעיל ביותר.",
    sql: `
      SELECT
        p.FirstName || ' ' || p.LastName AS "שם הרופא",
        COUNT(t.Treatment_Date) AS "סך טיפולים",
        ms.Salary AS "שכר",
        (NULLIF(ms.Salary, 0) / NULLIF(COUNT(t.Treatment_Date),0)) AS "מדד רווחיות"
      FROM PERSON p
      JOIN MEDICAL_STAFF ms ON p.ID = ms.ID
      JOIN ATTENDING_DOCTOR ad ON ms.ID = ad.Doctor_ID
      LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
      GROUP BY p.ID, p.FirstName, p.LastName, ms.Salary
      ORDER BY "מדד רווחיות" DESC
      LIMIT 50;`,
  },
  available_beds: {
    key: "available_beds",
    label: "מיטות פנויות במחלקות (שאילתה 3)",
    desc: "תפוסת מחלקות - כמה מיטות תפוסות וכמה פנויות.",
    sql: `
      SELECT
        d.DepID AS "מחלקה",
        d.NumOfBeds AS "סך מיטות",
        COUNT(DISTINCT t.Patient_ID) AS "מיטות תפוסות",
        (d.NumOfBeds - COUNT(DISTINCT t.Patient_ID)) AS "מיטות פנויות"
      FROM DEPARTMENT d
      LEFT JOIN ATTENDING_DOCTOR ad ON d.DepID = ad.DepID
      LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
        AND t.Treatment_Date >= NOW() - INTERVAL '2 month'
      GROUP BY d.DepID, d.NumOfBeds
      ORDER BY "מיטות פנויות" DESC;`,
  },
  drug_revenue: {
    key: "drug_revenue",
    label: "הכנסות מתרופות בחצי שנה (שאילתה 5)",
    desc: "סך ההכנסות וכמות המכירות לכל תרופה בששת החודשים האחרונים.",
    sql: `
      SELECT
        m.M_Name AS "שם התרופה",
        COUNT(mg.M_ID) AS "כמות מתן",
        SUM(m.Price) AS "סך הכנסות"
      FROM MEDICATION m
      JOIN MEDICATIONS_GIVEN mg ON m.M_ID = mg.M_ID
      WHERE mg.Treatment_Date >= NOW() - INTERVAL '6 months'
      GROUP BY m.M_ID, m.M_Name
      ORDER BY "סך הכנסות" DESC;`,
    chart: { type: "bar", labelColumn: "שם התרופה", valueColumn: "סך הכנסות" },
  },
  elderly_risk: {
    key: "elderly_risk",
    label: "חולים מבוגרים בסיכון (שאילתה 8)",
    desc: "מטופלים מעל גיל 55 עם 2 טיפולים או יותר בחודשיים האחרונים.",
    sql: `
      SELECT
        p.FirstName AS "שם פרטי",
        p.LastName AS "שם משפחה",
        EXTRACT(YEAR FROM age(CURRENT_DATE, pat.BirthDate)) AS "גיל",
        COUNT(t.Treatment_Date) AS "טיפולים"
      FROM PERSON p
      JOIN PATIENT pat ON p.ID = pat.ID
      JOIN TREATMENT t ON pat.ID = t.Patient_ID
      WHERE pat.BirthDate <= CURRENT_DATE - INTERVAL '55 years'
        AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '2 month'
      GROUP BY p.ID, p.FirstName, p.LastName, pat.BirthDate
      HAVING COUNT(t.Treatment_Date) >= 2;`,
  },
  blood_type: {
    key: "blood_type",
    label: "התפלגות סוגי דם (שאילתה 7)",
    desc: "כמות המטופלים מכל סוג דם - לניהול מלאי מנות דם.",
    sql: `
      SELECT
        BloodType AS "סוג דם",
        COUNT(*) AS "מספר מטופלים"
      FROM PATIENT
      WHERE BloodType IS NOT NULL
      GROUP BY BloodType
      ORDER BY "מספר מטופלים" DESC;`,
    chart: { type: "bar", labelColumn: "סוג דם", valueColumn: "מספר מטופלים" },
  },
};

export function getReport(key: string): ReportDef {
  const r = REPORTS[key];
  if (!r) throw new Error(`Unknown report: ${key}`);
  return r;
}

export function reportList(): { key: string; label: string; desc: string }[] {
  return Object.values(REPORTS).map((r) => ({
    key: r.key,
    label: r.label,
    desc: r.desc,
  }));
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd webapp && npx vitest run tests/reports.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add webapp/src/lib/reports.ts webapp/tests/reports.test.ts
git commit -m "feat: port stage-B reports with chart hints and tests"
```

---

## Task 6: Actions module (the 4 stage-D subprograms)

A declarative description of each function/procedure plus an executor. No DB-independent logic to unit test beyond the registry; verified end-to-end in Task 14.

**Files:**
- Create: `webapp/src/lib/actions.ts`

- [ ] **Step 1: Implement `webapp/src/lib/actions.ts`**

```ts
import {
  callScalarFunction,
  callProcedure,
  fetchRefcursor,
} from "@/lib/db";
import type { GridResult } from "@/types";

export interface ActionParam {
  name: string;
  label: string;
  default?: string;
}

export type ActionKind = "scalar" | "cursor" | "procedure";

export interface ActionDef {
  name: string;
  title: string;
  signature: string;
  kind: ActionKind;
  color: "accent" | "warning";
  params: ActionParam[];
}

export const ACTIONS: Record<string, ActionDef> = {
  calculate_patient_bill: {
    name: "calculate_patient_bill",
    title: "פונקציה: חישוב חשבונית מטופל",
    signature: "calculate_patient_bill(patient_id)",
    kind: "scalar",
    color: "accent",
    params: [{ name: "patient_id", label: "מזהה מטופל:", default: "328308725" }],
  },
  get_department_roster_cursor: {
    name: "get_department_roster_cursor",
    title: "פונקציה (REF CURSOR): צוות מחלקה לפי שכר",
    signature: "get_department_roster_cursor(dep_id, min_salary)",
    kind: "cursor",
    color: "accent",
    params: [
      { name: "dep_id", label: "מחלקה:", default: "2" },
      { name: "min_salary", label: "שכר מינ':", default: "0" },
    ],
  },
  apply_salary_bonus_by_performance: {
    name: "apply_salary_bonus_by_performance",
    title: "פרוצדורה: בונוס שכר לרופאים מצטיינים",
    signature: "apply_salary_bonus_by_performance(min_treatments, bonus_percent)",
    kind: "procedure",
    color: "warning",
    params: [
      { name: "min_treatments", label: "מינ' טיפולים:", default: "2" },
      { name: "bonus_percent", label: "אחוז בונוס:", default: "10" },
    ],
  },
  reassign_doctor_department: {
    name: "reassign_doctor_department",
    title: "פרוצדורה: העברת רופא למחלקה אחרת",
    signature: "reassign_doctor_department(doc_id, new_dep_id)",
    kind: "procedure",
    color: "warning",
    params: [
      { name: "doc_id", label: "מזהה רופא:", default: "" },
      { name: "new_dep_id", label: "מחלקה חדשה:", default: "" },
    ],
  },
};

export interface ActionResult {
  scalar?: unknown;
  grid?: GridResult;
  notices?: string[];
}

export async function runAction(
  name: string,
  params: Record<string, string>
): Promise<ActionResult> {
  switch (name) {
    case "calculate_patient_bill":
      return {
        scalar: await callScalarFunction("SELECT calculate_patient_bill($1)", [
          parseInt(params.patient_id, 10),
        ]),
      };
    case "get_department_roster_cursor":
      return {
        grid: await fetchRefcursor(
          "SELECT get_department_roster_cursor($1, $2)",
          [parseInt(params.dep_id, 10), parseFloat(params.min_salary)],
          "dept_staff_result_cursor"
        ),
      };
    case "apply_salary_bonus_by_performance":
      return {
        notices: await callProcedure(
          "CALL apply_salary_bonus_by_performance($1, $2)",
          [parseInt(params.min_treatments, 10), parseFloat(params.bonus_percent)]
        ),
      };
    case "reassign_doctor_department":
      return {
        notices: await callProcedure("CALL reassign_doctor_department($1, $2)", [
          parseInt(params.doc_id, 10),
          parseInt(params.new_dep_id, 10),
        ]),
      };
    default:
      throw new Error(`Unknown action: ${name}`);
  }
}
```

- [ ] **Step 2: Type-check**

Run: `cd webapp && npx tsc --noEmit`
Expected: no type errors.

- [ ] **Step 3: Commit**

```bash
git add webapp/src/lib/actions.ts
git commit -m "feat: add stage-D actions registry and executor"
```

---

## Task 7: Session helpers (TDD) and auth middleware

A minimal signed cookie. We sign `username` with HMAC-SHA256 using `SESSION_SECRET` so the cookie cannot be forged. Pure sign/verify functions are unit-tested.

**Files:**
- Create: `webapp/src/lib/session.ts`
- Create: `webapp/src/middleware.ts`
- Test: `webapp/tests/session.test.ts`

- [ ] **Step 1: Write the failing test `webapp/tests/session.test.ts`**

```ts
import { describe, it, expect } from "vitest";
import { signSession, verifySession } from "@/lib/session";

const SECRET = "test-secret";

describe("session", () => {
  it("verifies a token it just signed", () => {
    const token = signSession("admin", SECRET);
    expect(verifySession(token, SECRET)).toBe("admin");
  });

  it("rejects a tampered token", () => {
    const token = signSession("admin", SECRET);
    const tampered = token.replace(/^[^.]+/, "hacker");
    expect(verifySession(tampered, SECRET)).toBeNull();
  });

  it("rejects a token signed with another secret", () => {
    const token = signSession("admin", SECRET);
    expect(verifySession(token, "other-secret")).toBeNull();
  });

  it("returns null for malformed input", () => {
    expect(verifySession("garbage", SECRET)).toBeNull();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd webapp && npx vitest run tests/session.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `webapp/src/lib/session.ts`**

```ts
import crypto from "crypto";

export const SESSION_COOKIE = "hms_session";

/** Returns "<base64url(username)>.<hmac>". */
export function signSession(username: string, secret: string): string {
  const payload = Buffer.from(username, "utf8").toString("base64url");
  const sig = crypto.createHmac("sha256", secret).update(payload).digest("base64url");
  return `${payload}.${sig}`;
}

/** Returns the username if the token is valid, else null. */
export function verifySession(token: string, secret: string): string | null {
  const parts = token.split(".");
  if (parts.length !== 2) return null;
  const [payload, sig] = parts;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("base64url");
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  try {
    return Buffer.from(payload, "base64url").toString("utf8");
  } catch {
    return null;
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd webapp && npx vitest run tests/session.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Implement `webapp/src/middleware.ts`**

```ts
import { NextResponse, type NextRequest } from "next/server";
import { SESSION_COOKIE, verifySession } from "@/lib/session";

const PUBLIC_PATHS = ["/login"];

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  if (PUBLIC_PATHS.includes(pathname)) return NextResponse.next();

  const token = req.cookies.get(SESSION_COOKIE)?.value ?? "";
  const user = verifySession(token, process.env.SESSION_SECRET ?? "");
  if (!user) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

export const config = {
  // Protect everything except Next internals, the login API, and static assets.
  matcher: ["/((?!api/login|_next/static|_next/image|favicon.ico).*)"],
};
```

- [ ] **Step 6: Commit**

```bash
git add webapp/src/lib/session.ts webapp/src/middleware.ts webapp/tests/session.test.ts
git commit -m "feat: add signed session helpers and auth middleware"
```

---

## Task 8: Theme, root layout, and the Toast system

Sets the professional look: palette tokens, rounded radii, Heebo font, RTL. Adds the toast provider used app-wide (replaces Tkinter messagebox).

**Files:**
- Modify: `webapp/src/app/globals.css` (replace placeholder)
- Modify: `webapp/src/app/layout.tsx` (replace placeholder)
- Create: `webapp/src/components/Toast.tsx`

- [ ] **Step 1: Replace `webapp/src/app/globals.css` with the theme**

```css
:root {
  --bg: #f1f5f9;
  --surface: #ffffff;
  --primary: #0e7490;      /* medical teal/blue */
  --primary-dark: #0c5e74;
  --accent: #2563eb;
  --green: #16a34a;
  --amber: #d97706;
  --red: #dc2626;
  --text: #0f172a;
  --muted: #64748b;
  --border: #e2e8f0;
  --radius: 16px;
  --radius-sm: 10px;
  --shadow: 0 4px 20px rgba(15, 23, 42, 0.08);
}

* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body {
  font-family: "Heebo", system-ui, Arial, sans-serif;
  background: var(--bg);
  color: var(--text);
}

button { font-family: inherit; cursor: pointer; border: none; }

.btn {
  border-radius: var(--radius-sm);
  padding: 10px 18px;
  font-weight: 600;
  color: #fff;
  background: var(--primary);
  transition: filter 0.15s ease;
}
.btn:hover { filter: brightness(1.07); }
.btn-green { background: var(--green); }
.btn-amber { background: var(--amber); }
.btn-red { background: var(--red); }
.btn-accent { background: var(--accent); }
.btn-ghost { background: transparent; color: var(--text); border: 1px solid var(--border); }

.input, .select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-family: inherit;
  font-size: 14px;
  background: #fff;
  text-align: right;
}
.input:focus, .select:focus { outline: 2px solid var(--primary); border-color: var(--primary); }
.input:read-only { background: #f1f5f9; color: var(--muted); }
```

- [ ] **Step 2: Replace `webapp/src/app/layout.tsx` (load Heebo, mount ToastProvider)**

```tsx
import "./globals.css";
import { Heebo } from "next/font/google";
import { ToastProvider } from "@/components/Toast";

const heebo = Heebo({ subsets: ["hebrew", "latin"], display: "swap" });

export const metadata = { title: "מערכת ניהול בית חולים" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl" className={heebo.className}>
      <body>
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
```

- [ ] **Step 3: Implement `webapp/src/components/Toast.tsx`**

```tsx
"use client";
import { createContext, useCallback, useContext, useState } from "react";

type ToastKind = "info" | "success" | "error" | "warning";
interface ToastItem { id: number; kind: ToastKind; text: string; }
interface ToastApi { show: (kind: ToastKind, text: string) => void; }

const ToastCtx = createContext<ToastApi | null>(null);
const COLORS: Record<ToastKind, string> = {
  info: "#2563eb",
  success: "#16a34a",
  error: "#dc2626",
  warning: "#d97706",
};

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const show = useCallback((kind: ToastKind, text: string) => {
    const id = Date.now() + Math.random();
    setItems((p) => [...p, { id, kind, text }]);
    setTimeout(() => setItems((p) => p.filter((t) => t.id !== id)), 4000);
  }, []);
  return (
    <ToastCtx.Provider value={{ show }}>
      {children}
      <div style={{ position: "fixed", top: 16, left: 16, display: "flex", flexDirection: "column", gap: 8, zIndex: 1000 }}>
        {items.map((t) => (
          <div key={t.id} style={{
            background: "#fff", borderInlineStart: `5px solid ${COLORS[t.kind]}`,
            borderRadius: 10, padding: "12px 16px", boxShadow: "0 4px 20px rgba(15,23,42,.12)",
            minWidth: 240, maxWidth: 360, fontWeight: 500,
          }}>{t.text}</div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export function useToast(): ToastApi {
  const ctx = useContext(ToastCtx);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
}
```

- [ ] **Step 4: Verify the build compiles**

Run: `cd webapp && npm run build`
Expected: build succeeds (Heebo font downloads at build time; requires internet).

- [ ] **Step 5: Commit**

```bash
git add webapp/src/app/globals.css webapp/src/app/layout.tsx webapp/src/components/Toast.tsx
git commit -m "feat: add theme, RTL root layout with Heebo, and toast system"
```

---

## Task 9: Login API + login page

**Files:**
- Create: `webapp/src/app/api/login/route.ts`
- Create: `webapp/src/app/api/logout/route.ts`
- Create: `webapp/src/app/login/page.tsx`

- [ ] **Step 1: Implement `webapp/src/app/api/login/route.ts`**

Mirrors `verify_login`: validates non-empty, checks `admin`/`1234`, then confirms DB connectivity, then sets the session cookie.

```ts
import { NextResponse } from "next/server";
import { canConnect } from "@/lib/db";
import { SESSION_COOKIE, signSession } from "@/lib/session";

export async function POST(req: Request) {
  const { username, password } = await req.json();

  if (!username || !password) {
    return NextResponse.json({ ok: false, message: "אנא הזן שם משתמש וסיסמה." }, { status: 400 });
  }
  if (username !== process.env.APP_USERNAME || password !== process.env.APP_PASSWORD) {
    return NextResponse.json({ ok: false, message: "שם משתמש או סיסמה שגויים. נסה שוב." }, { status: 401 });
  }
  if (!(await canConnect())) {
    return NextResponse.json({ ok: false, message: "שגיאת רשת: לא ניתן להתחבר למסד הנתונים." }, { status: 503 });
  }

  const token = signSession(username, process.env.SESSION_SECRET ?? "");
  const res = NextResponse.json({ ok: true, message: `ברוך הבא למערכת, ${username}!` });
  res.cookies.set(SESSION_COOKIE, token, { httpOnly: true, sameSite: "lax", path: "/" });
  return res;
}
```

- [ ] **Step 2: Implement `webapp/src/app/api/logout/route.ts`**

```ts
import { NextResponse } from "next/server";
import { SESSION_COOKIE } from "@/lib/session";

export async function POST() {
  const res = NextResponse.json({ ok: true });
  res.cookies.delete(SESSION_COOKIE);
  return res;
}
```

- [ ] **Step 3: Implement `webapp/src/app/login/page.tsx`**

```tsx
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useToast } from "@/components/Toast";

export default function LoginPage() {
  const router = useRouter();
  const toast = useToast();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      const data = await res.json();
      if (data.ok) {
        toast.show("success", data.message);
        router.push("/dashboard");
      } else {
        toast.show("error", data.message);
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ minHeight: "100vh", display: "grid", placeItems: "center" }}>
      <form onSubmit={submit} style={{
        background: "var(--surface)", borderRadius: "var(--radius)", boxShadow: "var(--shadow)",
        padding: 36, width: 360, display: "flex", flexDirection: "column", gap: 16,
      }}>
        <h1 style={{ textAlign: "center", color: "var(--primary)", margin: 0 }}>
          🏥 כניסה למערכת
        </h1>
        <label>
          שם משתמש
          <input className="input" value={username} onChange={(e) => setUsername(e.target.value)} autoFocus />
        </label>
        <label>
          סיסמה
          <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        </label>
        <button className="btn" disabled={busy} type="submit">
          {busy ? "מתחבר..." : "התחבר"}
        </button>
      </form>
    </div>
  );
}
```

- [ ] **Step 4: Manual verification**

Run: `cd webapp && npm run dev`
- Visit `http://localhost:3000/dashboard` → should redirect to `/login` (middleware).
- Enter wrong credentials → red toast "שם משתמש או סיסמה שגויים".
- Enter `admin` / `1234` → success toast, redirect to `/dashboard` (dashboard built next; a 404/empty page here is acceptable until Task 10).

- [ ] **Step 5: Commit**

```bash
git add webapp/src/app/api/login webapp/src/app/api/logout webapp/src/app/login
git commit -m "feat: add login/logout API and login page"
```

---

## Task 10: App shell (sidebar + topbar) and dashboard

**Files:**
- Create: `webapp/src/components/Sidebar.tsx`
- Create: `webapp/src/components/TopBar.tsx`
- Create: `webapp/src/components/Card.tsx`
- Create: `webapp/src/app/(app)/layout.tsx`
- Create: `webapp/src/app/(app)/dashboard/page.tsx`

- [ ] **Step 1: Implement `webapp/src/components/Card.tsx`**

```tsx
export default function Card({ children, style }: { children: React.ReactNode; style?: React.CSSProperties }) {
  return (
    <div style={{
      background: "var(--surface)", borderRadius: "var(--radius)",
      boxShadow: "var(--shadow)", padding: 20, ...style,
    }}>
      {children}
    </div>
  );
}
```

- [ ] **Step 2: Implement `webapp/src/components/Sidebar.tsx`**

```tsx
"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const NAV = [
  { href: "/dashboard", label: "🏠 ראשי" },
  { href: "/data", label: "🗄️ ניהול נתונים" },
  { href: "/reports", label: "📊 דו\"חות" },
  { href: "/actions", label: "⚙️ פעולות מתקדמות" },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  async function logout() {
    await fetch("/api/logout", { method: "POST" });
    router.push("/login");
  }

  return (
    <aside style={{
      width: 240, background: "var(--primary)", color: "#fff", display: "flex",
      flexDirection: "column", padding: 18, gap: 6, minHeight: "100vh",
    }}>
      <div style={{ fontSize: 18, fontWeight: 700, padding: "8px 10px 18px" }}>
        🏥 בית חולים
      </div>
      {NAV.map((n) => {
        const active = pathname === n.href;
        return (
          <Link key={n.href} href={n.href} style={{
            color: "#fff", textDecoration: "none", padding: "10px 12px",
            borderRadius: 10, fontWeight: 600,
            background: active ? "rgba(255,255,255,.18)" : "transparent",
          }}>
            {n.label}
          </Link>
        );
      })}
      <button className="btn btn-red" onClick={logout} style={{ marginTop: "auto" }}>
        🚪 התנתק
      </button>
    </aside>
  );
}
```

- [ ] **Step 3: Implement `webapp/src/components/TopBar.tsx`**

```tsx
export default function TopBar({ title }: { title: string }) {
  return (
    <header style={{
      background: "var(--surface)", borderRadius: "var(--radius)", boxShadow: "var(--shadow)",
      padding: "16px 24px", marginBottom: 20, fontSize: 20, fontWeight: 700, color: "var(--primary)",
    }}>
      {title}
    </header>
  );
}
```

- [ ] **Step 4: Implement `webapp/src/app/(app)/layout.tsx`**

```tsx
import Sidebar from "@/components/Sidebar";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, padding: 24, overflow: "auto" }}>{children}</main>
    </div>
  );
}
```

- [ ] **Step 5: Implement `webapp/src/app/(app)/dashboard/page.tsx`**

```tsx
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import Link from "next/link";

const TILES = [
  { href: "/data", title: "🗄️ ניהול נתונים", desc: "הוספה, עדכון, מחיקה ושליפה מכל 14 הטבלאות.", color: "var(--accent)" },
  { href: "/reports", title: "📊 דו\"חות ושאילתות", desc: "הרצת שאילתות שלב ב' עם תרשימים.", color: "var(--green)" },
  { href: "/actions", title: "⚙️ פעולות מתקדמות", desc: "פונקציות ופרוצדורות שלב ד'.", color: "var(--amber)" },
];

export default function DashboardPage() {
  return (
    <>
      <TopBar title="מערכת ניהול בית חולים — תפריט ראשי" />
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", gap: 20 }}>
        {TILES.map((t) => (
          <Link key={t.href} href={t.href} style={{ textDecoration: "none", color: "inherit" }}>
            <Card style={{ borderTop: `5px solid ${t.color}` }}>
              <h2 style={{ marginTop: 0 }}>{t.title}</h2>
              <p style={{ color: "var(--muted)" }}>{t.desc}</p>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}
```

- [ ] **Step 6: Manual verification**

Run: `cd webapp && npm run dev`
- Log in, land on `/dashboard`: sidebar on the right (RTL), three rounded tiles, top bar.
- Click each tile → routes change (pages built in later tasks may 404 until then).
- Click "התנתק" → returns to `/login`.

- [ ] **Step 7: Commit**

```bash
git add webapp/src/components/Sidebar.tsx webapp/src/components/TopBar.tsx webapp/src/components/Card.tsx "webapp/src/app/(app)"
git commit -m "feat: add app shell (sidebar, topbar) and dashboard"
```

---

## Task 11: Reusable DataTable, Modal, and FormField components

**Files:**
- Create: `webapp/src/components/DataTable.tsx`
- Create: `webapp/src/components/Modal.tsx`
- Create: `webapp/src/components/FormField.tsx`

- [ ] **Step 1: Implement `webapp/src/components/DataTable.tsx`**

```tsx
import type { GridResult } from "@/types";

export default function DataTable({ data }: { data: GridResult | null }) {
  if (!data) return null;
  if (data.rows.length === 0) {
    return <p style={{ color: "var(--muted)", padding: 12 }}>אין תוצאות להצגה.</p>;
  }
  return (
    <div style={{
      overflow: "auto", borderRadius: "var(--radius)", border: "1px solid var(--border)",
      background: "var(--surface)", maxHeight: "65vh",
    }}>
      <table style={{ borderCollapse: "collapse", width: "100%", fontSize: 14 }}>
        <thead>
          <tr>
            {data.columns.map((c) => (
              <th key={c} style={{
                position: "sticky", top: 0, background: "var(--primary)", color: "#fff",
                padding: "12px 14px", textAlign: "right", whiteSpace: "nowrap",
              }}>{c}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.rows.map((row, i) => (
            <tr key={i} style={{ background: i % 2 ? "#f8fafc" : "#fff" }}>
              {row.map((v, j) => (
                <td key={j} style={{ padding: "10px 14px", textAlign: "right", borderTop: "1px solid var(--border)" }}>
                  {v === null || v === undefined ? "" : String(v)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

- [ ] **Step 2: Implement `webapp/src/components/Modal.tsx`**

```tsx
"use client";

export default function Modal({
  title, open, onClose, children,
}: {
  title: string; open: boolean; onClose: () => void; children: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, background: "rgba(15,23,42,.45)",
      display: "grid", placeItems: "center", zIndex: 900,
    }}>
      <div onClick={(e) => e.stopPropagation()} style={{
        background: "var(--surface)", borderRadius: "var(--radius)", padding: 24,
        width: 440, maxHeight: "85vh", overflow: "auto", boxShadow: "var(--shadow)",
      }}>
        <h2 style={{ marginTop: 0, color: "var(--primary)" }}>{title}</h2>
        {children}
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Implement `webapp/src/components/FormField.tsx`**

Renders the right control for a column: FK dropdown, fixed-option dropdown, or text input. Read-only when a pk is locked.

```tsx
"use client";
import type { ColumnMeta } from "@/types";

export interface FkOption { value: string; label: string; }

export default function FormField({
  column, value, fkOptions, locked, onChange,
}: {
  column: ColumnMeta;
  value: string;
  fkOptions: FkOption[] | undefined;
  locked: boolean;
  onChange: (v: string) => void;
}) {
  const label = (
    <label style={{ display: "block", marginBottom: 4, fontWeight: 600 }}>
      {column.label}
    </label>
  );

  if (column.fk && fkOptions) {
    return (
      <div style={{ marginBottom: 12 }}>
        {label}
        <select className="select" value={value} disabled={locked}
          onChange={(e) => onChange(e.target.value)}>
          <option value="">— בחר —</option>
          {fkOptions.map((o) => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>
      </div>
    );
  }

  if (column.options) {
    return (
      <div style={{ marginBottom: 12 }}>
        {label}
        <select className="select" value={value} disabled={locked}
          onChange={(e) => onChange(e.target.value)}>
          <option value="">— בחר —</option>
          {column.options.map((o) => <option key={o} value={o}>{o}</option>)}
        </select>
      </div>
    );
  }

  return (
    <div style={{ marginBottom: 12 }}>
      {label}
      <input className="input" value={value} readOnly={locked}
        onChange={(e) => onChange(e.target.value)} />
    </div>
  );
}
```

- [ ] **Step 4: Type-check**

Run: `cd webapp && npx tsc --noEmit`
Expected: no type errors.

- [ ] **Step 5: Commit**

```bash
git add webapp/src/components/DataTable.tsx webapp/src/components/Modal.tsx webapp/src/components/FormField.tsx
git commit -m "feat: add DataTable, Modal, and FormField components"
```

---

## Task 12: Tables API routes

Implements the CRUD endpoints. FK option lists for forms are resolved here using the FK SQL stored in metadata.

**Files:**
- Create: `webapp/src/app/api/tables/route.ts`
- Create: `webapp/src/app/api/tables/[key]/route.ts`
- Create: `webapp/src/app/api/tables/[key]/meta/route.ts`
- Create: `webapp/src/app/api/tables/[key]/row/route.ts`

- [ ] **Step 1: Implement `webapp/src/app/api/tables/route.ts`**

```ts
import { NextResponse } from "next/server";
import { tableList } from "@/lib/metadata";

export async function GET() {
  return NextResponse.json(tableList());
}
```

- [ ] **Step 2: Implement `webapp/src/app/api/tables/[key]/meta/route.ts`**

Returns each column plus, for FK columns, the `{value,label}` options (parity with `load_fk_options`).

```ts
import { NextResponse } from "next/server";
import { getTableMeta } from "@/lib/metadata";
import { runSelect } from "@/lib/db";

export async function GET(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  try {
    const meta = getTableMeta(key);
    const columns = await Promise.all(
      meta.columns.map(async (c) => {
        let fkOptions: { value: string; label: string }[] | null = null;
        if (c.fk) {
          const { rows } = await runSelect(c.fk);
          fkOptions = rows.map((r) => ({ value: String(r[0]), label: String(r[1]) }));
        }
        return { ...c, fkOptions };
      })
    );
    return NextResponse.json({ label: meta.label, pk: meta.pk, columns });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
```

- [ ] **Step 3: Implement `webapp/src/app/api/tables/[key]/row/route.ts`**

Fetches a single row by PK for the update flow. PK values arrive as a JSON-encoded `pk` query param (object of `{colName: value}`).

```ts
import { NextResponse } from "next/server";
import { getTableMeta } from "@/lib/metadata";
import { fetchRow } from "@/lib/db";

export async function GET(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const meta = getTableMeta(key);
  const raw = new URL(req.url).searchParams.get("pk") ?? "{}";
  const pkObj = JSON.parse(raw) as Record<string, string>;
  const pkVals = meta.pk.map((c) => pkObj[c]);
  try {
    const row = await fetchRow(key, meta.pk, pkVals);
    return NextResponse.json({ row });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
```

- [ ] **Step 4: Implement `webapp/src/app/api/tables/[key]/route.ts` (GET grid + POST/PUT/DELETE)**

```ts
import { NextResponse } from "next/server";
import { getTableMeta } from "@/lib/metadata";
import { runSelect, insertRow, updateRow, deleteRow } from "@/lib/db";

export async function GET(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  try {
    const meta = getTableMeta(key);
    const data = await runSelect(meta.select);
    return NextResponse.json(data);
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}

export async function POST(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const data = (await req.json()) as Record<string, unknown>;
  try {
    await insertRow(key, data);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}

export async function PUT(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const meta = getTableMeta(key);
  const body = (await req.json()) as Record<string, unknown>;
  const pkVals = meta.pk.map((c) => body[c]);
  try {
    const affected = await updateRow(key, meta.pk, pkVals, body);
    return NextResponse.json({ ok: true, affected });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const meta = getTableMeta(key);
  const body = (await req.json()) as Record<string, string>;
  const pkVals = meta.pk.map((c) => body[c]);
  try {
    const affected = await deleteRow(key, meta.pk, pkVals);
    return NextResponse.json({ ok: true, affected });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
```

- [ ] **Step 5: Manual verification (with the app running)**

Run: `cd webapp && npm run dev`
- `GET http://localhost:3000/api/tables` → 14 entries.
- `GET http://localhost:3000/api/tables/PERSON` → `{columns, rows}`.
- `GET http://localhost:3000/api/tables/PERSON/meta` → columns; `ID` has no fkOptions, `MEDICAL_STAFF` meta has fkOptions for `ID`.

- [ ] **Step 6: Commit**

```bash
git add "webapp/src/app/api/tables"
git commit -m "feat: add tables CRUD API routes"
```

---

## Task 13: CRUD page (generic data management)

Wires the metadata-driven UI: table picker, grid, and Add/Update/Delete using the modal form. Reproduces the Tkinter flows (update = enter pk → load → edit with pk locked; delete = enter pk → confirm).

**Files:**
- Create: `webapp/src/app/(app)/data/page.tsx`

- [ ] **Step 1: Implement `webapp/src/app/(app)/data/page.tsx`**

```tsx
"use client";
import { useEffect, useState, useCallback } from "react";
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import DataTable from "@/components/DataTable";
import Modal from "@/components/Modal";
import FormField, { type FkOption } from "@/components/FormField";
import { useToast } from "@/components/Toast";
import type { GridResult, ColumnMeta } from "@/types";

interface MetaColumn extends ColumnMeta { fkOptions: FkOption[] | null; }
interface TableMetaResp { label: string; pk: string[]; columns: MetaColumn[]; }
type Mode = "insert" | "update";

export default function DataPage() {
  const toast = useToast();
  const [tables, setTables] = useState<{ key: string; label: string }[]>([]);
  const [tableKey, setTableKey] = useState("");
  const [grid, setGrid] = useState<GridResult | null>(null);
  const [meta, setMeta] = useState<TableMetaResp | null>(null);

  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<Mode>("insert");
  const [form, setForm] = useState<Record<string, string>>({});
  const [lockPk, setLockPk] = useState(false);

  useEffect(() => {
    fetch("/api/tables").then((r) => r.json()).then((list) => {
      setTables(list);
      if (list.length) setTableKey(list[0].key);
    });
  }, []);

  const loadGrid = useCallback(async (key: string) => {
    const res = await fetch(`/api/tables/${key}`);
    const data = await res.json();
    if (res.ok) setGrid(data);
    else toast.show("error", data.message);
  }, [toast]);

  const loadMeta = useCallback(async (key: string): Promise<TableMetaResp> => {
    const res = await fetch(`/api/tables/${key}/meta`);
    const data = await res.json();
    setMeta(data);
    return data;
  }, []);

  useEffect(() => {
    if (tableKey) { loadGrid(tableKey); loadMeta(tableKey); }
  }, [tableKey, loadGrid, loadMeta]);

  function startInsert() {
    if (!meta) return;
    const editable = meta.columns.filter((c) => !c.auto);
    setForm(Object.fromEntries(editable.map((c) => [c.name, ""])));
    setMode("insert");
    setLockPk(false);
    setOpen(true);
  }

  async function startUpdate() {
    if (!meta) return;
    const pkObj: Record<string, string> = {};
    for (const c of meta.pk) {
      const v = window.prompt(`הזן ערך עבור מפתח: ${c}`);
      if (v === null) return;
      pkObj[c] = v;
    }
    const res = await fetch(`/api/tables/${tableKey}/row?pk=${encodeURIComponent(JSON.stringify(pkObj))}`);
    const data = await res.json();
    if (!res.ok) { toast.show("error", data.message); return; }
    if (!data.row) { toast.show("warning", "לא נמצאה רשומה עם המפתח שהוזן."); return; }
    const filled: Record<string, string> = {};
    for (const c of meta.columns) {
      const raw = data.row[c.name.toLowerCase()] ?? data.row[c.name];
      filled[c.name] = raw === null || raw === undefined ? "" : String(raw);
    }
    setForm(filled);
    setMode("update");
    setLockPk(true);
    setOpen(true);
  }

  async function deleteRecord() {
    if (!meta) return;
    const pkObj: Record<string, string> = {};
    for (const c of meta.pk) {
      const v = window.prompt(`למחיקה — הזן ערך עבור מפתח: ${c}`);
      if (v === null) return;
      pkObj[c] = v;
    }
    if (!window.confirm("האם אתה בטוח שברצונך למחוק את הרשומה?")) return;
    const res = await fetch(`/api/tables/${tableKey}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(pkObj),
    });
    const data = await res.json();
    if (!res.ok) { toast.show("error", data.message); return; }
    if (data.affected) toast.show("success", "הרשומה נמחקה בהצלחה.");
    else toast.show("warning", "לא נמצאה רשומה למחיקה.");
    loadGrid(tableKey);
  }

  async function save() {
    if (!meta) return;
    // basic required validation: non-auto pk fields must be filled
    for (const c of meta.columns) {
      if (c.pk && !c.auto && (form[c.name] ?? "").trim() === "" && !lockPk) {
        toast.show("warning", `חובה למלא את שדה המפתח: ${c.label}`);
        return;
      }
    }
    const method = mode === "insert" ? "POST" : "PUT";
    const payload =
      mode === "insert"
        ? Object.fromEntries(meta.columns.filter((c) => !c.auto).map((c) => [c.name, form[c.name]]))
        : form;
    const res = await fetch(`/api/tables/${tableKey}`, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!res.ok) { toast.show("error", data.message); return; }
    toast.show("success", mode === "insert" ? "הרשומה נוספה בהצלחה." : "הרשומה עודכנה בהצלחה.");
    setOpen(false);
    loadGrid(tableKey);
  }

  const formColumns = meta
    ? (mode === "insert" ? meta.columns.filter((c) => !c.auto) : meta.columns)
    : [];

  return (
    <>
      <TopBar title="🗄️ ניהול נתונים — כל הטבלאות" />
      <Card style={{ marginBottom: 20, display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>
        <select className="select" style={{ maxWidth: 320 }} value={tableKey}
          onChange={(e) => setTableKey(e.target.value)}>
          {tables.map((t) => <option key={t.key} value={t.key}>{t.label}</option>)}
        </select>
        <button className="btn btn-accent" onClick={() => loadGrid(tableKey)}>🔄 רענן</button>
        <button className="btn btn-green" onClick={startInsert}>➕ הוסף</button>
        <button className="btn btn-amber" onClick={startUpdate}>✏️ עדכן</button>
        <button className="btn btn-red" onClick={deleteRecord}>🗑️ מחק</button>
      </Card>

      <DataTable data={grid} />

      <Modal title={mode === "insert" ? "הוספת רשומה" : "עדכון רשומה"} open={open} onClose={() => setOpen(false)}>
        {formColumns.map((c) => (
          <FormField key={c.name} column={c} value={form[c.name] ?? ""}
            fkOptions={c.fkOptions ?? undefined}
            locked={lockPk && c.pk}
            onChange={(v) => setForm((f) => ({ ...f, [c.name]: v }))} />
        ))}
        <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
          <button className="btn btn-green" onClick={save}>שמור</button>
          <button className="btn btn-ghost" onClick={() => setOpen(false)}>ביטול</button>
        </div>
      </Modal>
    </>
  );
}
```

- [ ] **Step 2: Manual verification**

Run: `cd webapp && npm run dev`
- Open `/data`, pick a table → grid loads with friendly columns.
- Add a row in a simple table (e.g. DEPARTMENT) → success toast, grid refreshes.
- Update: pick PERSON, click עדכן, enter an existing ID → form loads prefilled, ID locked → change a field → save → success.
- Delete: enter a pk → confirm → row removed.
- FK table (e.g. PATIENT) → the "אדם" field is a name dropdown; blood type is an option dropdown.

- [ ] **Step 3: Commit**

```bash
git add "webapp/src/app/(app)/data"
git commit -m "feat: add generic metadata-driven CRUD page"
```

---

## Task 14: Reports API, Reports page, and chart

**Files:**
- Create: `webapp/src/app/api/reports/route.ts`
- Create: `webapp/src/app/api/reports/[key]/run/route.ts`
- Create: `webapp/src/components/ReportChart.tsx`
- Create: `webapp/src/app/(app)/reports/page.tsx`

- [ ] **Step 1: Implement `webapp/src/app/api/reports/route.ts`**

```ts
import { NextResponse } from "next/server";
import { reportList } from "@/lib/reports";

export async function GET() {
  return NextResponse.json(reportList());
}
```

- [ ] **Step 2: Implement `webapp/src/app/api/reports/[key]/run/route.ts`**

```ts
import { NextResponse } from "next/server";
import { getReport } from "@/lib/reports";
import { runSelect } from "@/lib/db";

export async function POST(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  try {
    const report = getReport(key);
    const data = await runSelect(report.sql);
    return NextResponse.json({ ...data, chart: report.chart ?? null });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
```

- [ ] **Step 3: Implement `webapp/src/components/ReportChart.tsx`**

```tsx
"use client";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import type { GridResult } from "@/types";

export default function ReportChart({
  data, labelColumn, valueColumn,
}: {
  data: GridResult; labelColumn: string; valueColumn: string;
}) {
  const li = data.columns.indexOf(labelColumn);
  const vi = data.columns.indexOf(valueColumn);
  if (li < 0 || vi < 0) return null;
  const chartData = data.rows.map((r) => ({
    name: String(r[li]),
    value: Number(r[vi]) || 0,
  }));
  return (
    <div style={{ width: "100%", height: 320, marginTop: 16 }}>
      <ResponsiveContainer>
        <BarChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Bar dataKey="value" fill="#0e7490" radius={[6, 6, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
```

- [ ] **Step 4: Implement `webapp/src/app/(app)/reports/page.tsx`**

```tsx
"use client";
import { useEffect, useState } from "react";
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import DataTable from "@/components/DataTable";
import ReportChart from "@/components/ReportChart";
import { useToast } from "@/components/Toast";
import type { GridResult } from "@/types";

interface ReportItem { key: string; label: string; desc: string; }
interface ChartHint { type: "bar"; labelColumn: string; valueColumn: string; }

export default function ReportsPage() {
  const toast = useToast();
  const [reports, setReports] = useState<ReportItem[]>([]);
  const [sel, setSel] = useState("");
  const [grid, setGrid] = useState<GridResult | null>(null);
  const [chart, setChart] = useState<ChartHint | null>(null);

  useEffect(() => {
    fetch("/api/reports").then((r) => r.json()).then((list) => {
      setReports(list);
      if (list.length) setSel(list[0].key);
    });
  }, []);

  const desc = reports.find((r) => r.key === sel)?.desc ?? "";

  async function run() {
    const res = await fetch(`/api/reports/${sel}/run`, { method: "POST" });
    const data = await res.json();
    if (!res.ok) { toast.show("error", data.message); return; }
    setGrid({ columns: data.columns, rows: data.rows });
    setChart(data.chart);
    if (data.rows.length === 0) toast.show("info", "השאילתה לא החזירה שורות.");
  }

  return (
    <>
      <TopBar title="📊 דו\&quot;חות מערכת — הרצת שאילתות" />
      <Card style={{ marginBottom: 20, display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>
        <select className="select" style={{ maxWidth: 360 }} value={sel}
          onChange={(e) => setSel(e.target.value)}>
          {reports.map((r) => <option key={r.key} value={r.key}>{r.label}</option>)}
        </select>
        <button className="btn btn-green" onClick={run}>▶️ הרץ שאילתה</button>
        <span style={{ color: "var(--muted)", fontStyle: "italic" }}>{desc}</span>
      </Card>

      {grid && chart && (
        <Card style={{ marginBottom: 20 }}>
          <ReportChart data={grid} labelColumn={chart.labelColumn} valueColumn={chart.valueColumn} />
        </Card>
      )}
      <DataTable data={grid} />
    </>
  );
}
```

- [ ] **Step 5: Manual verification**

Run: `cd webapp && npm run dev`
- Open `/reports`, default report selected, description shown.
- Run "התפלגות סוגי דם" → table + bar chart appear.
- Run "דירוג כלכליות רופאים" → table only (no chart hint).

- [ ] **Step 6: Commit**

```bash
git add "webapp/src/app/api/reports" webapp/src/components/ReportChart.tsx "webapp/src/app/(app)/reports"
git commit -m "feat: add reports API, reports page, and bar chart"
```

---

## Task 15: Actions API and Actions page

**Files:**
- Create: `webapp/src/app/api/actions/[name]/route.ts`
- Create: `webapp/src/app/(app)/actions/page.tsx`

- [ ] **Step 1: Implement `webapp/src/app/api/actions/[name]/route.ts`**

```ts
import { NextResponse } from "next/server";
import { runAction } from "@/lib/actions";

export async function POST(req: Request, { params }: { params: Promise<{ name: string }> }) {
  const { name } = await params;
  const body = (await req.json()) as Record<string, string>;
  try {
    const result = await runAction(name, body);
    return NextResponse.json({ ok: true, ...result });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
```

- [ ] **Step 2: Implement `webapp/src/app/(app)/actions/page.tsx`**

The action definitions are duplicated here as a client-side constant (the registry in `lib/actions.ts` is server-only because it imports `db`). Keep the two in sync.

```tsx
"use client";
import { useState } from "react";
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import DataTable from "@/components/DataTable";
import { useToast } from "@/components/Toast";
import type { GridResult } from "@/types";

interface ActionParam { name: string; label: string; default?: string; }
interface ActionUi { name: string; title: string; signature: string; color: string; params: ActionParam[]; }

const ACTIONS: ActionUi[] = [
  { name: "calculate_patient_bill", title: "פונקציה: חישוב חשבונית מטופל",
    signature: "calculate_patient_bill(patient_id)", color: "var(--accent)",
    params: [{ name: "patient_id", label: "מזהה מטופל:", default: "328308725" }] },
  { name: "get_department_roster_cursor", title: "פונקציה (REF CURSOR): צוות מחלקה לפי שכר",
    signature: "get_department_roster_cursor(dep_id, min_salary)", color: "var(--accent)",
    params: [
      { name: "dep_id", label: "מחלקה:", default: "2" },
      { name: "min_salary", label: "שכר מינ':", default: "0" },
    ] },
  { name: "apply_salary_bonus_by_performance", title: "פרוצדורה: בונוס שכר לרופאים מצטיינים",
    signature: "apply_salary_bonus_by_performance(min_treatments, bonus_percent)", color: "var(--amber)",
    params: [
      { name: "min_treatments", label: "מינ' טיפולים:", default: "2" },
      { name: "bonus_percent", label: "אחוז בונוס:", default: "10" },
    ] },
  { name: "reassign_doctor_department", title: "פרוצדורה: העברת רופא למחלקה אחרת",
    signature: "reassign_doctor_department(doc_id, new_dep_id)", color: "var(--amber)",
    params: [
      { name: "doc_id", label: "מזהה רופא:", default: "" },
      { name: "new_dep_id", label: "מחלקה חדשה:", default: "" },
    ] },
];

export default function ActionsPage() {
  const toast = useToast();
  const [log, setLog] = useState<string[]>(["מוכן. בחר פעולה והזן פרמטרים."]);
  const [grid, setGrid] = useState<GridResult | null>(null);
  const [values, setValues] = useState<Record<string, string>>(() => {
    const init: Record<string, string> = {};
    for (const a of ACTIONS) for (const p of a.params) init[`${a.name}.${p.name}`] = p.default ?? "";
    return init;
  });

  function append(line: string) { setLog((l) => [...l, line]); }

  async function run(a: ActionUi) {
    const body: Record<string, string> = {};
    for (const p of a.params) body[p.name] = values[`${a.name}.${p.name}`] ?? "";
    const res = await fetch(`/api/actions/${a.name}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) { toast.show("error", data.message); return; }

    if (data.scalar !== undefined && data.scalar !== null) {
      append(`💰 תוצאה: ${data.scalar}`);
    }
    if (data.notices) {
      append(`✅ ${a.title}:`);
      if (data.notices.length === 0) append("   הפעולה הסתיימה (ראה השפעה בטבלאות).");
      for (const n of data.notices) append("   " + n);
    }
    if (data.grid) {
      setGrid(data.grid);
      append(`📋 התקבלו ${data.grid.rows.length} שורות (ראה טבלה למטה).`);
    }
  }

  return (
    <>
      <TopBar title="⚙️ פעולות מתקדמות — פונקציות ופרוצדורות" />
      <div style={{ display: "grid", gap: 16 }}>
        {ACTIONS.map((a) => (
          <Card key={a.name} style={{ borderInlineStart: `5px solid ${a.color}` }}>
            <h3 style={{ margin: "0 0 4px" }}>{a.title}</h3>
            <code style={{ color: "var(--muted)" }}>{a.signature}</code>
            <div style={{ display: "flex", gap: 12, alignItems: "flex-end", flexWrap: "wrap", marginTop: 12 }}>
              {a.params.map((p) => (
                <div key={p.name}>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600 }}>{p.label}</label>
                  <input className="input" style={{ width: 140 }}
                    value={values[`${a.name}.${p.name}`] ?? ""}
                    onChange={(e) => setValues((v) => ({ ...v, [`${a.name}.${p.name}`]: e.target.value }))} />
                </div>
              ))}
              <button className="btn" onClick={() => run(a)}>הפעל</button>
            </div>
          </Card>
        ))}

        <Card>
          <h3 style={{ marginTop: 0 }}>פלט</h3>
          <pre style={{
            background: "#0f172a", color: "#bae6fd", borderRadius: 10, padding: 14,
            maxHeight: 220, overflow: "auto", whiteSpace: "pre-wrap", margin: 0,
          }}>{log.join("\n")}</pre>
        </Card>

        {grid && <DataTable data={grid} />}
      </div>
    </>
  );
}
```

- [ ] **Step 3: Manual verification**

Run: `cd webapp && npm run dev`
- `/actions`: four cards + output panel.
- "חישוב חשבונית מטופל" with a valid patient id → bill printed in the log.
- "צוות מחלקה" → roster table appears below + log line.
- "בונוס שכר" → NOTICE lines printed.
- Invalid input → red error toast.

- [ ] **Step 4: Commit**

```bash
git add "webapp/src/app/api/actions" "webapp/src/app/(app)/actions"
git commit -m "feat: add actions API and actions page (stage-D subprograms)"
```

---

## Task 16: Full-suite check, README, and final parity pass

**Files:**
- Create: `webapp/README.md`

- [ ] **Step 1: Run the full unit-test suite**

Run: `cd webapp && npm test`
Expected: all suites pass (queryBuilders, metadata, reports, session).

- [ ] **Step 2: Production build**

Run: `cd webapp && npm run build`
Expected: build completes with no type errors.

- [ ] **Step 3: Write `webapp/README.md`**

```markdown
# Hospital Management System — Web App

Next.js + TypeScript rebuild of the stage-E desktop app. Reuses the existing
Supabase Postgres database unchanged.

## Setup
1. `cd webapp && npm install`
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
```

- [ ] **Step 4: Parity walkthrough against the Tkinter app**

Manually confirm each item, fixing any gaps before committing:
- [ ] Login rejects empty/wrong credentials and gates the app.
- [ ] All 14 tables load, insert, update (pk-locked), and delete.
- [ ] FK fields show names; fixed-option fields show their lists; auto columns hidden on insert.
- [ ] All 5 reports run; blood-type and drug-revenue show charts.
- [ ] All 4 actions run, including REF CURSOR rows and procedure NOTICE messages.
- [ ] Whole UI is RTL Hebrew with rounded cards/buttons and the teal palette.

- [ ] **Step 5: Commit**

```bash
git add webapp/README.md
git commit -m "docs: add webapp README and finalize parity"
```

---

## Self-Review Notes

- **Spec coverage:** Login (T9), Dashboard (T10), generic CRUD over 14 tables (T4, T12, T13), Reports + charts (T5, T14), Actions incl. REF CURSOR & NOTICEs (T6, T15), RTL/theme/rounded (T8), env-based credentials (T1), DAL port (T2/T3), session/middleware auth (T7). All spec sections map to tasks.
- **Known coupling to keep in sync:** the action UI list in `(app)/actions/page.tsx` duplicates the server registry in `lib/actions.ts` (server module imports `db`, so it can't be imported by a client component). Both are listed; keep names/params identical.
- **Type consistency:** `GridResult`, `ColumnMeta`, `TableMeta`, `ReportDef`, `BuiltQuery` defined once in `types.ts` and reused; API meta route extends `ColumnMeta` with `fkOptions`.
- **pgbouncer note:** the Supabase pooler (port 6543, transaction mode) is what the Python app already uses; single-transaction REF CURSOR and `notice` capture work within one checked-out client, matching current behavior.
```