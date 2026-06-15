export default function TopBar({ title }: { title: string }) {
  return (
    <header style={{
      background: "var(--surface)", borderRadius: "var(--radius)", boxShadow: "var(--shadow)",
      padding: "16px 24px", marginBottom: 20, fontSize: 20, fontWeight: 700, color: "var(--primary)",
    }}>
      {title}
    </header>
  );
}
