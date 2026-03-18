import csv
import random

# Generate 20,000 random people records and save to people.csv Method1
first_names = [ 'Noa', 'David', 'Maya', 'Yossi', 'Amit', 'Tamar', 'Itay', 'Michal', 'Daniel',
                'Shira', 'Omer', 'Yael', 'Yonatan', 'Lior', 'Roni', 'Gal', 'Noga', 'Ariel', 'Shani', 
                'Erez', 'Hila', 'Yair', 'Or', 'Aviv', 'Sarit', 'Ido', 'Nadav', 'Rotem', 'Shaked', 'Liat',
                'Eden', 'Yarden', 'Alon', 'Naama', 'Gilad', 'Dafna', 'Oren', 'Rivka', 'Shlomi', 'Moran',
                'Efrat', 'Yosef', 'Talia', 'Avi', 'Hadar', 'Shira', 'Eitan', 'Liron', 'Nitzan', 'Roni']
last_names = [ 'Levi', 'Cohen', 'Biton', 'Mizrahi', 'Peretz', 'Azulay', 'Katz', 'Friedman',
              'Shalom', 'Barak', 'Eliav', 'Golan', 'Harel', 'Klein', 'Lavi', 'Mendel', 'Navon', 
              'Oren', 'Paz', 'Regev', 'Sasson', 'Tzur', 'Vardi', 'Weiss', 'Yosef', 'Zohar',
              'Alon', 'Ben-David']

with open('people.csv', 'w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['id', 'firstname', 'lastname', 'phonenum'])
    
    for i in range(1, 20001):
        f_name = random.choice(first_names)
        l_name = random.choice(last_names)
        phone = f"05{random.randint(0,9)}-{random.randint(1000000, 9999999)}"
        writer.writerow([i, f_name, l_name, phone])

print("Created people.csv with 20,000 records!")