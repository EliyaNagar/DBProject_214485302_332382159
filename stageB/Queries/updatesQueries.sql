-- Update 1: בונוס ביצועים לרופאים
-- מעלה שכר ב-10% למי שביצע מעל 130 טיפולים בשנה האחרונה
UPDATE MEDICAL_STAFF
SET Salary = Salary * 1.10
WHERE ID IN (
    SELECT Doctor_ID 
    FROM TREATMENT 
    WHERE Treatment_Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY Doctor_ID 
    HAVING COUNT(*) > 130
);

-- Update 2: מעבר דירה משפחתי (Family Move)
-- עדכון כתובת לאיש צוות וכל מי שגר איתו באותה דירה
UPDATE PERSON
SET City = 'Haifa', -- לפה
    Street = 'Herzl', 
    HouseNumber = 10, 
    ApartmentNumber = 2
WHERE City = 'Tel Aviv' --מפה 
  AND Street = 'HaYarkon' 
  AND HouseNumber = 15 
  AND ApartmentNumber = 4;


-- Update 3: עדכון מחיר תרופות פופולריות
-- מעלה מחיר ב-5% לתרופות שניתנו מעל 100 פעמים
UPDATE MEDICATION
SET Price = Price * 1.05
WHERE M_ID IN (
    SELECT M_ID 
    FROM MEDICATIONS_GIVEN
    GROUP BY M_ID 
    HAVING COUNT(*) > 100
);