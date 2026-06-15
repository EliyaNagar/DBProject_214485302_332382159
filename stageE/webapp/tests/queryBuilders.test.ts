import { describe, it, expect } from "vitest";
import {
  buildInsert,
  buildUpdate,
  buildDelete,
  buildFetchRow,
} from "@/lib/queryBuilders";

describe("buildInsert", () => {
  it("builds a parameterized insert", () => {
    const q = buildInsert("PERSON", { ID: 1, FirstName: "Dana" });
    expect(q.sql).toBe("INSERT INTO PERSON (ID, FirstName) VALUES ($1, $2)");
    expect(q.params).toEqual([1, "Dana"]);
  });
});

describe("buildUpdate", () => {
  it("excludes pk columns from SET and uses them in WHERE", () => {
    const q = buildUpdate(
      "MEDICAL_STAFF",
      ["id"],
      [5],
      { id: 5, Salary: 9000, Email: "a@b.c" }
    );
    expect(q.sql).toBe(
      "UPDATE MEDICAL_STAFF SET Salary = $1, Email = $2 WHERE id = $3"
    );
    expect(q.params).toEqual([9000, "a@b.c", 5]);
  });

  it("handles multiple pk columns with correct placeholder numbering", () => {
    const q = buildUpdate(
      "T",
      ["id", "sk"],
      [1, "key"],
      { id: 1, sk: "key", val: 99 }
    );
    expect(q.sql).toBe("UPDATE T SET val = $1 WHERE id = $2 AND sk = $3");
    expect(q.params).toEqual([99, 1, "key"]);
  });

  it("throws when there are no non-pk columns to update", () => {
    expect(() =>
      buildUpdate("ADDRESS", ["city", "street"], ["Haifa", "Herzl"], {
        city: "Haifa",
        street: "Herzl",
      })
    ).toThrow();
  });
});

describe("buildDelete", () => {
  it("builds a composite-key delete", () => {
    const q = buildDelete("ADDRESS", ["city", "street"], ["Haifa", "Herzl"]);
    expect(q.sql).toBe("DELETE FROM ADDRESS WHERE city = $1 AND street = $2");
    expect(q.params).toEqual(["Haifa", "Herzl"]);
  });
});

describe("buildFetchRow", () => {
  it("selects all columns by pk", () => {
    const q = buildFetchRow("PATIENT", ["id"], [9]);
    expect(q.sql).toBe("SELECT * FROM PATIENT WHERE id = $1");
    expect(q.params).toEqual([9]);
  });
});
