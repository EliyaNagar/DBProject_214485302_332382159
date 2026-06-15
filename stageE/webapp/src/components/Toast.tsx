"use client";
import { createContext, useCallback, useContext, useState } from "react";

type ToastKind = "info" | "success" | "error" | "warning";
interface ToastItem { id: number; kind: ToastKind; text: string; }
interface ToastApi { show: (kind: ToastKind, text: string) => void; }

const ToastCtx = createContext<ToastApi | null>(null);
const COLORS: Record<ToastKind, string> = {
  info: "#2563eb",
  success: "#16a34a",
  error: "#dc2626",
  warning: "#d97706",
};

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const show = useCallback((kind: ToastKind, text: string) => {
    const id = Date.now() + Math.random();
    setItems((p) => [...p, { id, kind, text }]);
    setTimeout(() => setItems((p) => p.filter((t) => t.id !== id)), 4000);
  }, []);
  return (
    <ToastCtx.Provider value={{ show }}>
      {children}
      <div style={{ position: "fixed", top: 16, left: 16, display: "flex", flexDirection: "column", gap: 8, zIndex: 1000 }}>
        {items.map((t) => (
          <div key={t.id} style={{
            background: "#fff", borderInlineStart: `5px solid ${COLORS[t.kind]}`,
            borderRadius: 10, padding: "12px 16px", boxShadow: "0 4px 20px rgba(15,23,42,.12)",
            minWidth: 240, maxWidth: 360, fontWeight: 500,
          }}>{t.text}</div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export function useToast(): ToastApi {
  const ctx = useContext(ToastCtx);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
}
