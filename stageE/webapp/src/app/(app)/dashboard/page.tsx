import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import Link from "next/link";

const TILES = [
  { href: "/data", title: "🗄️ ניהול נתונים", desc: "הוספה, עדכון, מחיקה ושליפה מכל 14 הטבלאות.", color: "var(--accent)" },
  { href: "/reports", title: "📊 דו\"חות ושאילתות", desc: "הרצת שאילתות שלב ב' עם תרשימים.", color: "var(--green)" },
  { href: "/actions", title: "⚙️ פעולות מתקדמות", desc: "פונקציות ופרוצדורות שלב ד'.", color: "var(--amber)" },
];

export default function DashboardPage() {
  return (
    <>
      <TopBar title="מערכת ניהול בית חולים — תפריט ראשי" />
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", gap: 20 }}>
        {TILES.map((t) => (
          <Link key={t.href} href={t.href} style={{ textDecoration: "none", color: "inherit" }}>
            <Card style={{ borderTop: `5px solid ${t.color}` }}>
              <h2 style={{ marginTop: 0 }}>{t.title}</h2>
              <p style={{ color: "var(--muted)" }}>{t.desc}</p>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}
