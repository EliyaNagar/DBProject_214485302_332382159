"""
db_metadata.py - תיאור מטא-דאטה של כל טבלאות המערכת.

מודול זה הוא "המוח" של מסך ה-CRUD הגנרי: עבור כל טבלה הוא מגדיר
את המפתח הראשי, את העמודות לעריכה, ואת המפתחות הזרים.
בעזרת המידע הזה מסך אחד גנרי יודע לטפל בכל 14 הטבלאות,
ולהציג שמות ידידותיים במקום מזהים (ID) של מפתחות זרים.
"""

# -----------------------------------------------------------------------------
# שאילתות לתיבות בחירה (Combobox) של מפתחות זרים - מחזירות (מזהה, תווית להצגה)
# -----------------------------------------------------------------------------
FK_PERSON   = "SELECT ID, FirstName || ' ' || LastName FROM PERSON ORDER BY FirstName, LastName"
FK_STAFF    = ("SELECT ms.ID, p.FirstName || ' ' || p.LastName "
               "FROM MEDICAL_STAFF ms JOIN PERSON p ON ms.ID = p.ID ORDER BY p.FirstName")
FK_DOCTOR   = ("SELECT ad.Doctor_ID, p.FirstName || ' ' || p.LastName "
               "FROM ATTENDING_DOCTOR ad JOIN PERSON p ON ad.Doctor_ID = p.ID ORDER BY p.FirstName")
FK_PATIENT  = ("SELECT pa.ID, p.FirstName || ' ' || p.LastName "
               "FROM PATIENT pa JOIN PERSON p ON pa.ID = p.ID ORDER BY p.FirstName")
FK_DEPT     = "SELECT DepID, 'מחלקה ' || DepID || ' (' || NumOfBeds || ' מיטות)' FROM DEPARTMENT ORDER BY DepID"
FK_LAB      = "SELECT LabID, Lab_Name FROM LAB ORDER BY Lab_Name"
FK_MED      = "SELECT M_ID, M_Name FROM MEDICATION ORDER BY M_Name"


def col(name, label, ctype="text", pk=False, fk=None, options=None, auto=False):
    """בונה הגדרת עמודה.
    ctype: text|int|decimal|date|timestamp
    fk: שאילתת SQL להבאת אפשרויות (מציג שם, שומר מזהה)
    options: רשימת ערכים קבועה (למשל סוג דם)
    auto: עמודה אוטומטית (SERIAL) - לא ממלאים אותה בהוספה
    """
    return {"name": name, "label": label, "type": ctype, "pk": pk,
            "fk": fk, "options": options, "auto": auto}


# -----------------------------------------------------------------------------
# הגדרת הטבלאות. לכל טבלה:
#   label  - שם תצוגה בעברית
#   pk     - רשימת עמודות המפתח הראשי
#   select - שאילתת תצוגה לרשת (כבר עם JOIN-ים שמציגים שמות במקום מזהים)
#   columns- הגדרות העמודות לטופס ההוספה/עדכון
# -----------------------------------------------------------------------------
TABLES = {
    "PERSON": {
        "label": "אנשים (Person)",
        "pk": ["id"],
        "select": ("SELECT ID AS \"מזהה\", FirstName AS \"שם פרטי\", LastName AS \"שם משפחה\", "
                   "PhoneNum AS \"טלפון\", City AS \"עיר\", Street AS \"רחוב\", "
                   "HouseNumber AS \"מס' בית\", ApartmentNumber AS \"דירה\" FROM PERSON ORDER BY ID"),
        "columns": [
            col("ID", "מזהה (ת\"ז)", "int", pk=True),
            col("FirstName", "שם פרטי"),
            col("LastName", "שם משפחה"),
            col("PhoneNum", "טלפון"),
            col("City", "עיר"),
            col("Street", "רחוב"),
            col("HouseNumber", "מספר בית", "int"),
            col("ApartmentNumber", "מספר דירה", "int"),
        ],
    },

    "MEDICAL_STAFF": {
        "label": "צוות רפואי (Medical Staff)",
        "pk": ["id"],
        "select": ("SELECT ms.ID AS \"מזהה\", p.FirstName || ' ' || p.LastName AS \"שם העובד\", "
                   "ms.Salary AS \"שכר\", ms.Email AS \"אימייל\", ms.HireDate AS \"תאריך גיוס\" "
                   "FROM MEDICAL_STAFF ms JOIN PERSON p ON ms.ID = p.ID ORDER BY p.FirstName"),
        "columns": [
            col("ID", "עובד", "int", pk=True, fk=FK_PERSON),
            col("Salary", "שכר", "decimal"),
            col("Email", "אימייל"),
            col("HireDate", "תאריך גיוס", "date"),
        ],
    },

    "DEPARTMENT": {
        "label": "מחלקות (Department)",
        "pk": ["depid"],
        "select": ("SELECT DepID AS \"מזהה מחלקה\", PhoneNum AS \"טלפון\", "
                   "NumOfBeds AS \"מספר מיטות\" FROM DEPARTMENT ORDER BY DepID"),
        "columns": [
            col("DepID", "מזהה מחלקה", "int", pk=True),
            col("PhoneNum", "טלפון"),
            col("NumOfBeds", "מספר מיטות", "int"),
        ],
    },

    "SHIFT": {
        "label": "משמרות (Shift)",
        "pk": ["staff_id", "shift_date", "starttime"],
        "select": ("SELECT s.Staff_ID AS \"מזהה עובד\", p.FirstName || ' ' || p.LastName AS \"שם העובד\", "
                   "s.Shift_Date AS \"תאריך\", s.StartTime AS \"התחלה\", s.EndTime AS \"סיום\" "
                   "FROM SHIFT s JOIN PERSON p ON s.Staff_ID = p.ID ORDER BY s.Shift_Date DESC"),
        "columns": [
            col("Staff_ID", "עובד", "int", pk=True, fk=FK_STAFF),
            col("Shift_Date", "תאריך משמרת", "date", pk=True),
            col("StartTime", "שעת התחלה", "timestamp", pk=True),
            col("EndTime", "שעת סיום", "timestamp"),
        ],
    },

    "LAB": {
        "label": "מעבדות (Lab)",
        "pk": ["labid"],
        "select": ("SELECT LabID AS \"מזהה\", Lab_Name AS \"שם המעבדה\", "
                   "NumOfTechnicians AS \"מספר טכנאים\" FROM LAB ORDER BY Lab_Name"),
        "columns": [
            col("LabID", "מזהה מעבדה", "int", pk=True),
            col("Lab_Name", "שם המעבדה"),
            col("NumOfTechnicians", "מספר טכנאים", "int"),
        ],
    },

    "PATIENT": {
        "label": "מטופלים (Patient)",
        "pk": ["id"],
        "select": ("SELECT pa.ID AS \"מזהה\", p.FirstName || ' ' || p.LastName AS \"שם המטופל\", "
                   "pa.BirthDate AS \"תאריך לידה\", pa.BloodType AS \"סוג דם\" "
                   "FROM PATIENT pa JOIN PERSON p ON pa.ID = p.ID ORDER BY p.FirstName"),
        "columns": [
            col("ID", "אדם", "int", pk=True, fk=FK_PERSON),
            col("BirthDate", "תאריך לידה", "date"),
            col("BloodType", "סוג דם", options=["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]),
        ],
    },

    "ATTENDING_DOCTOR": {
        "label": "רופאים מטפלים (Attending Doctor)",
        "pk": ["doctor_id"],
        "select": ("SELECT ad.Doctor_ID AS \"מזהה\", p.FirstName || ' ' || p.LastName AS \"שם הרופא\", "
                   "'מחלקה ' || ad.DepID AS \"מחלקה\" "
                   "FROM ATTENDING_DOCTOR ad JOIN PERSON p ON ad.Doctor_ID = p.ID ORDER BY p.FirstName"),
        "columns": [
            col("Doctor_ID", "רופא (מתוך הצוות)", "int", pk=True, fk=FK_STAFF),
            col("DepID", "מחלקה", "int", fk=FK_DEPT),
        ],
    },

    "MEDICATION": {
        "label": "תרופות (Medication)",
        "pk": ["m_id"],
        "select": ("SELECT M_ID AS \"מזהה\", M_Name AS \"שם התרופה\", Price AS \"מחיר\" "
                   "FROM MEDICATION ORDER BY M_Name"),
        "columns": [
            col("M_ID", "מזהה תרופה", "int", pk=True),
            col("M_Name", "שם התרופה"),
            col("Price", "מחיר", "decimal"),
        ],
    },

    "TREATMENT": {
        "label": "טיפולים (Treatment)",
        "pk": ["patient_id", "doctor_id", "treatment_date"],
        "select": ("SELECT pp.FirstName || ' ' || pp.LastName AS \"מטופל\", "
                   "dp.FirstName || ' ' || dp.LastName AS \"רופא\", "
                   "t.Treatment_Date AS \"תאריך הטיפול\" "
                   "FROM TREATMENT t "
                   "JOIN PERSON pp ON t.Patient_ID = pp.ID "
                   "JOIN PERSON dp ON t.Doctor_ID = dp.ID ORDER BY t.Treatment_Date DESC"),
        "columns": [
            col("Patient_ID", "מטופל", "int", pk=True, fk=FK_PATIENT),
            col("Doctor_ID", "רופא", "int", pk=True, fk=FK_DOCTOR),
            col("Treatment_Date", "תאריך הטיפול", "timestamp", pk=True),
        ],
    },

    "MEDICATIONS_GIVEN": {
        "label": "תרופות שניתנו (Medications Given)",
        "pk": ["m_id", "patient_id", "doctor_id", "treatment_date"],
        "select": ("SELECT m.M_Name AS \"תרופה\", pp.FirstName || ' ' || pp.LastName AS \"מטופל\", "
                   "dp.FirstName || ' ' || dp.LastName AS \"רופא\", mg.Treatment_Date AS \"תאריך\" "
                   "FROM MEDICATIONS_GIVEN mg "
                   "JOIN MEDICATION m ON mg.M_ID = m.M_ID "
                   "JOIN PERSON pp ON mg.Patient_ID = pp.ID "
                   "JOIN PERSON dp ON mg.Doctor_ID = dp.ID ORDER BY mg.Treatment_Date DESC"),
        "columns": [
            col("M_ID", "תרופה", "int", pk=True, fk=FK_MED),
            col("Patient_ID", "מטופל", "int", pk=True, fk=FK_PATIENT),
            col("Doctor_ID", "רופא", "int", pk=True, fk=FK_DOCTOR),
            col("Treatment_Date", "תאריך הטיפול", "timestamp", pk=True),
        ],
    },

    "NURSE": {
        "label": "אחיות (Nurse)",
        "pk": ["nurse_id"],
        "select": ("SELECT n.Nurse_ID AS \"מזהה\", p.FirstName || ' ' || p.LastName AS \"שם האח/ות\", "
                   "n.ShiftType AS \"סוג משמרת\", n.Specialization AS \"התמחות\", "
                   "'מחלקה ' || n.DepID AS \"מחלקה\" "
                   "FROM NURSE n JOIN PERSON p ON n.Nurse_ID = p.ID ORDER BY p.FirstName"),
        "columns": [
            col("Nurse_ID", "אח/ות (מתוך הצוות)", "int", pk=True, fk=FK_STAFF),
            col("ShiftType", "סוג משמרת", options=["Morning", "Afternoon", "Night"]),
            col("Specialization", "התמחות"),
            col("DepID", "מחלקה", "int", fk=FK_DEPT),
        ],
    },

    "RESEARCHER": {
        "label": "חוקרים (Researcher)",
        "pk": ["researcher_id"],
        "select": ("SELECT r.Researcher_ID AS \"מזהה\", p.FirstName || ' ' || p.LastName AS \"שם החוקר\", "
                   "r.Research_Field AS \"תחום מחקר\", r.StartDate AS \"תאריך תחילה\", "
                   "l.Lab_Name AS \"מעבדה\" "
                   "FROM RESEARCHER r JOIN PERSON p ON r.Researcher_ID = p.ID "
                   "JOIN LAB l ON r.LabID = l.LabID ORDER BY p.FirstName"),
        "columns": [
            col("Researcher_ID", "חוקר (מתוך הצוות)", "int", pk=True, fk=FK_STAFF),
            col("Research_Field", "תחום מחקר"),
            col("StartDate", "תאריך תחילה", "date"),
            col("LabID", "מעבדה", "int", fk=FK_LAB),
        ],
    },

    "ADDRESS": {
        "label": "כתובות (Address)",
        "pk": ["city", "street", "housenumber", "apartmentnumber"],
        "select": ("SELECT City AS \"עיר\", Street AS \"רחוב\", HouseNumber AS \"מס' בית\", "
                   "ApartmentNumber AS \"דירה\" FROM ADDRESS ORDER BY City, Street"),
        "columns": [
            col("City", "עיר", pk=True),
            col("Street", "רחוב", pk=True),
            col("HouseNumber", "מספר בית", "int", pk=True),
            col("ApartmentNumber", "מספר דירה", "int", pk=True),
        ],
    },

    "SALARY_AUDIT": {
        "label": "ביקורת שכר (Salary Audit) - מתעדכן ע\"י טריגר",
        "pk": ["audit_id"],
        "select": ("SELECT sa.Audit_ID AS \"מזהה\", p.FirstName || ' ' || p.LastName AS \"עובד\", "
                   "sa.Old_Salary AS \"שכר ישן\", sa.New_Salary AS \"שכר חדש\", "
                   "sa.Change_Date AS \"מועד השינוי\" "
                   "FROM SALARY_AUDIT sa JOIN PERSON p ON sa.Staff_ID = p.ID ORDER BY sa.Change_Date DESC"),
        "columns": [
            col("Audit_ID", "מזהה", "int", pk=True, auto=True),
            col("Staff_ID", "עובד", "int", fk=FK_STAFF),
            col("Old_Salary", "שכר ישן", "decimal"),
            col("New_Salary", "שכר חדש", "decimal"),
            col("Change_Date", "מועד השינוי", "timestamp"),
        ],
    },
}
