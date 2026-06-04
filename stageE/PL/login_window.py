import tkinter as tk
from tkinter import messagebox
from BL.auth_logic import verify_login

def build_login_screen():
    root = tk.Tk()
    root.title("מערכת ניהול בית חולים - Login")
    root.geometry("400x300")
    root.configure(bg="#f0f4f7")

    lbl_title = tk.Label(root, text="🏥 כניסה למערכת בית החולים", font=("Arial", 16, "bold"), bg="#f0f4f7", fg="#2c3e50")
    lbl_title.pack(pady=20)

    frame_form = tk.Frame(root, bg="#f0f4f7")
    frame_form.pack(pady=10)

    lbl_user = tk.Label(frame_form, text="שם משתמש:", font=("Arial", 12), bg="#f0f4f7")
    lbl_user.grid(row=0, column=1, pady=5, padx=5, sticky="e")
    entry_user = tk.Entry(frame_form, font=("Arial", 12), justify="right")
    entry_user.grid(row=0, column=0, pady=5, padx=5)

    lbl_pass = tk.Label(frame_form, text="סיסמה:", font=("Arial", 12), bg="#f0f4f7")
    lbl_pass.grid(row=1, column=1, pady=5, padx=5, sticky="e")
    entry_pass = tk.Entry(frame_form, show="*", font=("Arial", 12), justify="right")
    entry_pass.grid(row=1, column=0, pady=5, padx=5)

    # הוספנו event=None כדי שהפונקציה תדע לקבל את לחיצת האנטר
    def on_login_click(event=None):
        user = entry_user.get()
        pwd = entry_pass.get()
        
        success, message = verify_login(user, pwd)
        
        if success:
            messagebox.showinfo("התחברות מוצלחת", message)
            root.destroy() # סוגר את חלון ה-Login הישן
            
            # ייבוא והפעלת ה-Dashboard החדש
            from PL.dashboard_window import open_dashboard
            open_dashboard(user)
        else:
            messagebox.showerror("שגיאת התחברות", message)

    btn_login = tk.Button(root, text="התחבר", font=("Arial", 12, "bold"), bg="#3498db", fg="white", width=15, command=on_login_click)
    btn_login.pack(pady=20)

    # === התוספות החדשות ===
    # קשירת מקש ה-Enter (Return) לכל החלון, כך שיפעיל את פונקציית ההתחברות
    root.bind('<Return>', on_login_click)
    
    # מיקוד אוטומטי על שדה שם המשתמש עם פתיחת החלון
    entry_user.focus()

    root.mainloop()