-- image: before
SELECT AVG(Salary) AS Avg_Bonus_Group_Before
FROM MEDICAL_STAFF
WHERE ID IN (SELECT DocID FROM TREATMENT GROUP BY DocID HAVING COUNT(ID) > 10);

BEGIN;

-- making the "mistake" - giving a 10% bonus to doctors who treated more than 10 patients in the last month
UPDATE MEDICAL_STAFF
SET Salary = Salary * 1.10
WHERE ID IN (
    SELECT DocID FROM TREATMENT 
    WHERE "Date" >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY DocID HAVING COUNT(ID) > 10
);

--image: during
SELECT AVG(Salary) AS Avg_Bonus_Group_After
FROM MEDICAL_STAFF
WHERE ID IN (SELECT DocID FROM TREATMENT GROUP BY DocID HAVING COUNT(ID) > 10);

COMMIT;

--image: after 
SELECT AVG(Salary) AS Final_Verified_Salary
FROM MEDICAL_STAFF
WHERE ID IN (SELECT DocID FROM TREATMENT GROUP BY DocID HAVING COUNT(ID) > 10);