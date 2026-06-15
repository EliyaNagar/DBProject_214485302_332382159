import { NextResponse } from "next/server";
import { getReport } from "@/lib/reports";
import { runSelect } from "@/lib/db";

export async function POST(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  try {
    const report = getReport(key);
    const data = await runSelect(report.sql);
    return NextResponse.json({ ...data, chart: report.chart ?? null });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 400 });
  }
}
