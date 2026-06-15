"use client";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import type { GridResult } from "@/types";

export default function ReportChart({
  data, labelColumn, valueColumn,
}: {
  data: GridResult; labelColumn: string; valueColumn: string;
}) {
  const li = data.columns.indexOf(labelColumn);
  const vi = data.columns.indexOf(valueColumn);
  if (li < 0 || vi < 0) return null;
  const chartData = data.rows.map((r) => ({
    name: String(r[li]),
    value: Number(r[vi]) || 0,
  }));
  return (
    <div style={{ width: "100%", height: 320, marginTop: 16 }}>
      <ResponsiveContainer>
        <BarChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Bar dataKey="value" fill="#0e7490" radius={[6, 6, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
