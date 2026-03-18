-- genarete meds
INSERT INTO MEDICATIONS_GIVEN (M_ID, Patient_ID, Doctor_ID, Treatment_Date)
SELECT 
    (SELECT M_ID FROM MEDICATION ORDER BY random() LIMIT 1),
    Patient_ID, Doctor_ID, Treatment_Date
FROM TREATMENT
LIMIT 500;