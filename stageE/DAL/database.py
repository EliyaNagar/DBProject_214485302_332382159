import psycopg2
import psycopg2.extras


def get_connection():
    """יוצר חיבור למסד הנתונים ומחזיר את אובייקט החיבור"""
    try:
        conn = psycopg2.connect(
            host="aws-1-eu-central-1.pooler.supabase.com",
            port="6543",
            database="postgres",
            user="postgres.pslxaejgkeloehflbxit",
            password="EliyaDavid123!",
            sslmode="require"
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None


# =============================================================================
# פונקציות גנריות לעבודה מול בסיס הנתונים (שכבת גישה לנתונים - DAL)
# כל פונקציה פותחת חיבור, מבצעת את הפעולה וסוגרת אותו, ומחזירה תוצאה/שגיאה.
# =============================================================================

def run_select(sql, params=None):
    """
    מריץ שאילתת שליפה ומחזיר Tuple: (רשימת שמות עמודות, רשימת שורות).
    זורק חריגה במקרה של כשל כדי שהשכבה שמעליו תטפל בהודעה למשתמש.
    """
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        cur = conn.cursor()
        cur.execute(sql, params or ())
        columns = [desc[0] for desc in cur.description] if cur.description else []
        rows = cur.fetchall()
        cur.close()
        return columns, rows
    finally:
        conn.close()


def get_fk_options(sql):
    """
    מחזיר רשימת Tuples של (ערך_מפתח, תווית_תצוגה) עבור תיבות בחירה (Combobox) של מפתחות זרים.
    משמש כדי להציג שמות במקום מזהים.
    """
    _, rows = run_select(sql)
    return [(row[0], str(row[1])) for row in rows]


def fetch_row(table, pk_cols, pk_vals):
    """
    שולף שורה בודדת לפי המפתח הראשי - משמש את מסך העדכון:
    המשתמש מקיש מפתח, והמערכת מביאה את שאר השדות.
    מחזיר dict {שם_עמודה: ערך} או None אם לא נמצאה שורה.
    """
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        where = " AND ".join([f"{c} = %s" for c in pk_cols])
        cur.execute(f"SELECT * FROM {table} WHERE {where}", tuple(pk_vals))
        row = cur.fetchone()
        cur.close()
        return dict(row) if row else None
    finally:
        conn.close()


def insert_row(table, data):
    """מכניס שורה חדשה. data הוא dict של {עמודה: ערך}."""
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        cols = list(data.keys())
        placeholders = ", ".join(["%s"] * len(cols))
        col_list = ", ".join(cols)
        cur = conn.cursor()
        cur.execute(
            f"INSERT INTO {table} ({col_list}) VALUES ({placeholders})",
            tuple(data[c] for c in cols)
        )
        conn.commit()
        cur.close()
    finally:
        conn.close()


def update_row(table, pk_cols, pk_vals, data):
    """מעדכן שורה קיימת לפי המפתח הראשי."""
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        set_cols = [c for c in data.keys() if c not in pk_cols]
        set_clause = ", ".join([f"{c} = %s" for c in set_cols])
        where = " AND ".join([f"{c} = %s" for c in pk_cols])
        values = [data[c] for c in set_cols] + list(pk_vals)
        cur = conn.cursor()
        cur.execute(f"UPDATE {table} SET {set_clause} WHERE {where}", tuple(values))
        affected = cur.rowcount
        conn.commit()
        cur.close()
        return affected
    finally:
        conn.close()


def delete_row(table, pk_cols, pk_vals):
    """מוחק שורה לפי המפתח הראשי. מחזיר מספר שורות שנמחקו."""
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        where = " AND ".join([f"{c} = %s" for c in pk_cols])
        cur = conn.cursor()
        cur.execute(f"DELETE FROM {table} WHERE {where}", tuple(pk_vals))
        affected = cur.rowcount
        conn.commit()
        cur.close()
        return affected
    finally:
        conn.close()


# =============================================================================
# הרצת תתי-תוכניות משלב ד' (פונקציות ופרוצדורות)
# =============================================================================

def call_scalar_function(func_sql, params):
    """
    מזמן פונקציה שמחזירה ערך בודד (כמו calculate_patient_bill).
    func_sql לדוגמה: 'SELECT calculate_patient_bill(%s)'.
    מחזיר את הערך הבודד.
    """
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        cur = conn.cursor()
        cur.execute(func_sql, tuple(params))
        result = cur.fetchone()
        conn.commit()
        cur.close()
        return result[0] if result else None
    finally:
        conn.close()


def call_procedure(call_sql, params):
    """
    מזמן פרוצדורה (CALL ...) ומחזיר את הודעות ה-NOTICE שהיא הפיקה,
    כדי שנוכל להציג למשתמש מה קרה (למשל כמה רופאים קיבלו בונוס).
    """
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        cur = conn.cursor()
        cur.execute(call_sql, tuple(params))
        conn.commit()
        notices = [n.strip() for n in conn.notices]
        cur.close()
        return notices
    finally:
        conn.close()


def fetch_refcursor_function(func_sql, params, cursor_name):
    """
    מזמן פונקציה שמחזירה REFCURSOR (כמו get_department_roster_cursor),
    פותח את הסמן וקורא את כל השורות בתוך טרנזקציה אחת.
    מחזיר (עמודות, שורות).
    """
    conn = get_connection()
    if conn is None:
        raise ConnectionError("לא ניתן להתחבר למסד הנתונים.")
    try:
        cur = conn.cursor()
        # פתיחת הסמן בעזרת קריאה לפונקציה (חייב להיות בתוך טרנזקציה פעילה)
        cur.execute(func_sql, tuple(params))
        cur.execute(f'FETCH ALL IN "{cursor_name}"')
        columns = [desc[0] for desc in cur.description] if cur.description else []
        rows = cur.fetchall()
        conn.commit()
        cur.close()
        return columns, rows
    finally:
        conn.close()
