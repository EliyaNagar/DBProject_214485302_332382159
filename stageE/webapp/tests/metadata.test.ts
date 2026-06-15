import { describe, it, expect } from "vitest";
import { TABLES, getTableMeta, tableList } from "@/lib/metadata";

describe("metadata", () => {
  it("defines all 14 tables", () => {
    expect(Object.keys(TABLES)).toHaveLength(14);
  });

  it("every table has a label, non-empty pk, select, and columns", () => {
    for (const [key, t] of Object.entries(TABLES)) {
      expect(t.label, `${key} label`).toBeTruthy();
      expect(t.pk.length, `${key} pk`).toBeGreaterThan(0);
      expect(t.select, `${key} select`).toContain("SELECT");
      expect(t.columns.length, `${key} columns`).toBeGreaterThan(0);
    }
  });

  it("every pk column name exists in that table's columns (case-insensitive)", () => {
    for (const [key, t] of Object.entries(TABLES)) {
      const names = t.columns.map((c) => c.name.toLowerCase());
      for (const pk of t.pk) {
        expect(names, `${key} pk ${pk}`).toContain(pk.toLowerCase());
      }
    }
  });

  it("tableList returns key+label pairs", () => {
    const list = tableList();
    expect(list.find((x) => x.key === "PERSON")?.label).toContain("Person");
  });

  it("getTableMeta throws on unknown key", () => {
    expect(() => getTableMeta("NOPE")).toThrow();
  });
});
