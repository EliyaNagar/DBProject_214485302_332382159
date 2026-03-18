
--query to insert data into the PATIENT table based on the PERSON table Method2

INSERT INTO PATIENT (ID, BirthDate, BloodType)
SELECT 
    ID, 
    CURRENT_DATE - (random() * 36500)::int, 
    (ARRAY['A+','A-','B+','B-','AB+','AB-','O+','O-'])[floor(random() * 8 + 1)]
FROM PERSON;

