import {
  callScalarFunction,
  callProcedure,
  fetchRefcursor,
} from "@/lib/db";
import type { GridResult } from "@/types";

export interface ActionParam {
  name: string;
  label: string;
  default?: string;
}

export type ActionKind = "scalar" | "cursor" | "procedure";

export interface ActionDef {
  name: string;
  title: string;
  signature: string;
  kind: ActionKind;
  color: "accent" | "warning";
  params: ActionParam[];
}

export const ACTIONS: Record<string, ActionDef> = {
  calculate_patient_bill: {
    name: "calculate_patient_bill",
    title: "פונקציה: חישוב חשבונית מטופל",
    signature: "calculate_patient_bill(patient_id)",
    kind: "scalar",
    color: "accent",
    params: [{ name: "patient_id", label: "מזהה מטופל:", default: "328308725" }],
  },
  get_department_roster_cursor: {
    name: "get_department_roster_cursor",
    title: "פונקציה (REF CURSOR): צוות מחלקה לפי שכר",
    signature: "get_department_roster_cursor(dep_id, min_salary)",
    kind: "cursor",
    color: "accent",
    params: [
      { name: "dep_id", label: "מחלקה:", default: "2" },
      { name: "min_salary", label: "שכר מינ':", default: "0" },
    ],
  },
  apply_salary_bonus_by_performance: {
    name: "apply_salary_bonus_by_performance",
    title: "פרוצדורה: בונוס שכר לרופאים מצטיינים",
    signature: "apply_salary_bonus_by_performance(min_treatments, bonus_percent)",
    kind: "procedure",
    color: "warning",
    params: [
      { name: "min_treatments", label: "מינ' טיפולים:", default: "2" },
      { name: "bonus_percent", label: "אחוז בונוס:", default: "10" },
    ],
  },
  reassign_doctor_department: {
    name: "reassign_doctor_department",
    title: "פרוצדורה: העברת רופא למחלקה אחרת",
    signature: "reassign_doctor_department(doc_id, new_dep_id)",
    kind: "procedure",
    color: "warning",
    params: [
      { name: "doc_id", label: "מזהה רופא:", default: "" },
      { name: "new_dep_id", label: "מחלקה חדשה:", default: "" },
    ],
  },
};

export interface ActionResult {
  scalar?: unknown;
  grid?: GridResult;
  notices?: string[];
}

export async function runAction(
  name: string,
  params: Record<string, string>
): Promise<ActionResult> {
  switch (name) {
    case "calculate_patient_bill":
      return {
        // Explicit ::type casts: node-postgres sends params untyped, so without
        // these Postgres can't resolve the function overload (psycopg2 sent them
        // typed). Casts mirror the Python int()/float() conversions.
        scalar: await callScalarFunction("SELECT calculate_patient_bill($1::int)", [
          parseInt(params.patient_id, 10),
        ]),
      };
    case "get_department_roster_cursor":
      return {
        grid: await fetchRefcursor(
          "SELECT get_department_roster_cursor($1::int, $2::numeric)",
          [parseInt(params.dep_id, 10), parseFloat(params.min_salary)],
          "dept_staff_result_cursor"
        ),
      };
    case "apply_salary_bonus_by_performance":
      return {
        notices: await callProcedure(
          "CALL apply_salary_bonus_by_performance($1::int, $2::numeric)",
          [parseInt(params.min_treatments, 10), parseFloat(params.bonus_percent)]
        ),
      };
    case "reassign_doctor_department":
      return {
        notices: await callProcedure("CALL reassign_doctor_department($1::int, $2::int)", [
          parseInt(params.doc_id, 10),
          parseInt(params.new_dep_id, 10),
        ]),
      };
    default:
      throw new Error(`Unknown action: ${name}`);
  }
}
