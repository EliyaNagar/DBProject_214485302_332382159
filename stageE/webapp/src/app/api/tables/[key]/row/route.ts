import { NextResponse } from "next/server";
import { getTableMeta } from "@/lib/metadata";
import { fetchRow } from "@/lib/db";

export async function GET(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const meta = getTableMeta(key);
  const raw = new URL(req.url).searchParams.get("pk") ?? "{}";
  const pkObj = JSON.parse(raw) as Record<string, string>;
  const pkVals = meta.pk.map((c) => pkObj[c]);
  try {
    const row = await fetchRow(key, meta.pk, pkVals);
    return NextResponse.json({ row });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
