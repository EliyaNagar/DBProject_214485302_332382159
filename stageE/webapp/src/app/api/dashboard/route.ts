import { NextResponse } from "next/server";
import { runSelect } from "@/lib/db";
import { DASHBOARD_KPI_SQL, TREATMENTS_BY_DEPT_SQL, parseKpis } from "@/lib/dashboard";

export async function GET() {
  try {
    const [kpiRes, chart] = await Promise.all([
      runSelect(DASHBOARD_KPI_SQL),
      runSelect(TREATMENTS_BY_DEPT_SQL),
    ]);
    const kpis = parseKpis(kpiRes.rows[0] ?? []);
    return NextResponse.json({ kpis, chart });
  } catch (e) {
    return NextResponse.json({ message: (e as Error).message }, { status: 500 });
  }
}
