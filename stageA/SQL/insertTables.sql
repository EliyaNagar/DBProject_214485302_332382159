
-- This file contains SQL insert statements to populate the tables created in createTable.sql with sample data.
INSERT INTO PERSON (ID, FirstName, LastName, PhoneNum) VALUES (1, 'Yisrael', 'Israeli', '050-1234567');
INSERT INTO PERSON (ID, FirstName, LastName, PhoneNum) VALUES (1001, 'Dr. Levi', 'Cohen', '052-7654321');

INSERT INTO DEPARTMENT (DepID, PhoneNum, NumOfBeds) VALUES (10, '02-6543210', 40);

INSERT INTO MEDICAL_STAFF (ID, Salary, Email, HireDate) VALUES (1001, 25000, 'levi.c@hospital.org', TO_DATE('2020-01-01', 'YYYY-MM-DD'));

INSERT INTO PATIENT (ID, BirthDate, BloodType) VALUES (1, TO_DATE('1995-05-15', 'YYYY-MM-DD'), 'AB+');

INSERT INTO ATTENDING_DOCTOR (Doctor_ID, DepID) VALUES (1001, 10);

INSERT INTO MEDICATION (M_ID, M_Name, Price) VALUES (501, 'Acamol', 15.50);


