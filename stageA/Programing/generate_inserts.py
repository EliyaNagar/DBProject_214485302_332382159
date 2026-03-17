"""
Method 2 (Programing): Generate SQL INSERT statements via Python.

Generates: MEDICAL_STAFF (1500), ATTENDING_DOCTOR (500), NURSE (500),
           RESEARCHER (500), SHIFT (500), TREATMENT (20000), MEDICATIONS_GIVEN (500)

Output: generated_inserts.sql
"""
import random
import os
from datetime import datetime, timedelta

random.seed(42)

output_dir = os.path.dirname(os.path.abspath(__file__))

SHIFT_TYPES = ['Morning', 'Afternoon', 'Night']

SPECIALIZATIONS = [
    'ICU', 'ER', 'Surgical', 'Pediatric', 'Oncology', 'Cardiac',
    'Neonatal', 'Geriatric', 'Psychiatric', 'Rehabilitation',
    'Anesthesia', 'Dialysis', 'Wound Care', 'Infection Control', 'Palliative'
]

RESEARCH_FIELDS = [
    'Cancer Biology', 'Neuroscience', 'Immunotherapy', 'Gene Therapy',
    'Drug Discovery', 'Epidemiology', 'Clinical Trials', 'Bioinformatics',
    'Stem Cell Research', 'Vaccine Development', 'Pharmacology',
    'Molecular Biology', 'Cardiology Research', 'Diabetes Research',
    'Infectious Disease', 'Genomics', 'Proteomics', 'Regenerative Medicine',
    'Public Health', 'Biostatistics'
]

EMAIL_DOMAINS = ['hospital.org', 'med-center.co.il', 'health.gov.il', 'clinic.org.il']


def random_date(start_year, end_year):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def fmt_date(d):
    return f"TO_DATE('{d.strftime('%Y-%m-%d')}', 'YYYY-MM-DD')"


def fmt_timestamp(d):
    return f"TO_TIMESTAMP('{d.strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"


def escape_sql(s):
    return s.replace("'", "''")


# ============================================================
# Generate SQL INSERT files for all tables
# ============================================================
print("Generating generated_inserts.sql ...")

with open(os.path.join(output_dir, 'generated_inserts.sql'), 'w', encoding='utf-8') as f:
    f.write("-- Method 3: Python-generated SQL INSERT statements\n")
    f.write("-- MEDICAL_STAFF: 1500, ATTENDING_DOCTOR: 500, NURSE: 500\n")
    f.write("-- RESEARCHER: 500, SHIFT: 500, TREATMENT: 20000, MEDICATIONS_GIVEN: 500\n\n")

    # MEDICAL_STAFF (1500 records, IDs 1-1500 - subset of PERSON)
    f.write("-- MEDICAL_STAFF (1500 records)\n")
    for i in range(1, 1501):
        salary = round(random.uniform(8000, 60000), 2)
        domain = random.choice(EMAIL_DOMAINS)
        email = f'staff{i}@{domain}'
        hire_date = random_date(2000, 2024)
        f.write(f"INSERT INTO MEDICAL_STAFF (ID, Salary, Email, HireDate) VALUES ({i}, {salary}, '{email}', {fmt_date(hire_date)});\n")

    # ATTENDING_DOCTOR (500 records, IDs 1-500)
    f.write("\n-- ATTENDING_DOCTOR (500 records)\n")
    for i in range(1, 501):
        dep_id = random.randint(1, 500)
        f.write(f"INSERT INTO ATTENDING_DOCTOR (Doctor_ID, DepID) VALUES ({i}, {dep_id});\n")

    # NURSE (500 records, IDs 501-1000)
    f.write("\n-- NURSE (500 records)\n")
    for i in range(501, 1001):
        shift_type = random.choice(SHIFT_TYPES)
        spec = random.choice(SPECIALIZATIONS)
        dep_id = random.randint(1, 500)
        f.write(f"INSERT INTO NURSE (Nurse_ID, ShiftType, Specialization, DepID) VALUES ({i}, '{shift_type}', '{spec}', {dep_id});\n")

    # RESEARCHER (500 records, IDs 1001-1500)
    f.write("\n-- RESEARCHER (500 records)\n")
    for i in range(1001, 1501):
        field = escape_sql(random.choice(RESEARCH_FIELDS))
        start_date = random_date(2005, 2024)
        lab_id = random.randint(1, 500)
        f.write(f"INSERT INTO RESEARCHER (Researcher_ID, Research_Field, StartDate, LabID) VALUES ({i}, '{field}', {fmt_date(start_date)}, {lab_id});\n")

    # SHIFT (500 records)
    f.write("\n-- SHIFT (500 records)\n")
    used_shifts = set()
    count = 0
    while count < 500:
        staff_id = random.randint(1, 1500)
        shift_date = random_date(2023, 2025)
        shift_date_str = shift_date.strftime('%Y-%m-%d')
        hour = random.choice([7, 15, 23])
        key = (staff_id, shift_date_str, hour)
        if key in used_shifts:
            continue
        used_shifts.add(key)
        start_ts = shift_date.replace(hour=hour, minute=0, second=0)
        end_ts = start_ts + timedelta(hours=8)
        f.write(f"INSERT INTO SHIFT (Staff_ID, Shift_Date, StartTime, EndTime) VALUES ({staff_id}, {fmt_date(shift_date)}, {fmt_timestamp(start_ts)}, {fmt_timestamp(end_ts)});\n")
        count += 1

    # TREATMENT (20,000 records)
    f.write("\n-- TREATMENT (20000 records)\n")
    used_treatments = set()
    treatment_keys = []
    count = 0
    while count < 20000:
        patient_id = random.randint(1501, 21500)
        doctor_id = random.randint(1, 500)
        treat_date = random_date(2020, 2025)
        treat_date_str = treat_date.strftime('%Y-%m-%d')
        key = (patient_id, doctor_id, treat_date_str)
        if key in used_treatments:
            continue
        used_treatments.add(key)
        treatment_keys.append(key)
        f.write(f"INSERT INTO TREATMENT (Patient_ID, Doctor_ID, Treatment_Date) VALUES ({patient_id}, {doctor_id}, {fmt_date(treat_date)});\n")
        count += 1

    # MEDICATIONS_GIVEN (500 records)
    f.write("\n-- MEDICATIONS_GIVEN (500 records)\n")
    used_med_given = set()
    count = 0
    while count < 500:
        tk = random.choice(treatment_keys)
        m_id = random.randint(1, 500)
        key = (m_id, tk[0], tk[1], tk[2])
        if key in used_med_given:
            continue
        used_med_given.add(key)
        treat_date = datetime.strptime(tk[2], '%Y-%m-%d')
        f.write(f"INSERT INTO MEDICATIONS_GIVEN (M_ID, Patient_ID, Doctor_ID, Treatment_Date) VALUES ({m_id}, {tk[0]}, {tk[1]}, {fmt_date(treat_date)});\n")
        count += 1

print("  generated_inserts.sql generated.")
print("\nDone! Output: generated_inserts.sql")
print("Tables: MEDICAL_STAFF(1500), ATTENDING_DOCTOR(500), NURSE(500),")
print("  RESEARCHER(500), SHIFT(500), TREATMENT(20000), MEDICATIONS_GIVEN(500)")
