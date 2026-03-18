--create medical staff records for the first 500 people Method2
INSERT INTO MEDICAL_STAFF (ID, Salary, Email, HireDate)
SELECT 
    ID, 
    (random() * 20000 + 10000)::decimal(10,2),
    'staff' || ID || '@hospital.com',
    CURRENT_DATE - (random() * 3650)::int
FROM PERSON
WHERE ID <= 500;

--make few of the medical staff into attending doctors
INSERT INTO ATTENDING_DOCTOR (Doctor_ID, DepID)
SELECT 
    ID, 
    (SELECT DepID FROM DEPARTMENT ORDER BY random() LIMIT 1)
FROM MEDICAL_STAFF;