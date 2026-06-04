from DAL.database import get_connection

def verify_login(username, password):
    """
    בודק האם הקלט תקין והאם יש חיבור לשרת.
    מחזיר Tuple של (הצלחה/כישלון, הודעה טקסטואלית).
    """
    # 1. בדיקה שהשדות לא ריקים
    if not username or not password:
        return False, "אנא הזן שם משתמש וסיסמה."

    # 2. אימות מול המשתמש הפיקטיבי שלנו
    if username != "admin" or password != "1234":
        return False, "שם משתמש או סיסמה שגויים. נסה שוב."

    # 3. אם הסיסמה נכונה - נוודא שהשרת באוויר
    conn = get_connection()
    if conn:
        conn.close()
        return True, f"ברוך הבא למערכת, {username}!"
    else:
        return False, "שגיאת רשת: לא ניתן להתחבר למסד הנתונים."