-- 1. טיפולים מהמערכת שלך (אליה)
SELECT 
    p.ID AS Patient_ID, 
    p.FirstName || ' ' || p.LastName AS Patient_Name, 
    pa.BloodType AS Blood_Type, -- משיכת סוג הדם מהמערכת שלך
    t.Treatment_Date::timestamp AS Event_Date, 
    'טיפול מקומי' AS Event_Type,
    
    -- פרטי הרופא המטפל (מקומי)
    t.Doctor_ID AS Doctor_ID,
    doc_p.FirstName || ' ' || doc_p.LastName AS Doctor_Name,
    
    -- טיפול ותרופה (מקומי)
    m.M_Name AS Medication_Name,
    'אין אבחנה' AS Medical_Notes
    
FROM PERSON p
JOIN PATIENT pa ON p.ID = pa.ID -- חיבור לטבלת החולה המקומית
JOIN TREATMENT t ON p.ID = t.Patient_ID
-- משיכת פרטי הרופא מתוך טבלת PERSON
LEFT JOIN PERSON doc_p ON t.Doctor_ID = doc_p.ID 
-- משיכת התרופות
LEFT JOIN MEDICATIONS_GIVEN mg ON t.Patient_ID = mg.Patient_ID 
    AND t.Doctor_ID = mg.Doctor_ID AND t.Treatment_Date = mg.Treatment_Date
LEFT JOIN MEDICATION m ON mg.M_ID = m.M_ID
WHERE p.ID = 328308725

UNION ALL

-- 2. ביקורים מהמערכת של החבר
SELECT 
    p.ID AS Patient_ID, 
    p.FirstName || ' ' || p.LastName AS Patient_Name, 
    pa.BloodType AS Blood_Type, -- העשרת הנתונים של החבר עם סוג הדם שלך
    v.Visit_Date::timestamp AS Event_Date, 
    'ביקור שותף' AS Event_Type,
    
    -- פרטי הרופא המטפל (שותף)
    v.Employee_ID AS Doctor_ID,
    s.First_Name || ' ' || s.Last_Name AS Doctor_Name,
    
    -- טיפול ותרופה (שותף)
    rm.Medication_Name AS Medication_Name,
    v.Diagnosis AS Medical_Notes
    
FROM PERSON p
JOIN PATIENT pa ON p.ID = pa.ID -- חיבור לטבלת החולה המקומית
JOIN remote_partner.VISITS v ON p.ID = v.Patient_ID
-- משיכת פרטי הרופא מקומית אצל השותף
LEFT JOIN remote_partner.STAFF s ON v.Employee_ID = s.Employee_ID
-- משיכת התרופות מקומית אצל השותף
LEFT JOIN remote_partner.PRESCRIPTIONS rx ON v.Visit_ID = rx.Visit_ID
LEFT JOIN remote_partner.MEDICATIONS rm ON rx.Medication_ID = rm.Medication_ID
WHERE p.ID = 328308725

UNION ALL

-- 3. אשפוזים מהמערכת של החבר
SELECT 
    p.ID AS Patient_ID, 
    p.FirstName || ' ' || p.LastName AS Patient_Name, 
    pa.BloodType AS Blood_Type, -- העשרת הנתונים גם באשפוזים
    ia.Admission_Date::timestamp AS Event_Date, 
    'אשפוז שותף' AS Event_Type,
    
    -- פרטי הרופא
    NULL::INT AS Doctor_ID,
    NULL AS Doctor_Name,
    
    -- טיפול ותרופה
    NULL AS Medication_Name,
    'שחרור מתוכנן: ' || ia.Discharge_Date AS Medical_Notes
    
FROM PERSON p
JOIN PATIENT pa ON p.ID = pa.ID -- חיבור לטבלת החולה המקומית
JOIN remote_partner.INPATIENT_ADMISSIONS ia ON p.ID = ia.Patient_ID
WHERE p.ID = 328308725

ORDER BY Event_Date DESC;