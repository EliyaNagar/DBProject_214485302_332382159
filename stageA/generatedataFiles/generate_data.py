"""
Method 3 (generatedata): Generate SQL INSERT statements for
DEPARTMENT (500), LAB (500), MEDICATION (500)
using generatedata.com-style approach.

Output: insert_tables.sql
"""
import random
import os

random.seed(42)

output_dir = os.path.dirname(os.path.abspath(__file__))

LAB_NAMES = [
    'Blood Analysis', 'Microbiology', 'Pathology', 'Genetics', 'Immunology',
    'Biochemistry', 'Toxicology', 'Virology', 'Parasitology', 'Cytology',
    'Histology', 'Molecular Diagnostics', 'Serology', 'Bacteriology',
    'Clinical Chemistry', 'Hematology Lab', 'Urinalysis', 'Tissue Culture',
    'PCR Lab', 'Mass Spectrometry'
]

MEDICATION_NAMES = [
    'Acamol', 'Ibuprofen', 'Amoxicillin', 'Omeprazole', 'Metformin',
    'Atorvastatin', 'Amlodipine', 'Lisinopril', 'Metoprolol', 'Losartan',
    'Simvastatin', 'Aspirin', 'Prednisone', 'Gabapentin', 'Tramadol',
    'Diazepam', 'Ciprofloxacin', 'Azithromycin', 'Cephalexin', 'Doxycycline',
    'Fluoxetine', 'Sertraline', 'Escitalopram', 'Duloxetine', 'Venlafaxine',
    'Warfarin', 'Clopidogrel', 'Insulin', 'Levothyroxine', 'Albuterol',
    'Montelukast', 'Cetirizine', 'Loratadine', 'Ranitidine', 'Pantoprazole'
]


def escape_sql(s):
    return s.replace("'", "''")


print("Generating insert_tables.sql (DEPARTMENT, LAB, MEDICATION)...")

with open(os.path.join(output_dir, 'insert_tables.sql'), 'w', encoding='utf-8') as f:
    f.write("-- Generated data INSERT statements (generatedata style)\n")
    f.write("-- DEPARTMENT: 500, LAB: 500, MEDICATION: 500\n\n")

    f.write("-- DEPARTMENT (500 records)\n")
    for i in range(1, 501):
        phone = f'02-{random.randint(1000000,9999999)}'
        beds = random.randint(5, 100)
        f.write(f"INSERT INTO DEPARTMENT (DepID, PhoneNum, NumOfBeds) VALUES ({i}, '{phone}', {beds});\n")

    f.write("\n-- LAB (500 records)\n")
    for i in range(1, 501):
        name = escape_sql(f'{random.choice(LAB_NAMES)} {i}')
        techs = random.randint(1, 30)
        f.write(f"INSERT INTO LAB (LabID, Lab_Name, NumOfTechnicians) VALUES ({i}, '{name}', {techs});\n")

    f.write("\n-- MEDICATION (500 records)\n")
    for i in range(1, 501):
        name = escape_sql(f'{random.choice(MEDICATION_NAMES)} {random.randint(1,500)}mg')
        price = round(random.uniform(5.0, 500.0), 2)
        f.write(f"INSERT INTO MEDICATION (M_ID, M_Name, Price) VALUES ({i}, '{name}', {price});\n")

print("Done! Output: insert_tables.sql")
print("Tables: DEPARTMENT(500), LAB(500), MEDICATION(500)")
