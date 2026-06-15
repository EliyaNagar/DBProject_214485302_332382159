"""
reports_window.py - מסך הרצת שאילתות משלב ב'.
המשתמש בוחר שאילתה מהרשימה ולוחץ "הרץ" - התוצאות מוצגות ברשת.
"""
import tkinter as tk
from tkinter import ttk, messagebox
from BL import reports_logic
from PL import ui_common as ui


def open_reports_window(parent=None):
    win = tk.Toplevel(parent) if parent else tk.Tk()
    win.title("דו\"חות ושאילתות")
    win.geometry("1000x600")
    ui.style_app(win)

    ui.make_header(win, "📊 דו\"חות מערכת - הרצת שאילתות (שלב ב')")

    reports = reports_logic.get_reports()
    labels = [label for _, label, _, _ in reports]
    label_to_key = {label: key for key, label, _, _ in reports}
    desc_by_key = {key: desc for key, _, desc, _ in reports}

    top = tk.Frame(win, bg=ui.BG)
    top.pack(fill="x", padx=10, pady=8)
    tk.Label(top, text="בחר שאילתה:", font=(ui.FONT, 12, "bold"),
             bg=ui.BG).pack(side="right", padx=6)
    cb = ttk.Combobox(top, values=labels, state="readonly", font=(ui.FONT, 11), width=45)
    cb.pack(side="right", padx=6)
    cb.current(0)

    desc_lbl = tk.Label(win, text="", font=(ui.FONT, 10, "italic"), bg=ui.BG, fg="#555")
    desc_lbl.pack(anchor="e", padx=20)

    tree = ui.build_grid(win)

    def update_desc(*_):
        desc_lbl.config(text=desc_by_key[label_to_key[cb.get()]])

    def run():
        key = label_to_key[cb.get()]
        try:
            cols, rows = reports_logic.run_report(key)
            ui.fill_grid(tree, cols, rows)
            if not rows:
                messagebox.showinfo("אין תוצאות", "השאילתה לא החזירה שורות.", parent=win)
        except Exception as e:
            messagebox.showerror("שגיאה בהרצת השאילתה", str(e), parent=win)

    ui.make_button(top, "▶️ הרץ שאילתה", run, ui.GREEN).pack(side="right", padx=10)
    cb.bind("<<ComboboxSelected>>", update_desc)
    update_desc()

    if parent is None:
        win.mainloop()
