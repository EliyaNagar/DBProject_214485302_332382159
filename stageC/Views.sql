/*******************************************************************************
  Views.sql - שלב ג: מבטים על בסיס הנתונים המשולב
*******************************************************************************/

-- =============================================================================
-- מבט 1: מנקודת המבט של האגף שלנו - ניהול בית חולים
-- תיאור: סיכום פעילות רופאים - כמה טיפולים נתן כל רופא, אילו תרופות רשם,
--         ובאיזו מחלקה הוא עובד. שימושי לניהול כוח אדם ובקרת תקציב.
-- =============================================================================

CREATE OR REPLACE VIEW vw_doctor_activity AS
SELECT
    doc_p.ID                                    AS Doctor_ID,
    doc_p.FirstName || ' ' || doc_p.LastName    AS Doctor_Name,
    ad.DepID                                    AS Department_ID,
    t.Treatment_Date,
    pat_p.ID                                    AS Patient_ID,
    pat_p.FirstName || ' ' || pat_p.LastName    AS Patient_Name,
    pa.BloodType,
    m.M_Name                                    AS Medication_Name,
    m.Price                                     AS Medication_Price
FROM ATTENDING_DOCTOR ad
JOIN PERSON doc_p       ON ad.Doctor_ID = doc_p.ID
JOIN TREATMENT t        ON ad.Doctor_ID = t.Doctor_ID
JOIN PERSON pat_p       ON t.Patient_ID = pat_p.ID
JOIN PATIENT pa         ON t.Patient_ID = pa.ID
LEFT JOIN MEDICATIONS_GIVEN mg ON t.Patient_ID = mg.Patient_ID
    AND t.Doctor_ID = mg.Doctor_ID
    AND t.Treatment_Date = mg.Treatment_Date
LEFT JOIN MEDICATION m  ON mg.M_ID = m.M_ID;

-- -----------------------------------------------------------------------------
-- שאילתה 1 על מבט 1:
-- דירוג רופאים לפי מספר טיפולים - מי הכי עמוס 
-- -----------------------------------------------------------------------------
SELECT
    Doctor_ID,
    Doctor_Name,
    Department_ID,
    COUNT(*) AS Total_Treatments
FROM vw_doctor_activity
GROUP BY Doctor_ID, Doctor_Name, Department_ID
ORDER BY Total_Treatments DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- שאילתה 2 על מבט 1:
-- סך הכנסות מתרופות לכל מחלקה בחצי שנה האחרונה
-- -----------------------------------------------------------------------------
SELECT
    Department_ID,
    COUNT(DISTINCT Doctor_ID)   AS Num_Doctors,
    COUNT(*)                    AS Total_Treatments,
    SUM(Medication_Price)       AS Total_Drug_Revenue
FROM vw_doctor_activity
WHERE Treatment_Date >= NOW() - INTERVAL '6 months'
  AND Medication_Name IS NOT NULL
GROUP BY Department_ID
ORDER BY Total_Drug_Revenue DESC;


-- =============================================================================
-- מבט 2: מנקודת המבט של האגף של השותף - ניהול מרפאה קהילתית
-- תיאור: היסטוריה רפואית משולבת של חולים - ביקורים, מרשמים ואשפוזים
--         מהמערכת של השותף, מועשרים בסוג הדם ותאריך הלידה ממערכת בית החולים.
-- =============================================================================

CREATE OR REPLACE VIEW vw_patient_clinic_history AS
SELECT
    p.ID                                        AS Patient_ID,
    p.FirstName || ' ' || p.LastName            AS Patient_Name,
    pa.BloodType,
    pa.BirthDate,
    v.Visit_ID,
    v.Visit_Date,
    v.Diagnosis,
    s.First_Name || ' ' || s.Last_Name          AS Treating_Staff,
    s.Role                                      AS Staff_Role,
    rm.Medication_Name                          AS Prescribed_Medication,
    ia.Admission_Date,
    ia.Discharge_Date
FROM PERSON p
JOIN PATIENT pa                             ON p.ID = pa.ID
LEFT JOIN remote_partner.VISITS v           ON p.ID = v.Patient_ID
LEFT JOIN remote_partner.STAFF s            ON v.Employee_ID = s.Employee_ID
LEFT JOIN remote_partner.PRESCRIPTIONS rx   ON v.Visit_ID = rx.Visit_ID
LEFT JOIN remote_partner.MEDICATIONS rm     ON rx.Medication_ID = rm.Medication_ID
LEFT JOIN remote_partner.INPATIENT_ADMISSIONS ia ON p.ID = ia.Patient_ID;

-- -----------------------------------------------------------------------------
-- שאילתה 1 על מבט 2:
-- חולים עם הכי הרבה ביקורים במרפאה - זיהוי חולים כרוניים
-- -----------------------------------------------------------------------------
SELECT
    Patient_ID,
    Patient_Name,
    BloodType,
    COUNT(DISTINCT Visit_ID) AS Total_Visits
FROM vw_patient_clinic_history
WHERE Visit_ID IS NOT NULL
GROUP BY Patient_ID, Patient_Name, BloodType
ORDER BY Total_Visits DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- שאילתה 2 על מבט 2:
-- חולים שגם בוקרו וגם אושפזו - מעקב אחר חולים מורכבים
-- -----------------------------------------------------------------------------
SELECT
    Patient_ID,
    Patient_Name,
    BloodType,
    BirthDate,
    COUNT(DISTINCT Visit_ID)        AS Total_Visits,
    MIN(Admission_Date)             AS First_Admission,
    MAX(Discharge_Date)             AS Last_Discharge
FROM vw_patient_clinic_history
WHERE Visit_ID IS NOT NULL
  AND Admission_Date IS NOT NULL
GROUP BY Patient_ID, Patient_Name, BloodType, BirthDate
ORDER BY Total_Visits DESC
LIMIT 10;
