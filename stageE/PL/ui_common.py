"""
ui_common.py - רכיבי תצוגה משותפים לכל המסכים (עיצוב אחיד וידידותי).
"""
import tkinter as tk
from tkinter import ttk

# פלטת צבעים אחידה למערכת
BG = "#eef2f5"
CARD = "#ffffff"
PRIMARY = "#2c3e50"
ACCENT = "#3498db"
GREEN = "#27ae60"
ORANGE = "#f39c12"
RED = "#e74c3c"
FONT = "Arial"


def style_app(root):
    """מגדיר עיצוב אחיד ל-ttk (כותרות רשת, גופנים)."""
    root.configure(bg=BG)
    style = ttk.Style()
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass
    style.configure("Treeview", font=(FONT, 10), rowheight=26, background=CARD,
                    fieldbackground=CARD)
    style.configure("Treeview.Heading", font=(FONT, 10, "bold"),
                    background=PRIMARY, foreground="white")
    style.map("Treeview", background=[("selected", ACCENT)])


def make_header(parent, text):
    """כותרת עליונה אחידה למסך."""
    bar = tk.Frame(parent, bg=PRIMARY)
    bar.pack(fill="x")
    tk.Label(bar, text=text, font=(FONT, 16, "bold"), bg=PRIMARY, fg="white",
             pady=12).pack()
    return bar


def make_button(parent, text, command, color=ACCENT, width=18):
    return tk.Button(parent, text=text, command=command, font=(FONT, 11, "bold"),
                     bg=color, fg="white", width=width, relief="flat",
                     cursor="hand2", pady=4)


def build_grid(parent):
    """בונה Treeview עם פסי גלילה ומחזיר את ה-Treeview."""
    frame = tk.Frame(parent, bg=BG)
    frame.pack(fill="both", expand=True, padx=10, pady=10)

    tree = ttk.Treeview(frame, show="headings")
    vsb = ttk.Scrollbar(frame, orient="vertical", command=tree.yview)
    hsb = ttk.Scrollbar(frame, orient="horizontal", command=tree.xview)
    tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    hsb.grid(row=1, column=0, sticky="ew")
    frame.rowconfigure(0, weight=1)
    frame.columnconfigure(0, weight=1)
    return tree


def fill_grid(tree, columns, rows):
    """ממלא את הרשת בעמודות ובשורות שהתקבלו מה-DB."""
    tree.delete(*tree.get_children())
    tree["columns"] = columns
    for c in columns:
        tree.heading(c, text=c)
        tree.column(c, width=140, anchor="center")
    for i, row in enumerate(rows):
        tag = "even" if i % 2 == 0 else "odd"
        tree.insert("", "end", values=[("" if v is None else v) for v in row], tags=(tag,))
    tree.tag_configure("odd", background="#f4f8fb")
    tree.tag_configure("even", background="#ffffff")
