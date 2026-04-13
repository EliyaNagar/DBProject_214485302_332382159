-- ============================================================
--  Stage C — Views
--  Project: Hospital Management System
--  IDs: 214485302, 332382159
-- ============================================================


-- ============================================================
--  VIEW 1: DoctorActivityView
--  אגף: המערכת שלנו (צוות רפואי וטיפולים)
--
--  תיאור:
--  המבט מציג סיכום פעילות לכל רופא מטפל במערכת.
--  לכל רופא מוצגים: שמו המלא, מזהה המחלקה שבה הוא משובץ,
--  שכרו, תאריך קליטתו למערכת, ומספר הטיפולים הכולל שביצע.
--  המבט משלב את הטבלאות PERSON, MEDICAL_STAFF, ATTENDING_DOCTOR
--  ו-TREATMENT כדי לתת תמונה מאוחדת של ביצועי הרופאים.
-- ============================================================

CREATE OR REPLACE VIEW DoctorActivityView AS
SELECT
    p.FirstName || ' ' || p.LastName  AS Doctor_Name,
    ad.DepID                           AS Department_ID,
    ms.Salary,
    ms.HireDate,
    COUNT(t.Treatment_Date)            AS Total_Treatments
FROM PERSON p
JOIN MEDICAL_STAFF ms    ON p.ID = ms.ID
JOIN ATTENDING_DOCTOR ad ON ms.ID = ad.Doctor_ID
LEFT JOIN TREATMENT t    ON ad.Doctor_ID = t.Doctor_ID
GROUP BY p.FirstName, p.LastName, ad.DepID, ms.Salary, ms.HireDate;

-- שליפת נתונים מהמבט (10 רשומות ראשונות)
SELECT * FROM DoctorActivityView LIMIT 10;


-- ------------------------------------------------------------
--  שאילתה 1.1 על DoctorActivityView
--
--  תיאור:
--  מציאת רופאים עם עומס טיפולים גבוה — רופאים שביצעו
--  יותר מ-10 טיפולים, ממוינים מהעמוס ביותר לפחות עמוס.
--  שאילתה זו שימושית למנהל בית החולים לצורך ניהול עומסים
--  וחלוקת משאבים בין המחלקות.
-- ------------------------------------------------------------

SELECT Doctor_Name, Total_Treatments, Department_ID
FROM DoctorActivityView
WHERE Total_Treatments > 10
ORDER BY Total_Treatments DESC;


-- ------------------------------------------------------------
--  שאילתה 1.2 על DoctorActivityView
--
--  תיאור:
--  סיכום מחלקתי — ממוצע שכר ומספר טיפולים כולל לפי מחלקה.
--  שאילתה זו מאפשרת להשוות בין מחלקות מבחינת עומס עבודה
--  ועלויות שכר, ומסייעת בקבלת החלטות תקציביות.
-- ------------------------------------------------------------

SELECT
    Department_ID,
    ROUND(AVG(Salary), 2)  AS Avg_Salary,
    SUM(Total_Treatments)  AS Total_Dept_Treatments
FROM DoctorActivityView
GROUP BY Department_ID
ORDER BY Total_Dept_Treatments DESC;


-- ============================================================
--  VIEW 2: PatientAdmissionView
--  אגף: המערכת שקיבלנו (אשפוזים וניהול חדרים)
--
--  תיאור:
--  המבט מציג תמונה מלאה של כל אשפוז בבית החולים.
--  לכל אשפוז מוצגים: שם החולה, תאריך לידתו, תאריכי כניסה
--  ויציאה, מספר ימי האשפוז, מספר המיטה והחדר, סוג החדר,
--  ושם המחלקה.
--  המבט משלב את הטבלאות PATIENTS, INPATIENT_ADMISSIONS,
--  BEDS, ROOMS ו-DEPARTMENTS.
-- ============================================================

CREATE OR REPLACE VIEW PatientAdmissionView AS
SELECT
    p.First_Name || ' ' || p.Last_Name       AS Patient_Name,
    p.Date_Of_Birth,
    ia.Admission_Date,
    ia.Discharge_Date,
    (ia.Discharge_Date - ia.Admission_Date)  AS Days_Hospitalized,
    b.Bed_Number,
    r.Room_Number,
    r.Room_Type,
    d.Department_Name
FROM PATIENTS p
JOIN INPATIENT_ADMISSIONS ia ON p.Patient_ID = ia.Patient_ID
JOIN BEDS b                  ON ia.Bed_ID    = b.Bed_ID
JOIN ROOMS r                 ON b.Room_ID    = r.Room_ID
JOIN DEPARTMENTS d           ON r.Department_ID = d.Department_ID;

-- שליפת נתונים מהמבט (10 רשומות ראשונות)
SELECT * FROM PatientAdmissionView LIMIT 10;


-- ------------------------------------------------------------
--  שאילתה 2.1 על PatientAdmissionView
--
--  תיאור:
--  זיהוי חולים שאושפזו לתקופה ממושכת — יותר מ-7 ימים.
--  אשפוזים ממושכים דורשים מעקב מיוחד ומשאבים נוספים,
--  ולכן חשוב למנהל המחלקה לדעת מי הם החולים הללו ובאיזו
--  מחלקה הם שוהים.
-- ------------------------------------------------------------

SELECT Patient_Name, Admission_Date, Days_Hospitalized, Department_Name
FROM PatientAdmissionView
WHERE Days_Hospitalized > 7
ORDER BY Days_Hospitalized DESC;


-- ------------------------------------------------------------
--  שאילתה 2.2 על PatientAdmissionView
--
--  תיאור:
--  סטטיסטיקת תפוסה לפי מחלקה — מספר האשפוזים וממוצע
--  ימי השהייה בכל מחלקה.
--  שאילתה זו מסייעת בניהול קיבולת בית החולים ובתכנון
--  הקצאת מיטות ומשאבי כוח אדם.
-- ------------------------------------------------------------

SELECT
    Department_Name,
    COUNT(*)                        AS Total_Admissions,
    ROUND(AVG(Days_Hospitalized), 1) AS Avg_Stay_Days
FROM PatientAdmissionView
GROUP BY Department_Name
ORDER BY Total_Admissions DESC;


-- ============================================================
--  VIEW 3: MedicationUsageView
--  אגף: משולב — שתי המערכות יחד
--
--  תיאור:
--  המבט המשולב מאחד נתוני תרופות משתי המערכות:
--  (1) תרופות שניתנו ישירות בטיפולים מהמערכת שלנו
--      (טבלאות MEDICATION ו-MEDICATIONS_GIVEN)
--  (2) תרופות שנרשמו במרשמים רפואיים מהמערכת שקיבלנו
--      (טבלאות MEDICATIONS ו-PRESCRIPTIONS)
--  לכל שורה מוצגים: שם התרופה, מספר הפעמים שנעשה בה
--  שימוש, והמקור (Treatment / Prescription).
--  מבט זה מאפשר לנהל את מלאי התרופות ולנתח דפוסי
--  שימוש בהן על פני כלל בית החולים.
-- ============================================================

CREATE OR REPLACE VIEW MedicationUsageView AS
-- תרופות מהמערכת שלנו (ניתנו בטיפולים)
SELECT
    m.M_Name              AS Medication_Name,
    COUNT(mg.M_ID)        AS Times_Used,
    'Treatment'           AS Source
FROM MEDICATION m
JOIN MEDICATIONS_GIVEN mg ON m.M_ID = mg.M_ID
GROUP BY m.M_Name

UNION ALL

-- תרופות מהמערכת שקיבלנו (נרשמו במרשמים)
SELECT
    med.Medication_Name,
    COUNT(pr.Prescription_ID) AS Times_Used,
    'Prescription'            AS Source
FROM MEDICATIONS med
JOIN PRESCRIPTIONS pr ON med.Medication_ID = pr.Medication_ID
GROUP BY med.Medication_Name;

-- שליפת נתונים מהמבט (10 רשומות ראשונות)
SELECT * FROM MedicationUsageView LIMIT 10;


-- ------------------------------------------------------------
--  שאילתה 3.1 על MedicationUsageView
--
--  תיאור:
--  10 התרופות הנפוצות ביותר בכלל בית החולים — מחובר
--  משתי המערכות יחד.
--  שאילתה זו שימושית לניהול מלאי ולהבטחת זמינות התרופות
--  הנדרשות ביותר.
-- ------------------------------------------------------------

SELECT Medication_Name, SUM(Times_Used) AS Total_Uses
FROM MedicationUsageView
GROUP BY Medication_Name
ORDER BY Total_Uses DESC
LIMIT 10;


-- ------------------------------------------------------------
--  שאילתה 3.2 על MedicationUsageView
--
--  תיאור:
--  השוואה בין שתי המערכות — כמה תרופות שונות נרשמו
--  וכמה פעמים סה"כ נעשה שימוש בתרופות בכל מקור.
--  שאילתה זו מדגימה את ההיקף היחסי של כל אגף מבחינת
--  צריכת תרופות, ומסייעת בהחלטות איחוד נהלים.
-- ------------------------------------------------------------

SELECT
    Source,
    COUNT(DISTINCT Medication_Name)  AS Unique_Medications,
    SUM(Times_Used)                  AS Total_Uses
FROM MedicationUsageView
GROUP BY Source;
