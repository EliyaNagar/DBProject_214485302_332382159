import tkinter as tk
from PL import ui_common as ui
from PL.crud_window import open_crud_window
from PL.reports_window import open_reports_window
from PL.actions_window import open_actions_window


def open_dashboard(username):
    # הגדרת החלון הראשי - תפריט ניווט לכל מסכי המערכת
    dash = tk.Tk()
    dash.title("מערכת ניהול בית חולים - תפריט ראשי")
    dash.geometry("560x520")
    ui.style_app(dash)

    ui.make_header(dash, "🏥 מערכת ניהול בית חולים")

    tk.Label(dash, text=f"ברוך הבא, {username}!", font=(ui.FONT, 16, "bold"),
             bg=ui.BG, fg=ui.PRIMARY).pack(pady=18)

    tk.Label(dash, text="בחר מסך מהתפריט:", font=(ui.FONT, 11),
             bg=ui.BG, fg="#555").pack()

    btns = tk.Frame(dash, bg=ui.BG)
    btns.pack(pady=20)

    ui.make_button(btns, "🗄️  ניהול נתונים (CRUD)",
                   lambda: open_crud_window(dash), ui.ACCENT, 30).pack(pady=8)
    ui.make_button(btns, "📊  דו\"חות ושאילתות (שלב ב')",
                   lambda: open_reports_window(dash), ui.GREEN, 30).pack(pady=8)
    ui.make_button(btns, "⚙️  פעולות מתקדמות (שלב ד')",
                   lambda: open_actions_window(dash), ui.ORANGE, 30).pack(pady=8)

    ui.make_button(dash, "🚪 התנתק וצא", dash.destroy, ui.RED, 16).pack(pady=30)

    dash.mainloop()
