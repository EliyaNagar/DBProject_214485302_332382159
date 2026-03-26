
-- Insert 20,000 random treatment records
INSERT INTO TREATMENT (Patient_ID, Doctor_ID, Treatment_Date)
SELECT 
    p.ID, 
    d.Doctor_ID, 
    NOW() - (random() * interval '365 days')
FROM generate_series(1, 20000) s
CROSS JOIN LATERAL (
    SELECT ID FROM PATIENT 
    WHERE s > 0
    ORDER BY random() LIMIT 1
) p
CROSS JOIN LATERAL (
    SELECT Doctor_ID FROM ATTENDING_DOCTOR 
    WHERE s > 0
    ORDER BY random() LIMIT 1
) d
ON CONFLICT DO NOTHING;