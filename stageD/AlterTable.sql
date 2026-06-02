-- AlterTable.sql - שלב ד: שינויים בסכמת בסיס הנתונים
-- קובץ זה כולל את כל הטבלאות החדשות שנוצרו לצורך תוכניות שלב ד

-- טבלת ביקורת לתיעוד שינויי שכר (נדרשת על ידי trigger_audit_salary)
CREATE TABLE IF NOT EXISTS SALARY_AUDIT (
    Audit_ID    SERIAL PRIMARY KEY,
    Staff_ID    INT            NOT NULL,
    Old_Salary  DECIMAL(10,2)  NOT NULL,
    New_Salary  DECIMAL(10,2)  NOT NULL,
    Change_Date TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_staff FOREIGN KEY (Staff_ID) REFERENCES MEDICAL_STAFF(ID)
);
