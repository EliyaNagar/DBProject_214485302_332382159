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
    <aside className="sidebar">
      <div className="sidebar-brand">
        🏥 בית חולים
        <small>מערכת ניהול</small>
      </div>
      {NAV.map((n) => {
        const active = pathname === n.href;
        return (
          <Link key={n.href} href={n.href} className={"nav-link" + (active ? " active" : "")}>
            {n.label}
          </Link>
        );
      })}
      <div className="sidebar-spacer" />
      <button className="btn btn-red" onClick={logout}>
        🚪 התנתק
      </button>
    </aside>
  );
}
