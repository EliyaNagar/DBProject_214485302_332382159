import psycopg2


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