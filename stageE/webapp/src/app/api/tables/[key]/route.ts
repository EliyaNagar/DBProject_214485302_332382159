import { NextResponse } from "next/server";
import { getTableMeta } from "@/lib/metadata";
import { runSelect, insertRow, updateRow, deleteRow } from "@/lib/db";

export async function GET(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  try {
    const meta = getTableMeta(key);
    const data = await runSelect(meta.select);
    return NextResponse.json(data);
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}

export async function POST(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const data = (await req.json()) as Record<string, unknown>;
  try {
    await insertRow(key, data);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}

export async function PUT(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const meta = getTableMeta(key);
  const body = (await req.json()) as Record<string, unknown>;
  const pkVals = meta.pk.map((c) => body[c]);
  try {
    const affected = await updateRow(key, meta.pk, pkVals, body);
    return NextResponse.json({ ok: true, affected });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const meta = getTableMeta(key);
  const body = (await req.json()) as Record<string, string>;
  const pkVals = meta.pk.map((c) => body[c]);
  try {
    const affected = await deleteRow(key, meta.pk, pkVals);
    return NextResponse.json({ ok: true, affected });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
