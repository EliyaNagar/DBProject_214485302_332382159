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
    <div className="login-wrap">
      <form onSubmit={submit} className="login-card">
        <div className="login-badge">HOSPITAL SYSTEM</div>
        <h1 className="login-title">🏥 כניסה למערכת</h1>
        <div className="field">
          <label className="field-label">שם משתמש</label>
          <input className="input" value={username} onChange={(e) => setUsername(e.target.value)} autoFocus />
        </div>
        <div className="field">
          <label className="field-label">סיסמה</label>
          <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        </div>
        <button className="btn" disabled={busy} type="submit">
          {busy ? "מתחבר..." : "התחבר"}
        </button>
      </form>
    </div>
  );
}
