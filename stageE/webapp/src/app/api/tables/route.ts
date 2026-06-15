import { NextResponse } from "next/server";
import { tableList } from "@/lib/metadata";

export async function GET() {
  return NextResponse.json(tableList());
}
