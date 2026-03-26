import csv
import random

def create_address_csv():
    cities = [
        'Jerusalem', 'Tel Aviv', 'Haifa', 'Rishon LeZion', 'Petah Tikva', 
        'Ashdod', 'Netanya', 'Beer Sheva', 'Bnei Brak',
        'Ramat Gan', 'Rehovot', 'Ashkelon',
        'Kfar Saba', 'Herzliya', 'Modiin', 'Nazareth'
    ]    
    streets = [
        'Herzl', 'HaYarkon', 'Ben Gurion', 'Rothschild', 'Jabotinsky', 
        'Sokolov', 'Arlozorov', 'Allenby', 'King George', 'Dizengoff', 
        'Bialik', 'Rabin', 'Begin', 'Eshkol', 
    ]

    unique_addresses = set()
    target_count = 50000
    
    filename = 'addresses.csv'

    with open(filename, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(['city', 'street', 'housenumber', 'apartmentnumber'])
        
        while len(unique_addresses) < target_count:
            city = random.choice(cities)
            street = random.choice(streets)
            h_num = random.randint(1, 20)
            # 0 לבית פרטי, 1-10 לדירה
            apt_num = 0 if random.random() < 0.15 else random.randint(1, 10)
            
            addr = (city, street, h_num, apt_num)
            
            if addr not in unique_addresses:
                unique_addresses.add(addr)
                writer.writerow(addr)
                
    print(f"Success! {filename} created with {target_count} unique rows.")

if __name__ == "__main__":
    create_address_csv()