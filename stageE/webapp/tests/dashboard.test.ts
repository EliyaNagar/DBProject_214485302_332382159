import { describe, it, expect } from "vitest";
import { parseKpis, DASHBOARD_KPI_SQL, TREATMENTS_BY_DEPT_SQL } from "@/lib/dashboard";

describe("dashboard KPIs", () => {
  it("maps a DB row by index and computes occupancy %", () => {
    // order: patients, staff, departments, treatments_30d, total_beds, occupied_beds
    const k = parseKpis([120, 30, 5, 42, 80, 20]);
    expect(k.patients).toBe(120);
    expect(k.staff).toBe(30);
    expect(k.departments).toBe(5);
    expect(k.treatments30d).toBe(42);
    expect(k.totalBeds).toBe(80);
    expect(k.occupiedBeds).toBe(20);
    expect(k.occupancyPct).toBe(25);
  });

  it("occupancyPct is 0 when there are no beds", () => {
    expect(parseKpis([0, 0, 0, 0, 0, 0]).occupancyPct).toBe(0);
  });

  it("clamps occupancyPct to 100 when distinct patients exceed bed count", () => {
    expect(parseKpis([0, 0, 0, 0, 10, 25]).occupancyPct).toBe(100);
  });

  it("coerces string/null DB values to numbers", () => {
    const k = parseKpis(["120", null, "5", "0", "80", "40"]);
    expect(k.patients).toBe(120);
    expect(k.staff).toBe(0);
    expect(k.occupancyPct).toBe(50);
  });

  it("KPI SQL references the expected tables", () => {
    expect(DASHBOARD_KPI_SQL).toContain("PATIENT");
    expect(DASHBOARD_KPI_SQL).toContain("MEDICAL_STAFF");
    expect(DASHBOARD_KPI_SQL).toContain("DEPARTMENT");
    expect(DASHBOARD_KPI_SQL).toContain("TREATMENT");
  });

  it("chart SQL is a SELECT", () => {
    expect(TREATMENTS_BY_DEPT_SQL.toUpperCase()).toContain("SELECT");
  });
});
