export default function Card({ children, style }: { children: React.ReactNode; style?: React.CSSProperties }) {
  return (
    <div style={{
      background: "var(--surface)", borderRadius: "var(--radius)",
      boxShadow: "var(--shadow)", padding: 20, ...style,
    }}>
      {children}
    </div>
  );
}
