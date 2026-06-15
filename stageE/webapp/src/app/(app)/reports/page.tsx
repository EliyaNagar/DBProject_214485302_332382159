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
      <TopBar title="📊 דוחות מערכת — הרצת שאילתות" />
      <div className="card" style={{ marginBottom: 20 }}>
        <div className="toolbar">
          <select className="select" value={sel}
            onChange={(e) => setSel(e.target.value)}>
            {reports.map((r) => <option key={r.key} value={r.key}>{r.label}</option>)}
          </select>
          <button className="btn btn-green" onClick={run}>▶️ הרץ שאילתה</button>
          <span className="toolbar-hint">{desc}</span>
        </div>
      </div>

      {grid && chart && (
        <Card style={{ marginBottom: 20 }}>
          <ReportChart data={grid} labelColumn={chart.labelColumn} valueColumn={chart.valueColumn} />
        </Card>
      )}
      <DataTable data={grid} />
    </>
  );
}
