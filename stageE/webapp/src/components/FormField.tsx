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
    <label className="field-label">
      {column.label}
    </label>
  );

  if (column.fk && fkOptions) {
    return (
      <div className="field">
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
      <div className="field">
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
    <div className="field">
      {label}
      <input className="input" value={value} readOnly={locked}
        onChange={(e) => onChange(e.target.value)} />
    </div>
  );
}
