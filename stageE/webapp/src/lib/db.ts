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

/** Returns true if a connection can be opened (parity with verify_login's check). */
export async function canConnect(): Promise<boolean> {
  try {
    const client = await getPool().connect();
    client.release();
    return true;
  } catch (e) {
    console.error("DB connection failed:", (e as Error).message);
    return false;
  }
}

/** Runs a SELECT and returns { columns, rows } (rows as arrays, like Tkinter grid). */
export async function runSelect(sql: string, params: unknown[] = []): Promise<GridResult> {
  const res = await getPool().query({ text: sql, values: params, rowMode: "array" });
  const columns = res.fields.map((f) => f.name);
  return { columns, rows: res.rows as unknown[][] };
}

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
    (client as unknown as { removeListener: (e: string, cb: typeof onNotice) => void })
      .removeListener("notice", onNotice);
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
    try {
      await client.query("ROLLBACK");
    } catch {
      /* ignore rollback failure; preserve original error */
    }
    throw e;
  } finally {
    client.release();
  }
}
