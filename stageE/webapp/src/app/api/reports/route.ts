import { NextResponse } from "next/server";
import { reportList } from "@/lib/reports";

export async function GET() {
  return NextResponse.json(reportList());
}
