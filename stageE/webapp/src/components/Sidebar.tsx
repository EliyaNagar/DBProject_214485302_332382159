"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const NAV = [
  { href: "/dashboard", label: "🏠 ראשי" },
  { href: "/data", label: "🗄️ ניהול נתונים" },
  { href: "/reports", label: "📊 דו\"חות" },
  { href: "/actions", label: "⚙️ פעולות מתקדמות" },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  async function logout() {
    await fetch("/api/logout", { method: "POST" });
    router.push("/login");
  }

  return (
    <aside style={{
      width: 240, background: "var(--primary)", color: "#fff", display: "flex",
      flexDirection: "column", padding: 18, gap: 6, minHeight: "100vh",
    }}>
      <div style={{ fontSize: 18, fontWeight: 700, padding: "8px 10px 18px" }}>
        🏥 בית חולים
      </div>
      {NAV.map((n) => {
        const active = pathname === n.href;
        return (
          <Link key={n.href} href={n.href} style={{
            color: "#fff", textDecoration: "none", padding: "10px 12px",
            borderRadius: 10, fontWeight: 600,
            background: active ? "rgba(255,255,255,.18)" : "transparent",
          }}>
            {n.label}
          </Link>
        );
      })}
      <button className="btn btn-red" onClick={logout} style={{ marginTop: "auto" }}>
        🚪 התנתק
      </button>
    </aside>
  );
}
