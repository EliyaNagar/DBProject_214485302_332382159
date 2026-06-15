import { NextResponse } from "next/server";
import { runAction } from "@/lib/actions";

export async function POST(req: Request, { params }: { params: Promise<{ name: string }> }) {
  const { name } = await params;
  const body = (await req.json()) as Record<string, string>;
  try {
    const result = await runAction(name, body);
    return NextResponse.json({ ok: true, ...result });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
