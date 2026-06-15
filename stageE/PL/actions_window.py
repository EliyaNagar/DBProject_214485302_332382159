"""
actions_window.py - מסך הפעלת תתי-התוכניות משלב ד' (פונקציות ופרוצדורות).
כל פעולה מציגה טופס פרמטרים קטן, ומריצה את הפונקציה/פרוצדורה במסד הנתונים.
"""
import tkinter as tk
from tkinter import messagebox
from BL import actions_logic
from PL import ui_common as ui


def open_actions_window(parent=None):
    win = tk.Toplevel(parent) if parent else tk.Tk()
    win.title("פעולות מתקדמות - פונקציות ופרוצדורות")
    win.geometry("760x560")
    ui.style_app(win)

    ui.make_header(win, "⚙️ פעולות מתקדמות - פונקציות ופרוצדורות (שלב ד')")

    body = tk.Frame(win, bg=ui.BG)
    body.pack(fill="both", expand=True, padx=20, pady=10)

    out = tk.Text(win, height=8, font=("Consolas", 10), bg="#1e272e", fg="#dff9fb",
                  wrap="word")
    out.pack(fill="x", padx=20, pady=10)

    def log(msg):
        out.insert("end", msg + "\n")
        out.see("end")

    def card(title, desc, color):
        f = tk.Frame(body, bg=ui.CARD, bd=1, relief="solid")
        f.pack(fill="x", pady=6)
        tk.Label(f, text=title, font=(ui.FONT, 12, "bold"), bg=ui.CARD,
                 fg=color).pack(anchor="e", padx=10, pady=(8, 0))
        tk.Label(f, text=desc, font=(ui.FONT, 9), bg=ui.CARD, fg="#555",
                 justify="right").pack(anchor="e", padx=10)
        inner = tk.Frame(f, bg=ui.CARD)
        inner.pack(fill="x", padx=10, pady=8)
        return inner

    def labeled_entry(parent, text, default=""):
        tk.Label(parent, text=text, font=(ui.FONT, 10), bg=ui.CARD).pack(side="right", padx=4)
        e = tk.Entry(parent, font=(ui.FONT, 10), width=12, justify="right")
        e.insert(0, default)
        e.pack(side="right", padx=4)
        return e

    # --- פונקציה 1: חישוב חשבונית מטופל ---
    c1 = card("פונקציה: חישוב חשבונית מטופל", "calculate_patient_bill(patient_id)", ui.ACCENT)
    e_pid = labeled_entry(c1, "מזהה מטופל:", "328308725")

    def run_bill():
        try:
            amount = actions_logic.calculate_patient_bill(e_pid.get())
            log(f"💰 החשבונית של מטופל {e_pid.get()} היא: {amount} ש\"ח")
        except Exception as ex:
            messagebox.showerror("שגיאה", str(ex), parent=win)

    ui.make_button(c1, "חשב", run_bill, ui.ACCENT, 10).pack(side="right", padx=8)

    # --- פונקציה 2: דו"ח צוות מחלקה (REF CURSOR) ---
    c2 = card("פונקציה (REF CURSOR): צוות מחלקה לפי שכר",
              "get_department_roster_cursor(dep_id, min_salary)", ui.ACCENT)
    e_dep = labeled_entry(c2, "מחלקה:", "2")
    e_sal = labeled_entry(c2, "שכר מינ':", "0")

    def run_roster():
        try:
            cols, rows = actions_logic.department_roster(e_dep.get(), e_sal.get())
            log(f"📋 צוות מחלקה {e_dep.get()} (שכר מעל {e_sal.get()}):")
            if not rows:
                log("   (אין עובדים מתאימים)")
            for r in rows:
                log("   " + " | ".join(str(x) for x in r))
        except Exception as ex:
            messagebox.showerror("שגיאה", str(ex), parent=win)

    ui.make_button(c2, "הצג צוות", run_roster, ui.ACCENT, 10).pack(side="right", padx=8)

    # --- פרוצדורה 1: בונוס שכר לרופאים מצטיינים ---
    c3 = card("פרוצדורה: בונוס שכר לרופאים מצטיינים",
              "apply_salary_bonus_by_performance(min_treatments, bonus_percent)", ui.ORANGE)
    e_mt = labeled_entry(c3, "מינ' טיפולים:", "2")
    e_bp = labeled_entry(c3, "אחוז בונוס:", "10")

    def run_bonus():
        try:
            notices = actions_logic.apply_salary_bonus(e_mt.get(), e_bp.get())
            log("✅ הופעלה פרוצדורת הבונוס:")
            for n in notices:
                log("   " + n)
            if not notices:
                log("   הפרוצדורה הסתיימה (ראה השפעה בטבלת ביקורת שכר).")
        except Exception as ex:
            messagebox.showerror("שגיאה", str(ex), parent=win)

    ui.make_button(c3, "הפעל", run_bonus, ui.ORANGE, 10).pack(side="right", padx=8)

    # --- פרוצדורה 2: העברת רופא למחלקה ---
    c4 = card("פרוצדורה: העברת רופא למחלקה אחרת",
              "reassign_doctor_department(doc_id, new_dep_id)", ui.ORANGE)
    e_doc = labeled_entry(c4, "מזהה רופא:", "")
    e_ndep = labeled_entry(c4, "מחלקה חדשה:", "")

    def run_reassign():
        try:
            notices = actions_logic.reassign_doctor(e_doc.get(), e_ndep.get())
            log("✅ הופעלה פרוצדורת ההעברה:")
            for n in notices:
                log("   " + n)
        except Exception as ex:
            messagebox.showerror("שגיאה", str(ex), parent=win)

    ui.make_button(c4, "העבר", run_reassign, ui.ORANGE, 10).pack(side="right", padx=8)

    log("מוכן. בחר פעולה והזן פרמטרים.")

    if parent is None:
        win.mainloop()
