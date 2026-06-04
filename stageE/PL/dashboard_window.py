import tkinter as tk
from tkinter import messagebox

def open_dashboard(username):
    # הגדרת החלון הראשי
    dash = tk.Tk()
    dash.title("מערכת ניהול בית חולים - תפריט ראשי")
    dash.geometry("500x400")
    dash.configure(bg="#ecf0f1")

    # כותרת קבלת פנים
    lbl_welcome = tk.Label(dash, text=f"ברוך הבא, {username}!", font=("Arial", 18, "bold"), bg="#ecf0f1", fg="#2c3e50")
    lbl_welcome.pack(pady=20)

    # ---------------------------------------------------------
    # פונקציות זמניות (Placeholders) עד שנבנה את המסכים האמיתיים
    # ---------------------------------------------------------
    def open_crud_screen():
        messagebox.showinfo("בפיתוח", "כאן ייפתח מסך ניהול הנתונים (CRUD)\nמשיכת נתונים, עדכון, הוספה ומחיקה.")

    def open_reports_screen():
        messagebox.showinfo("בפיתוח", "כאן ייפתח מסך הדו\"חות\n(הרצת שאילתות משלב ב').")

    def open_actions_screen():
        messagebox.showinfo("בפיתוח", "כאן ייפתח מסך הפעולות המתקדמות\n(פונקציות ופרוצדורות משלב ד').")

    # ---------------------------------------------------------
    # כפתורי הניווט
    # ---------------------------------------------------------
    btn_crud = tk.Button(dash, text="ניהול מטופלים וצוות (CRUD)", font=("Arial", 14), bg="#3498db", fg="white", width=25, command=open_crud_screen)
    btn_crud.pack(pady=10)

    btn_reports = tk.Button(dash, text="הפקת דו\"חות מערכת (שאילתות)", font=("Arial", 14), bg="#2ecc71", fg="white", width=25, command=open_reports_screen)
    btn_reports.pack(pady=10)

    btn_actions = tk.Button(dash, text="פעולות מתקדמות (פונקציות DB)", font=("Arial", 14), bg="#f39c12", fg="white", width=25, command=open_actions_screen)
    btn_actions.pack(pady=10)

    # כפתור התנתקות שיסגור את התוכנה
    btn_exit = tk.Button(dash, text="התנתק וצא", font=("Arial", 12), bg="#e74c3c", fg="white", width=15, command=dash.destroy)
    btn_exit.pack(pady=30)

    dash.mainloop()