import type { ReportDef } from "@/types";

export const REPORTS: Record<string, ReportDef> = {
  doctor_efficiency: {
    key: "doctor_efficiency",
    label: "דירוג כלכליות רופאים (שאילתה 1)",
    desc: "כמות טיפולים מול שכר - מי הרופא היעיל ביותר.",
    sql: `
      SELECT
        p.FirstName || ' ' || p.LastName AS "שם הרופא",
        COUNT(t.Treatment_Date) AS "סך טיפולים",
        ms.Salary AS "שכר",
        (NULLIF(ms.Salary, 0) / NULLIF(COUNT(t.Treatment_Date),0)) AS "מדד רווחיות"
      FROM PERSON p
      JOIN MEDICAL_STAFF ms ON p.ID = ms.ID
      JOIN ATTENDING_DOCTOR ad ON ms.ID = ad.Doctor_ID
      LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
      GROUP BY p.ID, p.FirstName, p.LastName, ms.Salary
      ORDER BY "מדד רווחיות" DESC
      LIMIT 50;`,
  },
  available_beds: {
    key: "available_beds",
    label: "מיטות פנויות במחלקות (שאילתה 3)",
    desc: "תפוסת מחלקות - כמה מיטות תפוסות וכמה פנויות.",
    sql: `
      SELECT
        d.DepID AS "מחלקה",
        d.NumOfBeds AS "סך מיטות",
        COUNT(DISTINCT t.Patient_ID) AS "מיטות תפוסות",
        (d.NumOfBeds - COUNT(DISTINCT t.Patient_ID)) AS "מיטות פנויות"
      FROM DEPARTMENT d
      LEFT JOIN ATTENDING_DOCTOR ad ON d.DepID = ad.DepID
      LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
        AND t.Treatment_Date >= NOW() - INTERVAL '2 month'
      GROUP BY d.DepID, d.NumOfBeds
      ORDER BY "מיטות פנויות" DESC;`,
  },
  drug_revenue: {
    key: "drug_revenue",
    label: "הכנסות מתרופות בחצי שנה (שאילתה 5)",
    desc: "סך ההכנסות וכמות המכירות לכל תרופה בששת החודשים האחרונים.",
    sql: `
      SELECT
        m.M_Name AS "שם התרופה",
        COUNT(mg.M_ID) AS "כמות מתן",
        SUM(m.Price) AS "סך הכנסות"
      FROM MEDICATION m
      JOIN MEDICATIONS_GIVEN mg ON m.M_ID = mg.M_ID
      WHERE mg.Treatment_Date >= NOW() - INTERVAL '6 months'
      GROUP BY m.M_ID, m.M_Name
      ORDER BY "סך הכנסות" DESC;`,
    chart: { type: "bar", labelColumn: "שם התרופה", valueColumn: "סך הכנסות" },
  },
  elderly_risk: {
    key: "elderly_risk",
    label: "חולים מבוגרים בסיכון (שאילתה 8)",
    desc: "מטופלים מעל גיל 55 עם 2 טיפולים או יותר בחודשיים האחרונים.",
    sql: `
      SELECT
        p.FirstName AS "שם פרטי",
        p.LastName AS "שם משפחה",
        EXTRACT(YEAR FROM age(CURRENT_DATE, pat.BirthDate)) AS "גיל",
        COUNT(t.Treatment_Date) AS "טיפולים"
      FROM PERSON p
      JOIN PATIENT pat ON p.ID = pat.ID
      JOIN TREATMENT t ON pat.ID = t.Patient_ID
      WHERE pat.BirthDate <= CURRENT_DATE - INTERVAL '55 years'
        AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '2 month'
      GROUP BY p.ID, p.FirstName, p.LastName, pat.BirthDate
      HAVING COUNT(t.Treatment_Date) >= 2;`,
  },
  blood_type: {
    key: "blood_type",
    label: "התפלגות סוגי דם (שאילתה 7)",
    desc: "כמות המטופלים מכל סוג דם - לניהול מלאי מנות דם.",
    sql: `
      SELECT
        BloodType AS "סוג דם",
        COUNT(*) AS "מספר מטופלים"
      FROM PATIENT
      WHERE BloodType IS NOT NULL
      GROUP BY BloodType
      ORDER BY "מספר מטופלים" DESC;`,
    chart: { type: "bar", labelColumn: "סוג דם", valueColumn: "מספר מטופלים" },
  },
};

export function getReport(key: string): ReportDef {
  const r = REPORTS[key];
  if (!r) throw new Error(`Unknown report: ${key}`);
  return r;
}

export function reportList(): { key: string; label: string; desc: string }[] {
  return Object.values(REPORTS).map((r) => ({
    key: r.key,
    label: r.label,
    desc: r.desc,
  }));
}
