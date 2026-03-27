-- שלב א: מציאת ה-IDs של התרופות שניתנו פחות מ-20 פעמים
WITH LowUsageMeds AS (
    SELECT m_id
    FROM MEDICATION
    WHERE m_id NOT IN (
        SELECT m_id 
        FROM MEDICATIONS_GIVEN 
        GROUP BY m_id 
        HAVING COUNT(*) >= 68
    )
)
-- שלב ב: מחיקת הרישומים של התרופות האלו מטבלת הטיפולים (כדי לשחרר את המפתח הזר)
DELETE FROM MEDICATIONS_GIVEN
WHERE m_id IN (SELECT m_id FROM LowUsageMeds);

-- שלב ג: עכשיו אפשר למחוק את התרופות עצמן בביטחון
DELETE FROM MEDICATION
WHERE m_id NOT IN (
    SELECT m_id 
    FROM MEDICATIONS_GIVEN 
    GROUP BY m_id 
    HAVING COUNT(*) >= 68
);
------------------------------------------------------------------------------------------------


-- פיטורי איש צוות עם ID מסוים (למשל 123456789)
-- שלב 1: מחיקה מטבלת המשמרות (staff_id בתרשים)
DELETE FROM SHIFT 
WHERE staff_id = 21334321;
-- שלב 2: מחיקה מטבלת התפקיד (בתרשים מופיע כ-ID)
DELETE FROM ATTENDING_DOCTOR 
WHERE doctor_id = 21334321;
-- שלב 3: מחיקה מטבלת הצוות הרפואי
DELETE FROM MEDICAL_STAFF 
WHERE id = 21334321;



-- מחיקת חולים שמעולם לא עברו טיפול
DELETE FROM PATIENT p
WHERE NOT EXISTS (
    SELECT 1 
    FROM TREATMENT t 
    WHERE t.Patient_ID = p.ID
);