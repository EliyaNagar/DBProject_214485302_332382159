-- סוף חודש - תוכנית ראשית שמזמינה את הפונקציה והפרוצדורה שיצרנו
DO $$
DECLARE
    -- משתנים לתוכנית (תחליף את ה-ID במספר אמיתי שיש לך בטבלת PATIENT)
    v_target_patient INT := 328308725; 
    v_bill_amount DECIMAL(10,2);
BEGIN
    RAISE NOTICE '--- מתחיל תהליך סוף חודש מערכתי ---';

    -- 1. זימון הפונקציה: חישוב חוב למטופל
    RAISE NOTICE 'מחשב חובות עבור מטופל %...', v_target_patient;
    v_bill_amount := calculate_patient_bill(v_target_patient);
    RAISE NOTICE '>> החוב המעודכן שחושב הוא: % שקלים.', v_bill_amount;

    -- 2. זימון הפרוצדורה: חלוקת בונוסים של 10% לרופאים שביצעו לפחות 2 טיפולים
    RAISE NOTICE 'מפעיל חלוקת בונוסים שכר לרופאים מצטיינים...';
    CALL apply_salary_bonus_by_performance(2, 10.0);
    
    RAISE NOTICE '--- תהליך סוף חודש הסתיים בהצלחה ---';
END;
$$ LANGUAGE plpgsql;



-- הנהלת בית החולים מעבירה קופא למחלקה אחרת
DO $$
DECLARE
    -- נתונים לתהליך (תחליף למזהה רופא אמיתי אצלך ומזהה מחלקה)
    v_doctor_to_move INT := 123456789; 
    v_target_dept INT := 2; 
    
    -- משתנים לטיפול ב-Ref Cursor שהפונקציה תחזיר
    v_roster_cursor REFCURSOR;
    v_staff_record RECORD;
BEGIN
    RAISE NOTICE '--- מתחיל תהליך ניוד רופאים ועדכון מצבות ---';

    -- 1. זימון הפרוצדורה: העברת הרופא למחלקה החדשה (ומחיקת משמרותיו הישנות)
    RAISE NOTICE 'מעביר את רופא % למחלקה %...', v_doctor_to_move, v_target_dept;
    CALL reassign_doctor_department(v_doctor_to_move, v_target_dept);

    -- 2. זימון הפונקציה: קבלת מצביע (Ref Cursor) לדו"ח המחלקה המעודכן
    RAISE NOTICE 'מושך דו"ח צוות רפואי עבור מחלקה %...', v_target_dept;
    v_roster_cursor := get_department_roster_cursor(v_target_dept, 0.00);

    -- מכיוון שהפונקציה החזירה סמן, התוכנית הראשית צריכה לפתוח אותו ולרוץ עליו כדי להדפיס
    RAISE NOTICE '>> רשימת הצוות המעודכנת במחלקה:';
    LOOP
        FETCH v_roster_cursor INTO v_staff_record;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '   שם עובד: % | שכר נוכחי: %', v_staff_record.Staff_Name, v_staff_record.Salary;
    END LOOP;
    
    -- סגירת המצביע
    CLOSE v_roster_cursor;

    RAISE NOTICE '--- תהליך הארגון הסתיים בהצלחה ---';
END;
$$ LANGUAGE plpgsql;