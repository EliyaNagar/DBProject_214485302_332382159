import type { GridResult } from "@/types";

export default function DataTable({ data }: { data: GridResult | null }) {
  if (!data) return null;
  if (data.rows.length === 0) {
    return <p className="table-empty">אין תוצאות להצגה.</p>;
  }
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {data.columns.map((c) => (
              <th key={c}>{c}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.rows.map((row, i) => (
            <tr key={i}>
              {row.map((v, j) => (
                <td key={j}>
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
