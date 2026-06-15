export default function Card({
  children,
  style,
  interactive = false,
}: {
  children: React.ReactNode;
  style?: React.CSSProperties;
  interactive?: boolean;
}) {
  return (
    <div className={"card" + (interactive ? " card-interactive" : "")} style={style}>
      {children}
    </div>
  );
}
