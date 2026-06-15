"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import ReportChart from "@/components/ReportChart";
import { useToast } from "@/components/Toast";
import type { GridResult } from "@/types";
import type { DashboardKpis } from "@/lib/dashboard";

const TILES = [
  { href: "/data", title: "ניהול נתונים", desc: "הוספה, עדכון, מחיקה ושליפה מכל 14 הטבלאות." },
  { href: "/reports", title: "דוחות ושאילתות", desc: "הרצת שאילתות שלב ב' עם תרשימים." },
  { href: "/actions", title: "פעולות מתקדמות", desc: "פונקציות ופרוצדורות שלב ד'." },
];

const STATS: { key: keyof DashboardKpis; label: string; suffix?: string }[] = [
  { key: "patients", label: "מטופלים" },
  { key: "staff", label: "צוות רפואי" },
  { key: "departments", label: "מחלקות" },
  { key: "treatments30d", label: "טיפולים (30 ימים)" },
  { key: "occupancyPct", label: "תפוסת מיטות", suffix: "%" },
];

export default function DashboardPage() {
  const toast = useToast();
  const [kpis, setKpis] = useState<DashboardKpis | null>(null);
  const [chart, setChart] = useState<GridResult | null>(null);

  useEffect(() => {
    fetch("/api/dashboard")
      .then(async (r) => {
        const data = await r.json();
        if (!r.ok) throw new Error(data.message);
        setKpis(data.kpis);
        setChart(data.chart);
      })
      .catch((e) => toast.show("error", (e as Error).message));
  }, [toast]);

  return (
    <>
      <TopBar title="מערכת ניהול בית חולים — לוח בקרה" />

      <div className="dashboard-grid stagger" style={{ marginBottom: 24 }}>
        {STATS.map((s) => (
          <Card key={s.key}>
            <div className="stat-card">
              <span className="stat-value">
                {kpis ? kpis[s.key] : "—"}{kpis && s.suffix ? s.suffix : ""}
              </span>
              <span className="stat-label">{s.label}</span>
            </div>
          </Card>
        ))}
      </div>

      {chart && chart.rows.length > 0 && (
        <Card style={{ marginBottom: 24 }}>
          <h2 style={{ marginTop: 0, fontSize: 20 }}>טיפולים לפי מחלקה</h2>
          <ReportChart data={chart} labelColumn="מחלקה" valueColumn="טיפולים" />
        </Card>
      )}

      <div className="dashboard-grid stagger">
        {TILES.map((t) => (
          <Link key={t.href} href={t.href} className="tile">
            <Card interactive>
              <h2 className="tile-title">{t.title}</h2>
              <p className="tile-desc">{t.desc}</p>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}
