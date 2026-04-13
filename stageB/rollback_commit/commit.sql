-- image: before
SELECT AVG(Salary) AS Avg_Bonus_Group_Before
FROM MEDICAL_STAFF
WHERE ID IN (
    SELECT doctor_id 
    FROM TREATMENT 
    GROUP BY doctor_id 
    HAVING COUNT(*) > 10
);


BEGIN;


UPDATE MEDICAL_STAFF
SET Salary = Salary * 1.10
WHERE ID IN (
    SELECT doctor_id 
    FROM TREATMENT 
    WHERE Treatment_Date >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY doctor_id 
    HAVING COUNT(*) > 10
);

--image: during
SELECT AVG(Salary) AS Avg_Bonus_Group_After
FROM MEDICAL_STAFF
WHERE ID IN (
    SELECT doctor_id 
    FROM TREATMENT 
    GROUP BY doctor_id 
    HAVING COUNT(*) > 10
);

COMMIT;

--image: after
SELECT AVG(Salary) AS Final_Verified_Salary
FROM MEDICAL_STAFF
WHERE ID IN (
    SELECT doctor_id 
    FROM TREATMENT 
    GROUP BY doctor_id 
    HAVING COUNT(*) > 10
);