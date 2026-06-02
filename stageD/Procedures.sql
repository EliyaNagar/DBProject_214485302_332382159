-- בונוס לרופאים על פי ביצועים - פרוצדורה שמעדכנת את השכר של רופאים שעומדים ביעד טיפולים מסוים
CREATE OR REPLACE PROCEDURE apply_salary_bonus_by_performance(p_min_treatments INT, p_bonus_percent DECIMAL)
LANGUAGE plpgsql AS $$
DECLARE
    -- [אלמנט a] סמן מפורש השולף את כל הרופאים ואת כמות הטיפולים שביצעו
    cur_doctors CURSOR FOR 
        SELECT ad.Doctor_ID, ms.Salary, COUNT(t.Treatment_Date) as Total_Treatments
        FROM ATTENDING_DOCTOR ad
        JOIN MEDICAL_STAFF ms ON ad.Doctor_ID = ms.ID
        LEFT JOIN TREATMENT t ON ad.Doctor_ID = t.Doctor_ID
        GROUP BY ad.Doctor_ID, ms.Salary;
        
    -- [אלמנט g] רשומה שתחזיק את הנתונים בכל איטרציה של הלולאה
    v_doc_record RECORD;
    v_updated_count INT := 0;
BEGIN
    -- [אלמנט d] בדיקת תקינות קלט (הסתעפות)
    IF p_bonus_percent <= 0 OR p_bonus_percent > 100 THEN
        -- [אלמנט f] טיפול בשגיאות
        RAISE EXCEPTION 'אחוז הבונוס חייב להיות בין 1 ל-100. הוזן: %', p_bonus_percent
            USING ERRCODE = 'INVALID_PARAMETER_VALUE';
    END IF;

    -- [אלמנט e] פתיחת הסמן והרצת לולאה
    OPEN cur_doctors;
    LOOP
        FETCH cur_doctors INTO v_doc_record;
        EXIT WHEN NOT FOUND; -- תנאי יציאה
        
        -- [אלמנט d] בדיקה האם הרופא עומד ביעד הטיפולים
        IF v_doc_record.Total_Treatments >= p_min_treatments THEN
            -- [אלמנט c] פקודת DML: עדכון השכר של הרופא
            UPDATE MEDICAL_STAFF
            SET Salary = Salary * (1 + (p_bonus_percent / 100))
            WHERE ID = v_doc_record.Doctor_ID;
            
            v_updated_count := v_updated_count + 1;
        END IF;
    END LOOP;
    CLOSE cur_doctors;

    -- הדפסת הודעת מערכת (לא חובה, אבל מראה מקצועיות)
    RAISE NOTICE 'הבונוס הוחל בהצלחה על % רופאים מצטיינים.', v_updated_count;
END;
$$;




-- העברת רופא למחלקה אחרת - פרוצדורה שמעדכנת את המחלקה של רופא מסוים ומוחקת את המשמרות העתידיות שלו
CREATE OR REPLACE PROCEDURE reassign_doctor_department(p_doc_id INT, p_new_dep_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_doc_exists INT;
    v_dep_exists INT;
BEGIN
    -- בדיקה האם הרופא קיים בטבלת הרופאים המטפלים
    SELECT COUNT(*) INTO v_doc_exists FROM ATTENDING_DOCTOR WHERE Doctor_ID = p_doc_id;
    IF v_doc_exists = 0 THEN
        -- [אלמנט f] חריגה: מניעת עדכון לרופא רפאים
        RAISE EXCEPTION 'הרופא עם מזהה % לא קיים במערכת!', p_doc_id;
    END IF;

    -- בדיקה האם המחלקה החדשה קיימת
    SELECT COUNT(*) INTO v_dep_exists FROM DEPARTMENT WHERE DepID = p_new_dep_id;
    IF v_dep_exists = 0 THEN
        RAISE EXCEPTION 'מחלקה מספר % לא קיימת בבית החולים!', p_new_dep_id;
    END IF;

    -- [אלמנט c] פקודת DML 1: מחיקת משמרות עתידיות של הרופא מהיומן
    -- נמחק רק משמרות שעדיין לא התקיימו (ממחר והלאה)
    DELETE FROM SHIFT
    WHERE Staff_ID = p_doc_id AND Shift_Date > CURRENT_DATE;

    -- [אלמנט c] פקודת DML 2: עדכון שיוך המחלקה של הרופא
    UPDATE ATTENDING_DOCTOR 
    SET DepID = p_new_dep_id 
    WHERE Doctor_ID = p_doc_id;

    RAISE NOTICE 'הרופא % הועבר למחלקה % ויומן המשמרות העתידי שלו נוקה.', p_doc_id, p_new_dep_id;
END;
$$;