--more staff members
INSERT INTO MEDICAL_STAFF (ID, Salary, Email, HireDate)
SELECT ID, (random() * 15000 + 8000)::decimal(10,2), 'staff' || ID || '@hospital.com', CURRENT_DATE - (random() * 3000)::int
FROM PERSON WHERE ID > 500 AND ID <= 1500;

-- 500 nurses
INSERT INTO NURSE (Nurse_ID, ShiftType, Specialization, DepID)
SELECT ID, 
       (ARRAY['Morning', 'Evening', 'Night'])[floor(random() * 3 + 1)], 
       'General Care', 
       (SELECT DepID FROM DEPARTMENT ORDER BY random() LIMIT 1)
FROM MEDICAL_STAFF WHERE ID > 500 AND ID <= 1000;

-- 500 researchers
INSERT INTO RESEARCHER (Researcher_ID, Research_Field, StartDate, LabID)
SELECT ID, 'Clinical Research', HireDate, (SELECT LabID FROM LAB ORDER BY random() LIMIT 1)
FROM MEDICAL_STAFF WHERE ID > 1000 AND ID <= 1500;