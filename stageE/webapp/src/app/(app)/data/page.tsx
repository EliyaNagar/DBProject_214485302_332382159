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
