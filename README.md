# DBProject_214485302_332382159

## Cover Page

**Submitted by:** 214485302, 332382159

**System:** Hospital Management System

**Selected Unit:** Medical Staff, Patients, and Treatments Management

---

## Table of Contents

1. [Introduction](#introduction)
2. [System Design](#system-design)
3. [ERD Diagram](#erd-diagram)
4. [DSD Diagram](#dsd-diagram)
5. [Design Decisions](#design-decisions)
6. [Data Insertion](#data-insertion)
7. [Backup and Restore](#backup-and-restore)

---

## Introduction

The system is designed for hospital management and enables tracking of medical staff, patients, treatments, and medications.

**Data stored in the system:**
- **Person** — Basic details of every individual in the system (name, phone number)
- **Medical Staff** — Medical employees including salary, email, and hire date
- **Patient** — Hospital patients with birth date and blood type
- **Attending Doctor** — Doctors assigned to departments
- **Nurse** — Nurses with specialization and shift type
- **Researcher** — Researchers working in laboratories
- **Department** — Hospital departments with number of beds
- **Lab** — Research laboratories with number of technicians
- **Medication** — Medication catalog with prices
- **Shift** — Staff shifts with start and end times
- **Treatment** — Treatments given to patients by doctors
- **Medications Given** — Link between treatments and medications administered

**Main functionality:**
- Managing and tracking medical staff (doctors, nurses, researchers)
- Assigning staff to departments and laboratories
- Shift management
- Tracking treatments and medications given to patients
- Department and laboratory management

---

## System Design

![alt text](images/image.png)

---

## ERD Diagram

![alt text](images/appImage.png)

---

## DSD Diagram

![DSD Diagram](images/DSD.png)

---

## Design Decisions

1. **Inheritance (ISA):** The `Person` entity serves as the supertype. `Medical_Staff` and `Patient` inherit from it. Within `Medical_Staff` there are three subtypes: `Attending_Doctor`, `Nurse`, and `Researcher`. Inheritance is implemented using a foreign key that is also a primary key (ID) — so every record in `Medical_Staff` must first exist in `Person`.

2. **Meaningful DATE fields:**
   - `HireDate` in `MEDICAL_STAFF` — Employee hire date
   - `BirthDate` in `PATIENT` — Patient birth date
   - `Treatment_Date` in `TREATMENT` — Treatment date
   - `StartDate` in `RESEARCHER` — Research start date
   - `Shift_Date` in `SHIFT` — Shift date

3. **Constraints:**
   - `Salary > 0` — Salary must be positive
   - `Price >= 0` — Medication price cannot be negative
   - `NumOfBeds >= 0` — Number of beds cannot be negative
   - `NumOfTechnicians >= 0` — Number of technicians cannot be negative
   - `BloodType IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')` — Only valid blood type values
   - `Email UNIQUE` — Unique email address per employee

4. **Relationships:**
   - `Treatment` — Many-to-many relationship between `Patient` and `Attending_Doctor` with date as part of the key
   - `Medications_Given` — Many-to-many relationship between `Treatment` and `Medication`
   - `Shift` — Weak entity dependent on `Medical_Staff`

---

## Data Insertion

Data was inserted using 3 different methods:

### Method 1: CSV File Import (`DataImportFiles/`)

CSV files were generated using a Python script (`generate_csv.py`).

**Tables:**
| Table | Record Count |
|-------|-------------|
| PERSON | 21,500 |
| PATIENT | 20,000 |

Data was imported into the database using SQL*Loader with control files (`.ctl`).

![alt text](images/sqlLoader.png)

### Method 2: Programming — Python-generated INSERT statements (`Programing/`)

A Python script (`generate_inserts.py`) generates a SQL file with INSERT statements.

**Tables:**
| Table | Record Count |
|-------|-------------|
| MEDICAL_STAFF | 1,500 |
| ATTENDING_DOCTOR | 500 |
| NURSE | 500 |
| RESEARCHER | 500 |
| SHIFT | 500 |
| TREATMENT | 20,000 |
| MEDICATIONS_GIVEN | 500 |


### Method 3: generatedata — INSERT statement generation (`generatedataFiles/`)

INSERT statements were generated for the following tables:

**Tables:**
| Table | Record Count |
|-------|-------------|
| DEPARTMENT | 500 |
| LAB | 500 |
| MEDICATION | 500 |

![alt text](images/sqlLoader.png)

### Record Count Summary

| Table | Record Count | Method |
|-------|-------------|--------|
| PERSON | 21,500 | CSV Import |
| PATIENT | 20,000 | CSV Import |
| TREATMENT | 20,000 | Python INSERT |
| MEDICAL_STAFF | 1,500 | Python INSERT |
| DEPARTMENT | 500 | generatedata |
| LAB | 500 | generatedata |
| MEDICATION | 500 | generatedata |
| ATTENDING_DOCTOR | 500 | Python INSERT |
| NURSE | 500 | Python INSERT |
| RESEARCHER | 500 | Python INSERT |
| SHIFT | 500 | Python INSERT |
| MEDICATIONS_GIVEN | 500 | Python INSERT |

---

## Backup and Restore

### Backup

Backup was performed using Oracle Data Pump Export (`expdp`).

Backup file is saved in the format: `backup_YYYY-MM-DD.dmp`

Backup script: `backup.bat`


### Restore

Restore was performed on a different machine using Oracle Data Pump Import (`impdp`).

Restore script: `restore.bat`
