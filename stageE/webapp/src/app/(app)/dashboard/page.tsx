import TopBar from "@/components/TopBar";
import Card from "@/components/Card";
import Link from "next/link";

const TILES = [
  { href: "/data", title: "🗄️ ניהול נתונים", desc: "הוספה, עדכון, מחיקה ושליפה מכל 14 הטבלאות." },
  { href: "/reports", title: "📊 דו\"חות ושאילתות", desc: "הרצת שאילתות שלב ב' עם תרשימים." },
  { href: "/actions", title: "⚙️ פעולות מתקדמות", desc: "פונקציות ופרוצדורות שלב ד'." },
];

export default function DashboardPage() {
  return (
    <>
      <TopBar title="מערכת ניהול בית חולים — תפריט ראשי" />
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
