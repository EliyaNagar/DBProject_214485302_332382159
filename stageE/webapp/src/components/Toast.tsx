"use client";
import { createContext, useCallback, useContext, useState } from "react";

type ToastKind = "info" | "success" | "error" | "warning";
interface ToastItem { id: number; kind: ToastKind; text: string; }
interface ToastApi { show: (kind: ToastKind, text: string) => void; }

const ToastCtx = createContext<ToastApi | null>(null);

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
      <div className="toast-stack">
        {items.map((t) => (
          <div key={t.id} className={"toast " + t.kind}>{t.text}</div>
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
