export interface DashboardKpis {
  patients: number;
  staff: number;
  departments: number;
  treatments30d: number;
  totalBeds: number;
  occupiedBeds: number;
  occupancyPct: number;
}

// All KPIs in a single round trip. Column order is consumed positionally by
// parseKpis, so do not reorder without updating parseKpis.
export const DASHBOARD_KPI_SQL = `
  SELECT
    (SELECT COUNT(*) FROM PATIENT)                                            AS patients,
    (SELECT COUNT(*) FROM MEDICAL_STAFF)                                      AS staff,
    (SELECT COUNT(*) FROM DEPARTMENT)                                         AS departments,
    (SELECT COUNT(*) FROM TREATMENT
       WHERE Treatment_Date >= NOW() - INTERVAL '30 days')                    AS treatments_30d,
    (SELECT COALESCE(SUM(NumOfBeds), 0) FROM DEPARTMENT)                      AS total_beds,
    (SELECT COUNT(DISTINCT Patient_ID) FROM TREATMENT
       WHERE Treatment_Date >= NOW() - INTERVAL '2 month')                    AS occupied_beds
`;

// Treatments per department (label + count) for the dashboard bar chart.
export const TREATMENTS_BY_DEPT_SQL = `
  SELECT
    'מחלקה ' || d.DepID            AS "מחלקה",
    COUNT(t.Treatment_Date)        AS "טיפולים"
  FROM DEPARTMENT d
  LEFT JOIN ATTENDING_DOCTOR ad ON d.DepID = ad.DepID
  LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
  GROUP BY d.DepID
  ORDER BY d.DepID
`;

/**
 * Maps a positional KPI row (see DASHBOARD_KPI_SQL) to a typed object.
 * Expects an array-shaped row (runSelect uses rowMode: "array").
 *
 * Note: occupancy here is a hospital-wide proxy — distinct patients treated in
 * the last 2 months over total physical beds — so it intentionally differs from
 * the per-department occupancy in reports.ts and is clamped to 100%.
 */
export function parseKpis(row: unknown[]): DashboardKpis {
  const n = (v: unknown) => Number(v) || 0;
  const patients = n(row[0]);
  const staff = n(row[1]);
  const departments = n(row[2]);
  const treatments30d = n(row[3]);
  const totalBeds = n(row[4]);
  const occupiedBeds = n(row[5]);
  const occupancyPct =
    totalBeds > 0 ? Math.min(100, Math.round((occupiedBeds / totalBeds) * 100)) : 0;
  return { patients, staff, departments, treatments30d, totalBeds, occupiedBeds, occupancyPct };
}
