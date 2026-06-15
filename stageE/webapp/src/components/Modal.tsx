"use client";

export default function Modal({
  title, open, onClose, children,
}: {
  title: string; open: boolean; onClose: () => void; children: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, background: "rgba(15,23,42,.45)",
      display: "grid", placeItems: "center", zIndex: 900,
    }}>
      <div onClick={(e) => e.stopPropagation()} style={{
        background: "var(--surface)", borderRadius: "var(--radius)", padding: 24,
        width: 440, maxHeight: "85vh", overflow: "auto", boxShadow: "var(--shadow)",
      }}>
        <h2 style={{ marginTop: 0, color: "var(--primary)" }}>{title}</h2>
        {children}
      </div>
    </div>
  );
}
