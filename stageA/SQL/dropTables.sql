-- first drop tables with foreign keys, then drop tables without foreign keys, and finally drop the supertype table
DROP TABLE MEDICATIONS_GIVEN CASCADE CONSTRAINTS;
DROP TABLE TREATMENT CASCADE CONSTRAINTS;
DROP TABLE SHIFT CASCADE CONSTRAINTS;

-- next drop the subtypes of medical staff, which have foreign keys referencing the medical staff table
DROP TABLE NURSE CASCADE CONSTRAINTS;
DROP TABLE RESEARCHER CASCADE CONSTRAINTS;
DROP TABLE ATTENDING_DOCTOR CASCADE CONSTRAINTS;

-- next drop the tables that have foreign keys referencing the medical staff table
DROP TABLE MEDICAL_STAFF CASCADE CONSTRAINTS;
DROP TABLE PATIENT CASCADE CONSTRAINTS;
DROP TABLE MEDICATION CASCADE CONSTRAINTS;
DROP TABLE LAB CASCADE CONSTRAINTS;
DROP TABLE DEPARTMENT CASCADE CONSTRAINTS;

-- lastly, drop the supertype table, which has no foreign keys referencing it
DROP TABLE PERSON CASCADE CONSTRAINTS;

COMMIT;