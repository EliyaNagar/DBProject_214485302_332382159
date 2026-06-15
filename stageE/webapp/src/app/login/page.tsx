"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useToast } from "@/components/Toast";

export default function LoginPage() {
  const router = useRouter();
  const toast = useToast();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      const data = await res.json();
      if (data.ok) {
        toast.show("success", data.message);
        router.push("/dashboard");
      } else {
        toast.show("error", data.message);
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ minHeight: "100vh", display: "grid", placeItems: "center" }}>
      <form onSubmit={submit} style={{
        background: "var(--surface)", borderRadius: "var(--radius)", boxShadow: "var(--shadow)",
        padding: 36, width: 360, display: "flex", flexDirection: "column", gap: 16,
      }}>
        <h1 style={{ textAlign: "center", color: "var(--primary)", margin: 0 }}>
          🏥 כניסה למערכת
        </h1>
        <label>
          שם משתמש
          <input className="input" value={username} onChange={(e) => setUsername(e.target.value)} autoFocus />
        </label>
        <label>
          סיסמה
          <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        </label>
        <button className="btn" disabled={busy} type="submit">
          {busy ? "מתחבר..." : "התחבר"}
        </button>
      </form>
    </div>
  );
}
