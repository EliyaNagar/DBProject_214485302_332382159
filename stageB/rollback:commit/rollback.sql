-- image: before
SELECT AVG(Salary) AS Avg_Before_Mistake 
FROM MEDICAL_STAFF;

BEGIN;

-- 50% increase in salary for all medical staff (this is the "mistake" we will roll back)
UPDATE MEDICAL_STAFF 
SET Salary = Salary * 1.5;

-- image: during
SELECT AVG(Salary) AS Avg_During_Transaction 
FROM MEDICAL_STAFF;

ROLLBACK;

-- image: after
SELECT AVG(Salary) AS Final_Avg_Verified 
FROM MEDICAL_STAFF;