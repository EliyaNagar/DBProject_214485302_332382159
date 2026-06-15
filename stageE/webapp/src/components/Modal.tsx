"use client";

export default function Modal({
  title, open, onClose, children,
}: {
  title: string; open: boolean; onClose: () => void; children: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2 className="modal-title">{title}</h2>
        {children}
      </div>
    </div>
  );
}
