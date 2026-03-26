import random
from datetime import datetime, timedelta

def generate_unique_shift_sql():
    # --- תדביק כאן את ה-IDs האמיתיים שלך ---
    staff_ids = list(range(1, 1500)) 
    
    output_filename = 'insert_shifts.sql'
    target_records = 500 
    
    # משתנה שישמור את כל השילובים שכבר יצרנו
    used_combinations = set()
    
    shift_options = [
        ("07:00:00", 8),
        ("15:00:00", 8),
        ("23:00:00", 8)
    ]

    with open(output_filename, mode='w', encoding='utf-8') as f:
        f.write("-- SQL Insert Script for SHIFT Table\n")
        f.write("DELETE FROM shift; -- מנקה את הטבלה לפני ההכנסה כדי למנוע התנגשויות\n\n")

        count = 0
        while count < target_records:
            s_id = random.choice(staff_ids)
            
            # הגרלת תאריך (הגדלתי את הטווח ל-120 יום כדי להקטין סיכוי לכפילויות)
            random_days = random.randint(0, 120)
            date_obj = datetime(2026, 1, 1) + timedelta(days=random_days)
            date_str = date_obj.strftime('%Y-%m-%d')
            
            start_time_str, duration = random.choice(shift_options)
            
            # יצירת מפתח לבדיקה: (מי העובד, באיזה יום, באיזו שעה)
            unique_key = (s_id, date_str, start_time_str)
            
            # אם השילוב הזה כבר קיים, נדלג וננסה שוב
            if unique_key in used_combinations:
                continue
                
            used_combinations.add(unique_key)
            
            start_dt = datetime.strptime(f"{date_str} {start_time_str}", '%Y-%m-%d %H:%M:%S')
            end_dt = start_dt + timedelta(hours=duration)
            
            sql_line = (
                f"INSERT INTO shift (staff_id, shift_date, starttime, endtime) "
                f"VALUES ({s_id}, '{date_str}', '{start_dt.strftime('%Y-%m-%d %H:%M:%S')}', "
                f"'{end_dt.strftime('%Y-%m-%d %H:%M:%S')}');\n"
            )
            f.write(sql_line)
            count += 1

    print(f"Success! {output_filename} created with {target_records} unique inserts.")

if __name__ == "__main__":
    generate_unique_shift_sql()