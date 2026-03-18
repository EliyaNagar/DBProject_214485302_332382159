/* ============================================================
HOSPITAL SYSTEM - DATA POPULATION LOG
Student: Eliya Nagar | ID: 214485302
============================================================

The data was populated using 3 distinct methods as required:

--- METHOD 1: CSV Import (Bulk Data) ---
Tables: PERSON (20,000 records), PATIENT (20,000 records)
Process: 
1. Generated 20,000 records using a Python script (generate_people.py).
2. Imported the resulting 'people.csv' directly into Supabase via Table Editor.
3. Cloned PERSON IDs into PATIENT table using SQL.

--- METHOD 2: SQL Scripts (External Source) ---
Tables: DEPARTMENT (500), LAB (500), MEDICATION (500)
Process:
Executed 'insert_tables.sql' containing pre-generated INSERT statements.

--- METHOD 3: Dynamic SQL Generation (Randomized Logic) ---
Tables: MEDICAL_STAFF, ATTENDING_DOCTOR, NURSE, RESEARCHER, TREATMENT (20,000)
Process:
Used PostgreSQL random functions and subqueries to link entities.
*/

-- Example of Method 3 execution logic used:
-- (Here we document the core logic for the instructor)

/*
-- Generating 20,000 Treatments linked to existing Doctors and Patients
INSERT INTO TREATMENT (Patient_ID, Doctor_ID, Treatment_Date)
SELECT 
    (SELECT ID FROM PATIENT ORDER BY random() LIMIT 1),
    (SELECT Doctor_ID FROM ATTENDING_DOCTOR ORDER BY random() LIMIT 1),
    NOW() - (random() * interval '365 days')
FROM generate_series(1, 20000);
*/

COMMIT;