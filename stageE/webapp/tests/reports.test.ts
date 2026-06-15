import { describe, it, expect } from "vitest";
import { REPORTS, getReport, reportList } from "@/lib/reports";

describe("reports", () => {
  it("defines the 5 stage-B reports", () => {
    expect(Object.keys(REPORTS)).toHaveLength(5);
  });

  it("each report has a label, desc and SELECT sql", () => {
    for (const [key, r] of Object.entries(REPORTS)) {
      expect(r.label, `${key} label`).toBeTruthy();
      expect(r.desc, `${key} desc`).toBeTruthy();
      expect(r.sql.toUpperCase(), `${key} sql`).toContain("SELECT");
    }
  });

  it("blood_type report has a bar chart hint", () => {
    expect(REPORTS.blood_type.chart?.type).toBe("bar");
  });

  it("getReport throws on unknown key", () => {
    expect(() => getReport("nope")).toThrow();
  });

  it("reportList returns key/label/desc", () => {
    expect(reportList().find((r) => r.key === "available_beds")).toBeTruthy();
  });
});
