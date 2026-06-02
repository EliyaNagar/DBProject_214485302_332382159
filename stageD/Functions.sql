-- CURSOR - פונקציה לחישוב חשבונית מטופל בבית החולים
CREATE OR REPLACE FUNCTION calculate_patient_bill(p_patient_id INT)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_total_bill DECIMAL(10,2) := 0.00;
    v_patient_exists INT;
    v_treatment_count INT;
    
    -- [אלמנט a] הגדרת Cursor מפורש (Explicit Cursor) לשליפת מחירי התרופות של המטופל
    cur_medications CURSOR FOR 
        SELECT m.Price 
        FROM MEDICATIONS_GIVEN mg
        JOIN MEDICATION m ON mg.M_ID = m.M_ID
        WHERE mg.Patient_ID = p_patient_id;
        
    -- [אלמנט g] הגדרת משתנה מסוג רשומה (Record) לשימוש בתוך הלולאה
    v_med_row RECORD;
BEGIN
    -- [אלמנט a] שימוש בסמן מרומז (Implicit) לבדיקה האם המטופל קיים בטבלה
    SELECT COUNT(*) INTO v_patient_exists FROM PATIENT WHERE ID = p_patient_id;
    
    -- [אלמנט d] הסתעפות ותנאים (Branching)
    IF v_patient_exists = 0 THEN
        -- [אלמנט f] שימוש ב-Exception מותאם אישית למקרה קצה של חוסר נתונים
        RAISE EXCEPTION 'מטופל עם מזהה % לא נמצא במערכת בית החולים', p_patient_id
            USING ERRCODE = 'P0001';
    END IF;

    -- חישוב עלות בסיסית: סופרים כמה טיפולים עבר ומכפילים בעלות בדיקה קבועה (למשל 120 ש"ח)
    SELECT COUNT(*) INTO v_treatment_count FROM TREATMENT WHERE Patient_ID = p_patient_id;
    v_total_bill := v_total_bill + (v_treatment_count * 120.00);

    -- [אלמנט e] פתיחת הסמן המפורש וריצה בלולאה שורה-שורה
    OPEN cur_medications;
    LOOP
        -- שליפת השורה הנוכחית לתוך הרשומה
        FETCH cur_medications INTO v_med_row;
        
        -- תנאי יציאה מהלולאה כאשר נגמרו השורות בסמן
        EXIT WHEN NOT FOUND; 
        
        -- הוספת מחיר התרופה הנוכחית לסך הכל
        v_total_bill := v_total_bill + v_med_row.Price;
    END LOOP;
    
    -- סגירת הסמן לשחרור משאבי זיכרון בשרת
    CLOSE cur_medications;

    -- החזרת הסכום הסופי
    RETURN v_total_bill;

EXCEPTION
    -- [אלמנט f] תפיסת שגיאות כלליות כדי למנוע קריסה מוחלטת של ה-GUI
    WHEN OTHERS THEN
        RAISE NOTICE 'שגיאה פרוצדורלית בתהליך חישוב החשבונית: %', SQLERRM;
        RETURN 0.00;
END;
$$ LANGUAGE plpgsql;




-- REF CURSOR - פונקציה להחזרת רשימת הצוות במחלקה עם שכר מעל סכום מסוים
-- כדי לוודא שלא יחנק לנו הזיכרון בשרת, נשתמש ב-Ref Cursor שמאפשר שליפה דינמית של נתונים גדולים מבלי לטעון את כולם לזיכרון בבת אחת
CREATE OR REPLACE FUNCTION get_department_roster_cursor(p_dep_id INT, p_min_salary DECIMAL)
RETURNS REFCURSOR AS $$
DECLARE
    -- [אלמנט b] הגדרת משתנה מסוג Ref Cursor (מצביע דינמי לחילופי מידע יעילים)
    v_matching_staff_cursor REFCURSOR := 'dept_staff_result_cursor';
    v_dep_exists INT;
BEGIN
    -- [אלמנט a] סמן מרומז לבדיקת קיום המחלקה
    SELECT COUNT(*) INTO v_dep_exists FROM DEPARTMENT WHERE DepID = p_dep_id;
    
    -- [אלמנט d] הסתעפות לניהול לוגי של קלטים
    IF v_dep_exists = 0 THEN
        -- [אלמנט f] זריקת חריגה במידה והמנהל הקיש קוד מחלקה שגוי במסך
        RAISE EXCEPTION 'מחלקה מספר % אינה קיימת במאגר הנתונים המרכזי', p_dep_id
            USING ERRCODE = 'P0002';
    END IF;

    -- [אלמנט b] פתיחת ה-Ref Cursor עבור שאילתת השליפה המבוקשת
    -- השאילתה מחברת 3 טבלאות כדי להציג שם מלא במקום מזהים יבשים (דרישת GUI)
    OPEN v_matching_staff_cursor FOR 
        SELECT 
            p.ID AS Staff_ID, 
            p.FirstName || ' ' || p.LastName AS Staff_Name, 
            ms.Salary,
            ms.HireDate
        FROM ATTENDING_DOCTOR ad
        JOIN MEDICAL_STAFF ms ON ad.Doctor_ID = ms.ID
        JOIN PERSON p ON ms.ID = p.ID
        WHERE ad.DepID = p_dep_id AND ms.Salary >= p_min_salary;
        
    -- החזרת המצביע לתוכנית המזמנת (או למסך התוכנה)
    RETURN v_matching_staff_cursor;
END;
$$ LANGUAGE plpgsql;