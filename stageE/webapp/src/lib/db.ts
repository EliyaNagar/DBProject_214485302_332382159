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
