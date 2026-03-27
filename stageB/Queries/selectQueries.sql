/*******************************************************************************
  Queries.sql - פרויקט ניהול בית חולים
*******************************************************************************/

-- =============================================================================
-- SECTION 1: MEDICAL STAFF MANAGEMENT (ניהול צוות רפואי)
-- =============================================================================

-- Query 1: Doctor Efficiency Ranking (דירוג כלכליות רופאים)
-- מסך: דו"ח רווחיות כוח אדם
SELECT 
    p.FirstName || ' ' || p.LastName as Doctor_Name,
    COUNT(t.Treatment_Date) as Total_Treatments,
    ms.Salary,
    -- חישוב מדד רווחיות: כמות טיפולים חלקי שכר
    (NULLIF(ms.Salary, 0) / COUNT(t.Treatment_Date)) as Profitability_Index
FROM PERSON p
JOIN MEDICAL_STAFF ms ON p.ID = ms.ID
JOIN ATTENDING_DOCTOR ad ON ms.ID = ad.Doctor_ID
LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
GROUP BY p.ID, p.FirstName, p.LastName, ms.Salary
ORDER BY Profitability_Index DESC
LIMIT 50;

--------------------------------------------------------------------------------

-- Query 2: Local On-Call Doctors (מציאת כוננים מקומיים)
-- מסך: שיבוץ כוננות לפי קרבה גאוגרפית
SELECT p_staff.FirstName, p_staff.LastName, p_staff.City
FROM PERSON p_staff
WHERE EXISTS (
    SELECT 1 FROM TREATMENT t
    JOIN PERSON p_pat ON t.Patient_ID = p_pat.ID
    WHERE t.Doctor_ID = p_staff.ID
    AND p_pat.City = p_staff.City
    AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '1 day'
);

--------------------------------------------------------------------------------

-- Query 6: Nurse Economic Index (מדד יעילות אחיות)
-- מסך: ניתוח עומס עבודה מול שכר

SELECT 
    p.FirstName || ' ' || p.LastName as Staff_Name,
    COUNT(s.Shift_Date) as Total_Shifts,
    ms.Salary,
    ((COUNT(s.Shift_Date) / NULLIF(ms.Salary, 0))*1000000) as Efficiency_Score
FROM PERSON p
JOIN MEDICAL_STAFF ms ON p.ID = ms.ID
LEFT JOIN SHIFT s ON ms.ID = s.Staff_ID
GROUP BY p.ID, p.FirstName, p.LastName, ms.Salary
ORDER BY Efficiency_Score DESC
LIMIT 50;

--------------------------------------------------------------------------------

-- =============================================================================
-- SECTION 2: OPERATIONAL LOADS (עומסים ותפעול)
-- =============================================================================

-- Query 3: Available Beds with Staffing Check (מיטות פנויות במחלקות מאוישות)
-- מסך: ניהול תפוסת מחלקות בזמן אמת

SELECT 
    d.DepID,
    d.NumOfBeds as Total_Capacity,
    -- ספירת חולים ייחודיים שתפסו מיטה ב-24 השעות האחרונות
    COUNT(DISTINCT t.Patient_ID) as Occupied_Beds,
    -- חישוב המיטות שנותרו פנויות
    (d.NumOfBeds - COUNT(DISTINCT t.Patient_ID)) as Available_Beds
FROM DEPARTMENT d
-- חיבור למחלקות דרך הרופאים המועסקים בהן
LEFT JOIN ATTENDING_DOCTOR ad ON d.DepID = ad.DepID
-- חיבור לטיפולים שבוצעו על ידי אותם רופאים
LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID 
    AND t.Treatment_Date >= NOW() - INTERVAL '1 week' -- הגדרת "כרגע"
GROUP BY d.DepID, d.NumOfBeds
ORDER BY Available_Beds DESC;
--------------------------------------------------------------------------------

-- Query 5: Daily Revenue Report (דו"ח הכנסות חצי שנתי מתרופות)
-- מסך: בקרה תקציבית 
SELECT 
    m.M_Name,
    COUNT(mg.M_ID) as Times_Sold,
    SUM(m.Price) as Total_Revenue
FROM MEDICATION m
JOIN MEDICATIONS_GIVEN mg ON m.M_ID = mg.M_ID
WHERE mg.Treatment_Date >= NOW() - INTERVAL '6 months'
GROUP BY m.M_ID, m.M_Name
ORDER BY Total_Revenue DESC;

-- less effctive
SELECT 
    m.M_Name,
    -- תת-שאילתה 1: ספירת כמות המכירות לכל תרופה בנפרד
    (SELECT COUNT(*) 
     FROM MEDICATIONS_GIVEN mg 
     WHERE mg.M_ID = m.M_ID 
     AND mg.Treatment_Date >= NOW() - INTERVAL '6 months'
    ) as Times_Sold,
    -- תת-שאילתה 2: חישוב סך ההכנסות לכל תרופה בנפרד
    (SELECT SUM(m2.Price) 
     FROM MEDICATIONS_GIVEN mg2
     JOIN MEDICATION m2 ON mg2.M_ID = m2.M_ID
     WHERE mg2.M_ID = m.M_ID 
     AND mg2.Treatment_Date >= NOW() - INTERVAL '6 months'
    ) as Total_Revenue
FROM MEDICATION m
-- שימוש בתת-שאילתה חוזרת בתוך ה-ORDER BY (בזבוז משאבים)
ORDER BY (
    SELECT SUM(m3.Price) 
    FROM MEDICATIONS_GIVEN mg3
    JOIN MEDICATION m3 ON mg3.M_ID = m3.M_ID
    WHERE mg3.M_ID = m.M_ID 
    AND mg3.Treatment_Date >= NOW() - INTERVAL '6 months'
) DESC;

--------------------------------------------------------------------------------

-- =============================================================================
-- SECTION 3: EPIDEMIOLOGICAL & CLINICAL (אפידמיולוגיה ובקרה)
-- =============================================================================

-- Query 4: Monthly Outbreak Alert (התראת עלייה בתחלואה)
-- מסך: דאשבורד אפידמיולוגי
-- האם בשנה ההאחרונה היה חודש שבו התחלואה הייתה מעל הממוצע ואם היו כמה נבחר את ההכי גדול ממנו 

SELECT City, Monthly_Count, Yearly_Avg_Integer
FROM (
    SELECT 
        City, 
        Monthly_Count, 
        CAST(Yearly_Avg AS INT) as Yearly_Avg_Integer,
        -- דירוג החודשים בתוך כל עיר מהגבוה לנמוך
        ROW_NUMBER() OVER(PARTITION BY City ORDER BY Monthly_Count DESC) as rank_per_city
    FROM (
        SELECT 
            p.City,
            COUNT(*) OVER(PARTITION BY p.City, EXTRACT(MONTH FROM t.Treatment_Date)) as Monthly_Count,
            COUNT(*) OVER(PARTITION BY p.City) / 12.0 as Yearly_Avg
        FROM PERSON p
        JOIN TREATMENT t ON p.ID = t.Patient_ID
    ) Stats
    WHERE Monthly_Count > Yearly_Avg
) RankedStats
WHERE rank_per_city = 1 -- שומר רק את חודש השיא לכל עיר
ORDER BY Monthly_Count DESC;

-- less effctive
SELECT DISTINCT
    p.City,
    -- תת-שאילתה 1: ספירת הטיפולים לחודש הספציפי בעיר הספציפית
    (SELECT COUNT(*) 
     FROM TREATMENT t2 
     JOIN PERSON p2 ON t2.Patient_ID = p2.ID
     WHERE p2.City = p.City 
     AND EXTRACT(MONTH FROM t2.Treatment_Date) = EXTRACT(MONTH FROM t.Treatment_Date)
    ) as Monthly_Count,
    -- תת-שאילתה 2: חישוב הממוצע השנתי לאותה עיר
    (SELECT COUNT(*) 
     FROM TREATMENT t3 
     JOIN PERSON p3 ON t3.Patient_ID = p3.ID
     WHERE p3.City = p.City) / 12 as Yearly_Avg_Integer
FROM PERSON p
JOIN TREATMENT t ON p.ID = t.Patient_ID
WHERE 
    -- פילטר 1: רק חודשים שמעל הממוצע (חישוב כפול!)
    (SELECT COUNT(*) FROM TREATMENT t2 JOIN PERSON p2 ON t2.Patient_ID = p2.ID
     WHERE p2.City = p.City AND EXTRACT(MONTH FROM t2.Treatment_Date) = EXTRACT(MONTH FROM t.Treatment_Date)) 
     > 
    (SELECT COUNT(*) FROM TREATMENT t3 JOIN PERSON p3 ON t3.Patient_ID = p3.ID
     WHERE p3.City = p.City) / 12.0
    AND
    -- פילטר 2: מציאת חודש השיא (במקום ROW_NUMBER) - מסורבל מאוד!
    (SELECT COUNT(*) FROM TREATMENT t2 JOIN PERSON p2 ON t2.Patient_ID = p2.ID
     WHERE p2.City = p.City AND EXTRACT(MONTH FROM t2.Treatment_Date) = EXTRACT(MONTH FROM t.Treatment_Date)) 
     = (
        SELECT MAX(month_total) FROM (
            SELECT COUNT(*) as month_total
            FROM TREATMENT t4 JOIN PERSON p4 ON t4.Patient_ID = p4.ID
            WHERE p4.City = p.City
            GROUP BY EXTRACT(MONTH FROM t4.Treatment_Date)
        ) InnerSub
    )
ORDER BY Monthly_Count DESC;

--------------------------------------------------------------------------------

-- Query 7: Most Common Blood Type per Department (סוג דם שכיח למחלקה)
-- מסך: ניהול מלאי מנות דם
SELECT 
    BloodType, 
    COUNT(*) as Patient_Count
FROM PATIENT
WHERE BloodType IS NOT NULL
GROUP BY BloodType
ORDER BY Patient_Count DESC;

-- less effective
SELECT DISTINCT 
    p1.BloodType,
    -- תת-שאילתה שנסרקת עבור כל סוג דם בנפרד כדי לספור חולים
    (SELECT COUNT(*) 
     FROM PATIENT p2 
     WHERE p2.BloodType = p1.BloodType) as Patient_Count
FROM PATIENT p1
WHERE p1.BloodType IS NOT NULL
-- שימוש בתת-שאילתה נוספת בתוך ה-ORDER BY (בזבוז משאבים מוחלט)
ORDER BY (SELECT COUNT(*) 
          FROM PATIENT p3 
          WHERE p3.BloodType = p1.BloodType) DESC;

--------------------------------------------------------------------------------

-- Query 8: High-Risk Elderly Patients Audit (חולים בסיכון גבוה)
-- מסך: מעקב חולים מעל גיל 60 עם ריבוי טיפולים
SELECT 
    p.FirstName, 
    p.LastName, 
    EXTRACT(YEAR FROM age(CURRENT_DATE, pat.BirthDate)) as Age,
    COUNT(t.Treatment_Date) as Monthly_Treatments
FROM PERSON p
JOIN PATIENT pat ON p.ID = pat.ID
JOIN TREATMENT t ON pat.ID = t.Patient_ID
WHERE pat.BirthDate <= CURRENT_DATE - INTERVAL '55 years'
  AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY p.ID, p.FirstName, p.LastName, pat.BirthDate
HAVING COUNT(t.Treatment_Date) >= 2;

--lass effective 
SELECT 
    p.FirstName, 
    p.LastName,
    -- תת-שאילתה לחישוב הגיל עבור כל שורה ושורה בנפרד
    (SELECT EXTRACT(YEAR FROM age(CURRENT_DATE, pat.BirthDate)) 
     FROM PATIENT pat 
     WHERE pat.ID = p.ID) as Age,
    -- תת-שאילתה לספירת טיפולים חודשיים עבור כל שורה בנפרד
    (SELECT COUNT(*) 
     FROM TREATMENT t 
     WHERE t.Patient_ID = p.ID 
     AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '1 month') as Monthly_Treatments
FROM PERSON p
WHERE 
    -- סינון גיל באמצעות תת-שאילתה נוספת
    (SELECT BirthDate FROM PATIENT pat WHERE pat.ID = p.ID) <= CURRENT_DATE - INTERVAL '55 years'
    AND 
    -- סינון כמות טיפולים באמצעות תת-שאילתה חוזרת
    (SELECT COUNT(*) FROM TREATMENT t 
     WHERE t.Patient_ID = p.ID 
     AND t.Treatment_Date >= CURRENT_DATE - INTERVAL '1 month') >= 2;