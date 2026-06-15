"""
actions_logic.py - הפעלת תתי-התוכניות משלב ד' (פונקציות ופרוצדורות) מהממשק.

נחשפות כאן 4 תתי-תוכניות:
  פונקציות:  calculate_patient_bill, get_department_roster_cursor (REF CURSOR)
  פרוצדורות: apply_salary_bonus_by_performance, reassign_doctor_department
"""
from DAL import database


def calculate_patient_bill(patient_id):
    """פונקציה: מחשבת את סך החשבונית של מטופל. מחזירה מספר."""
    return database.call_scalar_function(
        "SELECT calculate_patient_bill(%s)", [int(patient_id)]
    )


def department_roster(dep_id, min_salary):
    """
    פונקציה עם REF CURSOR: מחזירה את צוות המחלקה ששכרו מעל הסף.
    מחזירה (עמודות, שורות).
    """
    return database.fetch_refcursor_function(
        "SELECT get_department_roster_cursor(%s, %s)",
        [int(dep_id), float(min_salary)],
        "dept_staff_result_cursor",
    )


def apply_salary_bonus(min_treatments, bonus_percent):
    """פרוצדורה: מעניקה בונוס שכר לרופאים מצטיינים. מחזירה הודעות מערכת."""
    return database.call_procedure(
        "CALL apply_salary_bonus_by_performance(%s, %s)",
        [int(min_treatments), float(bonus_percent)],
    )


def reassign_doctor(doc_id, new_dep_id):
    """פרוצדורה: מעבירה רופא למחלקה אחרת ומוחקת משמרותיו העתידיות."""
    return database.call_procedure(
        "CALL reassign_doctor_department(%s, %s)",
        [int(doc_id), int(new_dep_id)],
    )
