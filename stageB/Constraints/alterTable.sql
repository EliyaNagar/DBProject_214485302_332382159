-- update the DB to add Address within ERD and DSD

--ALTER TABLE - new table and foreign key
CREATE TABLE ADDRESS (
    City VARCHAR(100) NOT NULL,
    Street VARCHAR(100) NOT NULL,
    HouseNumber INT NOT NULL,
    ApartmentNumber INT NOT NULL DEFAULT 0, -- 0 if it is a house and not an apartment
    PRIMARY KEY (City, Street, HouseNumber, ApartmentNumber)
);

--add new column to person table
ALTER TABLE PERSON ADD COLUMN City VARCHAR(100);
ALTER TABLE PERSON ADD COLUMN Street VARCHAR(100);
ALTER TABLE PERSON ADD COLUMN HouseNumber INT;
ALTER TABLE PERSON ADD COLUMN ApartmentNumber INT DEFAULT 0;

-- Constraint 1: Foreign Key - כתובת אדם חייבת להתקיים בטבלת ADDRESS
ALTER TABLE PERSON
ADD CONSTRAINT fk_person_address
FOREIGN KEY (City, Street, HouseNumber, ApartmentNumber)
REFERENCES ADDRESS (City, Street, HouseNumber, ApartmentNumber);

-- Constraint 2: Check - זמן סיום משמרת חייב להיות לאחר זמן ההתחלה
ALTER TABLE SHIFT
ADD CONSTRAINT chk_shift_times CHECK (EndTime > StartTime);

-- Constraint 3: Check - סוג משמרת חייב להיות אחד מהערכים המוגדרים
ALTER TABLE NURSE
ADD CONSTRAINT chk_nurse_shift_type
CHECK (ShiftType IN ('Morning', 'Afternoon', 'Night'));


/*******************************************************************************
  הדגמת הפרת אילוצים - כל INSERT מטה אמור להחזיר שגיאה
*******************************************************************************/

-- הפרת אילוץ 1 (FK): כתובת שלא קיימת בטבלת ADDRESS
-- תחילה מוסיפים כתובת תקינה אחת לדוגמה:
INSERT INTO ADDRESS (City, Street, HouseNumber, ApartmentNumber)
VALUES ('Tel Aviv', 'Dizengoff', 1, 0);

-- עכשיו מנסים להכניס אדם עם כתובת שלא קיימת ב-ADDRESS:
INSERT INTO PERSON (ID, FirstName, LastName, PhoneNum, City, Street, HouseNumber, ApartmentNumber)
VALUES (99999, 'Test', 'Violation', '0500000001', 'FakeCity', 'NoSuchStreet', 999, 0);
-- צפויה שגיאה: ERROR: insert or update on table "person" violates foreign key constraint "fk_person_address"

-- הפרת אילוץ 2 (CHECK): זמן סיום לפני זמן התחלה
INSERT INTO SHIFT (Staff_ID, Shift_Date, StartTime, EndTime)
VALUES (1, '2024-06-01', '2024-06-01 18:00:00', '2024-06-01 08:00:00');
-- צפויה שגיאה: ERROR: new row for relation "shift" violates check constraint "chk_shift_times"

-- הפרת אילוץ 3 (CHECK): סוג משמרת לא קיים ברשימה המוגדרת
INSERT INTO NURSE (Nurse_ID, ShiftType, Specialization, DepID)
VALUES (99999, 'Weekend', 'Cardiology', 1);
-- צפויה שגיאה: ERROR: new row for relation "nurse" violates check constraint "chk_nurse_shift_type"
