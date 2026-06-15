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
