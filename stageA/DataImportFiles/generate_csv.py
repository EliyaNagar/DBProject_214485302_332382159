"""
Method 1: Generate CSV files for PERSON and PATIENT tables.
PERSON: 21,500 records (IDs 1-21500)
PATIENT: 20,000 records (IDs 1501-21500, subset of PERSON)
"""
import csv
import random
import os

random.seed(42)

FIRST_NAMES = [
    'Yosef', 'David', 'Moshe', 'Avraham', 'Yaakov', 'Yitzhak', 'Shmuel', 'Daniel',
    'Eliyahu', 'Noam', 'Oren', 'Amit', 'Eitan', 'Ari', 'Gal', 'Ido', 'Lior',
    'Nir', 'Omer', 'Ran', 'Tal', 'Uri', 'Yonatan', 'Ziv', 'Alon', 'Ben',
    'Chen', 'Dor', 'Eli', 'Gil', 'Hai', 'Itai', 'Kobi', 'Matan', 'Nadav',
    'Ohad', 'Paz', 'Ron', 'Shahar', 'Tomer', 'Yaron', 'Zohar', 'Adam',
    'Sarah', 'Miriam', 'Rivka', 'Rachel', 'Leah', 'Tamar', 'Noa', 'Shira',
    'Maya', 'Yael', 'Hila', 'Dana', 'Michal', 'Liora', 'Keren', 'Inbar',
    'Ayala', 'Batya', 'Chana', 'Devora', 'Efrat', 'Galit', 'Hadasa', 'Ilana',
    'Julia', 'Kayla', 'Liat', 'Merav', 'Naomi', 'Orly', 'Penina', 'Ruth'
]

LAST_NAMES = [
    'Cohen', 'Levi', 'Mizrachi', 'Peretz', 'Biton', 'Dahan', 'Avraham', 'Friedman',
    'Shapira', 'Goldstein', 'Katz', 'Rosenberg', 'Klein', 'Schwartz', 'Weiss',
    'Berkowitz', 'Horowitz', 'Lieberman', 'Stern', 'Blum', 'Gross', 'Feldman',
    'Fischer', 'Hoffman', 'Rosen', 'Adler', 'Baum', 'Diamond', 'Engel', 'Frank',
    'Green', 'Hershko', 'Israel', 'Jacobson', 'Kaplan', 'Levin', 'Miller',
    'Newman', 'Oren', 'Pollak', 'Rabinowitz', 'Silver', 'Teller', 'Ullman',
    'Vardi', 'Weinstein', 'Yosef', 'Zamir', 'Ashkenazi', 'Ben-David'
]

BLOOD_TYPES = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']

output_dir = os.path.dirname(os.path.abspath(__file__))

# Generate PERSON CSV
print("Generating PERSON CSV (21,500 records)...")
with open(os.path.join(output_dir, 'person.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['ID', 'FirstName', 'LastName', 'PhoneNum'])
    for i in range(1, 21501):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        phone = f'05{random.randint(0,9)}-{random.randint(1000000,9999999)}'
        writer.writerow([i, first, last, phone])

# Generate PATIENT CSV
print("Generating PATIENT CSV (20,000 records)...")
with open(os.path.join(output_dir, 'patient.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['ID', 'BirthDate', 'BloodType'])
    for i in range(1501, 21501):
        year = random.randint(1940, 2010)
        month = random.randint(1, 12)
        day = random.randint(1, 28)
        birth_date = f'{year}-{month:02d}-{day:02d}'
        blood = random.choice(BLOOD_TYPES)
        writer.writerow([i, birth_date, blood])

print("CSV files generated successfully!")
print(f"  person.csv: 21,500 records")
print(f"  patient.csv: 20,000 records")
