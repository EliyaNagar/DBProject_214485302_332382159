import { NextResponse } from "next/server";
import { getTableMeta } from "@/lib/metadata";
import { runSelect } from "@/lib/db";

export async function GET(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  try {
    const meta = getTableMeta(key);
    const columns = await Promise.all(
      meta.columns.map(async (c) => {
        let fkOptions: { value: string; label: string }[] | null = null;
        if (c.fk) {
          const { rows } = await runSelect(c.fk);
          fkOptions = rows.map((r) => ({ value: String(r[0]), label: String(r[1]) }));
        }
        return { ...c, fkOptions };
      })
    );
    return NextResponse.json({ label: meta.label, pk: meta.pk, columns });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
