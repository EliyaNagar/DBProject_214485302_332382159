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

-- foreign key constraint to ensure referential integrity
ALTER TABLE PERSON 
ADD CONSTRAINT fk_person_address 
FOREIGN KEY (City, Street, HouseNumber, ApartmentNumber) 
REFERENCES ADDRESS (City, Street, HouseNumber, ApartmentNumber);
