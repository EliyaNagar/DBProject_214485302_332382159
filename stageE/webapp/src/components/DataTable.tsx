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
