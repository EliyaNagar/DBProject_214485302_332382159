"use client";
import { useState } from "react";
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import DataTable from "@/components/DataTable";
import { useToast } from "@/components/Toast";
import type { GridResult } from "@/types";

interface ActionParam { name: string; label: string; default?: string; }
interface ActionUi { name: string; title: string; signature: string; params: ActionParam[]; }

const ACTIONS: ActionUi[] = [
  { name: "calculate_patient_bill", title: "פונקציה: חישוב חשבונית מטופל",
    signature: "calculate_patient_bill(patient_id)",
    params: [{ name: "patient_id", label: "מזהה מטופל:", default: "328308725" }] },
  { name: "get_department_roster_cursor", title: "פונקציה (REF CURSOR): צוות מחלקה לפי שכר",
    signature: "get_department_roster_cursor(dep_id, min_salary)",
    params: [
      { name: "dep_id", label: "מחלקה:", default: "2" },
      { name: "min_salary", label: "שכר מינ':", default: "0" },
    ] },
  { name: "apply_salary_bonus_by_performance", title: "פרוצדורה: בונוס שכר לרופאים מצטיינים",
    signature: "apply_salary_bonus_by_performance(min_treatments, bonus_percent)",
    params: [
      { name: "min_treatments", label: "מינ' טיפולים:", default: "2" },
      { name: "bonus_percent", label: "אחוז בונוס:", default: "10" },
    ] },
  { name: "reassign_doctor_department", title: "פרוצדורה: העברת רופא למחלקה אחרת",
    signature: "reassign_doctor_department(doc_id, new_dep_id)",
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
      append(`תוצאה: ${data.scalar}`);
    }
    if (data.notices) {
      append(`${a.title}:`);
      if (data.notices.length === 0) append("   הפעולה הסתיימה (ראה השפעה בטבלאות).");
      for (const n of data.notices) append("   " + n);
    }
    if (data.grid) {
      setGrid(data.grid);
      append(`התקבלו ${data.grid.rows.length} שורות (ראה טבלה למטה).`);
    }
  }

  return (
    <>
      <TopBar title="פעולות מתקדמות — פונקציות ופרוצדורות" />
      <div className="stack-grid stagger">
        {ACTIONS.map((a) => (
          <Card key={a.name}>
            <h3 style={{ margin: "0 0 4px" }}>{a.title}</h3>
            <code className="code-sig">{a.signature}</code>
            <div style={{ display: "flex", gap: 12, alignItems: "flex-end", flexWrap: "wrap", marginTop: 12 }}>
              {a.params.map((p) => (
                <div key={p.name} className="field" style={{ marginBottom: 0 }}>
                  <label className="field-label">{p.label}</label>
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
          <pre className="output-log">{log.join("\n")}</pre>
        </Card>

        {grid && <DataTable data={grid} />}
      </div>
    </>
  );
}
