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
  if (setCols.length === 0) {
    throw new Error("אין שדות לעדכון (כל העמודות הן חלק מהמפתח הראשי).");
  }
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
