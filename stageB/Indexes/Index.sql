/*******************************************************************************
  Index.sql - יצירת אינדקסים לשיפור ביצועי שאילתות

  3 אינדקסים על עמודות שנסרקות תכופות בשאילתות SELECT, UPDATE ו-DELETE.
  עבור כל אינדקס: EXPLAIN ANALYZE לפני ואחרי היצירה.
*******************************************************************************/


-- ============================================================
-- INDEX 1: idx_treatment_date
-- טבלה: TREATMENT | עמודה: Treatment_Date
-- מוטיבציה: רוב השאילתות מסננות לפי טווח תאריכים על TREATMENT.
--            ללא אינדקס - נדרש Sequential Scan על 20,000 שורות.
-- ============================================================

-- לפני האינדקס - Seq Scan צפוי, זמן גבוה יותר:
EXPLAIN ANALYZE
SELECT
    p.FirstName,
    p.LastName,
    EXTRACT(YEAR FROM age(CURRENT_DATE, pat.BirthDate)) AS Age,
    COUNT(t.Treatment_Date) AS Monthly_Treatments
FROM PERSON p
JOIN PATIENT pat ON p.ID = pat.ID
JOIN TREATMENT t ON pat.ID = t.Patient_ID
WHERE pat.BirthDate <= CURRENT_DATE - INTERVAL '55 years'
  AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '2 months'
GROUP BY p.ID, p.FirstName, p.LastName, pat.BirthDate
HAVING COUNT(t.Treatment_Date) >= 2;

-- יצירת אינדקס 1
CREATE INDEX idx_treatment_date ON TREATMENT(Treatment_Date);

-- אחרי האינדקס - Index Range Scan צפוי, זמן נמוך יותר:
EXPLAIN ANALYZE
SELECT
    p.FirstName,
    p.LastName,
    EXTRACT(YEAR FROM age(CURRENT_DATE, pat.BirthDate)) AS Age,
    COUNT(t.Treatment_Date) AS Monthly_Treatments
FROM PERSON p
JOIN PATIENT pat ON p.ID = pat.ID
JOIN TREATMENT t ON pat.ID = t.Patient_ID
WHERE pat.BirthDate <= CURRENT_DATE - INTERVAL '55 years'
  AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '2 months'
GROUP BY p.ID, p.FirstName, p.LastName, pat.BirthDate
HAVING COUNT(t.Treatment_Date) >= 2;

/*
  הסבר תוצאות INDEX 1:
  לפני:  Seq Scan on treatment (cost=... rows=20000 ...)
          -> הסורק כל שורה בטבלה, סינון ב-Filter לאחר קריאה.
  אחרי:  Index Range Scan using idx_treatment_date on treatment
          -> קופץ ישירות לטווח התאריכים, קורא רק ~1,000 שורות רלוונטיות.
  שיפור: ירידה דרסטית בזמן ריצה כשרק ~5% מהשורות עוברות את תנאי התאריך.
*/


-- ============================================================
-- INDEX 2: idx_treatment_doctor_id
-- טבלה: TREATMENT | עמודה: Doctor_ID
-- מוטיבציה: שאילתות GROUP BY Doctor_ID ו-UPDATE בונוסים נסרקות
--            לפי Doctor_ID על טבלת TREATMENT. ללא אינדקס - Hash Aggregate
--            דורש טעינת כל הטבלה לזיכרון.
-- ============================================================

-- לפני האינדקס:
EXPLAIN ANALYZE
SELECT
    p.FirstName || ' ' || p.LastName AS Doctor_Name,
    COUNT(t.Treatment_Date)          AS Total_Treatments,
    ms.Salary,
    (NULLIF(ms.Salary, 0) / COUNT(t.Treatment_Date)) AS Profitability_Index
FROM PERSON p
JOIN MEDICAL_STAFF ms       ON p.ID = ms.ID
JOIN ATTENDING_DOCTOR ad    ON ms.ID = ad.Doctor_ID
LEFT JOIN TREATMENT t       ON ad.Doctor_ID = t.Doctor_ID
GROUP BY p.ID, p.FirstName, p.LastName, ms.Salary
ORDER BY Profitability_Index DESC
LIMIT 50;

-- יצירת אינדקס 2
CREATE INDEX idx_treatment_doctor_id ON TREATMENT(Doctor_ID);

-- אחרי האינדקס:
EXPLAIN ANALYZE
SELECT
    p.FirstName || ' ' || p.LastName AS Doctor_Name,
    COUNT(t.Treatment_Date)          AS Total_Treatments,
    ms.Salary,
    (NULLIF(ms.Salary, 0) / COUNT(t.Treatment_Date)) AS Profitability_Index
FROM PERSON p
JOIN MEDICAL_STAFF ms       ON p.ID = ms.ID
JOIN ATTENDING_DOCTOR ad    ON ms.ID = ad.Doctor_ID
LEFT JOIN TREATMENT t       ON ad.Doctor_ID = t.Doctor_ID
GROUP BY p.ID, p.FirstName, p.LastName, ms.Salary
ORDER BY Profitability_Index DESC
LIMIT 50;

/*
  הסבר תוצאות INDEX 2:
  לפני:  Hash Join + Seq Scan on treatment
          -> הבניית Hash Table על כל הטיפולים לצורך Join עם ATTENDING_DOCTOR.
  אחרי:  Index Scan using idx_treatment_doctor_id on treatment
          -> ה-JOIN מתבצע ישירות דרך האינדקס לפי Doctor_ID,
             ללא בניית Hash Table בזיכרון.
  שיפור: משמעותי כשמספר הרופאים קטן (500) לעומת הטיפולים (20,000).
*/


-- ============================================================
-- INDEX 3: idx_medications_given_mid_date  (COMPOSITE INDEX)
-- טבלה: MEDICATIONS_GIVEN | עמודות: M_ID, Treatment_Date
-- מוטיבציה: שאילתת הכנסות (Query 5) ושאילתת מחיקה (DELETE) מסננות
--            גם לפי M_ID וגם לפי Treatment_Date בו זמנית.
--            אינדקס מורכב מכסה את שתי העמודות במעבר אחד (Index Only Scan).
-- ============================================================

-- לפני האינדקס:
EXPLAIN ANALYZE
SELECT
    m.M_Name,
    COUNT(mg.M_ID)   AS Times_Sold,
    SUM(m.Price)     AS Total_Revenue
FROM MEDICATION m
JOIN MEDICATIONS_GIVEN mg ON m.M_ID = mg.M_ID
WHERE mg.Treatment_Date >= NOW() - INTERVAL '6 months'
GROUP BY m.M_ID, m.M_Name
ORDER BY Total_Revenue DESC;

-- יצירת אינדקס 3 (מורכב)
CREATE INDEX idx_medications_given_mid_date ON MEDICATIONS_GIVEN(M_ID, Treatment_Date);

-- אחרי האינדקס:
EXPLAIN ANALYZE
SELECT
    m.M_Name,
    COUNT(mg.M_ID)   AS Times_Sold,
    SUM(m.Price)     AS Total_Revenue
FROM MEDICATION m
JOIN MEDICATIONS_GIVEN mg ON m.M_ID = mg.M_ID
WHERE mg.Treatment_Date >= NOW() - INTERVAL '6 months'
GROUP BY m.M_ID, m.M_Name
ORDER BY Total_Revenue DESC;

/*
  הסבר תוצאות INDEX 3:
  לפני:  Seq Scan on medications_given + Hash Join
          -> סריקה של כל 500 רשומות MEDICATIONS_GIVEN ואז Filter על תאריך.
  אחרי:  Index Only Scan using idx_medications_given_mid_date
          -> מנוע ה-SQL קורא רק את האינדקס (ללא גישה לטבלה עצמה!).
             הצמד M_ID + Treatment_Date שניהם בתוך האינדקס,
             כך שניתן לחשב COUNT ולסנן לפי תאריך ישירות מהאינדקס.
  שיפור: Index Only Scan הוא המהיר ביותר האפשרי - אפס גישות לטבלה.
*/
