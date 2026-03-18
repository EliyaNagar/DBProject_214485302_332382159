
-- Insert 20,000 random treatment records
INSERT INTO TREATMENT (Patient_ID, Doctor_ID, Treatment_Date)
SELECT 
    (SELECT ID FROM PATIENT ORDER BY random() LIMIT 1),
    (SELECT Doctor_ID FROM ATTENDING_DOCTOR ORDER BY random() LIMIT 1),
    NOW() - (random() * interval '365 days') 
FROM generate_series(1, 20000);