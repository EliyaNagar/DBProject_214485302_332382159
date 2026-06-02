-- TRIGGERS - יצירת טריגר לתיעוד שינויים בשכר של הצוות הרפואי
-- הערה: טבלת SALARY_AUDIT נוצרת ב-AlterTable.sql - יש להריץ אותו תחילה

-- הפונקציה שמופעלת על ידי הטריגר
CREATE OR REPLACE FUNCTION log_salary_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- [אלמנט d] הסתעפות: נבדוק אם השכר *באמת* השתנה (ולא סתם עדכנו כתובת)
    -- NEW מייצג את הנתונים החדשים שניסו להכניס, OLD את הנתונים לפני העדכון
    IF OLD.Salary IS DISTINCT FROM NEW.Salary THEN
        -- [אלמנט c] הכנסת התיעוד לטבלת המעקב
        INSERT INTO SALARY_AUDIT (Staff_ID, Old_Salary, New_Salary)
        VALUES (OLD.ID, OLD.Salary, NEW.Salary);
    END IF;
    
    -- חובה להחזיר NEW כדי שהעדכון המקורי ימשיך כרגיל
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. חיבור הטריגר לטבלה (מופעל *אחרי* העדכון)
CREATE TRIGGER trigger_audit_salary
AFTER UPDATE ON MEDICAL_STAFF
FOR EACH ROW
EXECUTE FUNCTION log_salary_changes();




-- טריגר למניעת שיבוץ כפול של משמרות לאותו עובד באותו יום
-- 1. הפונקציה שמופעלת על ידי הטריגר
CREATE OR REPLACE FUNCTION prevent_double_shift()
RETURNS TRIGGER AS $$
DECLARE
    v_shift_exists INT;
BEGIN
    -- בדיקה האם כבר קיימת משמרת לאותו עובד באותו תאריך
    SELECT COUNT(*) INTO v_shift_exists
    FROM SHIFT
    WHERE Staff_ID = NEW.Staff_ID AND Shift_Date = NEW.Shift_Date;

    -- [אלמנט d] הסתעפות לבדיקת התוצאה
    IF v_shift_exists > 0 THEN
        -- [אלמנט f] שימוש ב-Exception כדי לעצור את ה-INSERT/UPDATE
        RAISE EXCEPTION 'שגיאת שיבוץ: לאיש הצוות % כבר קיימת משמרת בתאריך %', NEW.Staff_ID, NEW.Shift_Date
            USING ERRCODE = 'P0003';
    END IF;

    -- אם הכל בסדר, תאשר לשורה החדשה להיכנס לטבלה
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. חיבור הטריגר לטבלה (מופעל *לפני* שמכניסים נתון חדש)
CREATE TRIGGER trigger_prevent_double_shift
BEFORE INSERT OR UPDATE ON SHIFT
FOR EACH ROW
EXECUTE FUNCTION prevent_double_shift();