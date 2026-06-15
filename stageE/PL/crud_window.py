"""
crud_window.py - מסך גנרי לניהול כל הטבלאות (שליפה, הוספה, עדכון, מחיקה).

מסך אחד משרת את כל 14 הטבלאות בעזרת המטא-דאטה שב-BL/db_metadata.py.
- ברשת מוצגים שמות ידידותיים במקום מזהים (בעזרת JOIN-ים).
- בטפסים, מפתחות זרים מיוצגים בתיבת בחירה של שמות (ולא הקלדת מספר).
- בעדכון: המשתמש מקיש את המפתח, לוחץ "טען", והמערכת מביאה את שאר השדות.
"""
import tkinter as tk
from tkinter import ttk, messagebox
from BL import crud_logic
from PL import ui_common as ui


class FormDialog:
    """חלון טופס מודאלי לעריכת רשומה. מחזיר dict של ערכים גולמיים, או None."""

    def __init__(self, parent, title, columns, prefill=None, lock_pk=False):
        self.result = None
        self.columns = columns
        self.widgets = {}
        self.fk_maps = {}  # שם עמודה -> {תווית: מזהה}

        self.top = tk.Toplevel(parent)
        self.top.title(title)
        self.top.configure(bg=ui.BG)
        self.top.grab_set()
        self.top.resizable(False, False)

        tk.Label(self.top, text=title, font=(ui.FONT, 14, "bold"),
                 bg=ui.BG, fg=ui.PRIMARY).grid(row=0, column=0, columnspan=2, pady=12)

        for i, c in enumerate(columns, start=1):
            tk.Label(self.top, text=c["label"] + ":", font=(ui.FONT, 11), bg=ui.BG,
                     anchor="e").grid(row=i, column=1, sticky="e", padx=8, pady=5)
            widget = self._build_widget(c, prefill, lock_pk)
            widget.grid(row=i, column=0, padx=8, pady=5, sticky="we")
            self.widgets[c["name"]] = widget

        btns = tk.Frame(self.top, bg=ui.BG)
        btns.grid(row=len(columns) + 1, column=0, columnspan=2, pady=15)
        ui.make_button(btns, "שמור", self._on_save, ui.GREEN, 12).pack(side="left", padx=6)
        ui.make_button(btns, "ביטול", self.top.destroy, ui.RED, 12).pack(side="left", padx=6)

        self.top.wait_window()

    def _build_widget(self, c, prefill, lock_pk):
        existing = None
        if prefill:
            # ה-prefill מגיע מ-DB עם שמות עמודות באותיות קטנות
            existing = prefill.get(c["name"].lower(), prefill.get(c["name"]))

        if c.get("fk"):
            options = crud_logic.load_fk_options(c)  # [(value, label)]
            label_to_val = {label: val for val, label in options}
            self.fk_maps[c["name"]] = label_to_val
            cb = ttk.Combobox(self.top, values=list(label_to_val.keys()),
                              state="readonly", font=(ui.FONT, 11), width=28)
            if existing is not None:
                for val, label in options:
                    if str(val) == str(existing):
                        cb.set(label)
                        break
            return cb

        if c.get("options"):
            cb = ttk.Combobox(self.top, values=c["options"], state="readonly",
                              font=(ui.FONT, 11), width=28)
            if existing is not None:
                cb.set(str(existing))
            return cb

        entry = tk.Entry(self.top, font=(ui.FONT, 11), width=30, justify="right")
        if existing is not None:
            entry.insert(0, str(existing))
        if lock_pk and c["pk"]:
            entry.config(state="readonly")  # אסור לשנות מפתח ראשי בעדכון
        return entry

    def _get_value(self, c):
        w = self.widgets[c["name"]]
        if c["name"] in self.fk_maps:  # FK combobox - החזרת המזהה ולא התווית
            label = w.get()
            return self.fk_maps[c["name"]].get(label, "")
        return w.get()

    def _on_save(self):
        values = {c["name"]: self._get_value(c) for c in self.columns}
        # ולידציה בסיסית: שדות חובה (מפתח ראשי) לא ריקים
        for c in self.columns:
            if c["pk"] and not c["auto"] and str(values[c["name"]]).strip() == "":
                messagebox.showwarning("שדה חסר", f"חובה למלא את שדה המפתח: {c['label']}",
                                       parent=self.top)
                return
        self.result = values
        self.top.destroy()


def open_crud_window(parent=None):
    win = tk.Toplevel(parent) if parent else tk.Tk()
    win.title("ניהול נתונים - CRUD")
    win.geometry("1000x600")
    ui.style_app(win)

    ui.make_header(win, "🗄️ ניהול נתונים - כל הטבלאות (הוספה / עדכון / מחיקה / שליפה)")

    # ----- בחירת טבלה -----
    top_bar = tk.Frame(win, bg=ui.BG)
    top_bar.pack(fill="x", padx=10, pady=8)

    tk.Label(top_bar, text="בחר טבלה:", font=(ui.FONT, 12, "bold"),
             bg=ui.BG).pack(side="right", padx=6)

    tables = crud_logic.get_table_names()
    table_labels = [label for _, label in tables]
    label_to_key = {label: key for key, label in tables}

    table_cb = ttk.Combobox(top_bar, values=table_labels, state="readonly",
                            font=(ui.FONT, 11), width=40)
    table_cb.pack(side="right", padx=6)
    table_cb.current(0)

    tree = ui.build_grid(win)

    def current_key():
        return label_to_key[table_cb.get()]

    def refresh():
        try:
            cols, rows = crud_logic.load_grid(current_key())
            ui.fill_grid(tree, cols, rows)
        except Exception as e:
            messagebox.showerror("שגיאה בשליפת נתונים", str(e), parent=win)

    def do_insert():
        key = current_key()
        meta = crud_logic.get_meta(key)
        cols = [c for c in meta["columns"] if not c["auto"]]
        dlg = FormDialog(win, f"הוספת רשומה - {meta['label']}", cols)
        if dlg.result is None:
            return
        try:
            crud_logic.insert(key, dlg.result)
            messagebox.showinfo("הצלחה", "הרשומה נוספה בהצלחה.", parent=win)
            refresh()
        except Exception as e:
            messagebox.showerror("שגיאה בהוספה", str(e), parent=win)

    def do_update():
        key = current_key()
        meta = crud_logic.get_meta(key)
        # שלב 1: בקשת המפתח בלבד
        pk_cols = [c for c in meta["columns"] if c["pk"]]
        key_dlg = FormDialog(win, f"עדכון - הזן מפתח של {meta['label']}", pk_cols)
        if key_dlg.result is None:
            return
        # שלב 2: שליפת שאר השדות מה-DB
        try:
            row = crud_logic.fetch_for_update(key, key_dlg.result)
        except Exception as e:
            messagebox.showerror("שגיאה", str(e), parent=win)
            return
        if not row:
            messagebox.showwarning("לא נמצא", "לא נמצאה רשומה עם המפתח שהוזן.", parent=win)
            return
        # שלב 3: טופס עריכה מלא, מפתח נעול
        edit_dlg = FormDialog(win, f"עדכון רשומה - {meta['label']}",
                              meta["columns"], prefill=row, lock_pk=True)
        if edit_dlg.result is None:
            return
        try:
            crud_logic.update(key, edit_dlg.result)
            messagebox.showinfo("הצלחה", "הרשומה עודכנה בהצלחה.", parent=win)
            refresh()
        except Exception as e:
            messagebox.showerror("שגיאה בעדכון", str(e), parent=win)

    def do_delete():
        key = current_key()
        meta = crud_logic.get_meta(key)
        pk_cols = [c for c in meta["columns"] if c["pk"]]
        key_dlg = FormDialog(win, f"מחיקה - הזן מפתח של {meta['label']}", pk_cols)
        if key_dlg.result is None:
            return
        if not messagebox.askyesno("אישור מחיקה",
                                   "האם אתה בטוח שברצונך למחוק את הרשומה?", parent=win):
            return
        try:
            affected = crud_logic.delete(key, key_dlg.result)
            if affected:
                messagebox.showinfo("הצלחה", "הרשומה נמחקה בהצלחה.", parent=win)
            else:
                messagebox.showwarning("לא נמצא", "לא נמצאה רשומה למחיקה.", parent=win)
            refresh()
        except Exception as e:
            messagebox.showerror("שגיאה במחיקה", str(e), parent=win)

    # ----- כפתורי פעולה -----
    actions = tk.Frame(win, bg=ui.BG)
    actions.pack(fill="x", padx=10, pady=8)
    ui.make_button(actions, "🔄 רענן / שלוף", refresh, ui.ACCENT).pack(side="right", padx=5)
    ui.make_button(actions, "➕ הוסף", do_insert, ui.GREEN).pack(side="right", padx=5)
    ui.make_button(actions, "✏️ עדכן", do_update, ui.ORANGE).pack(side="right", padx=5)
    ui.make_button(actions, "🗑️ מחק", do_delete, ui.RED).pack(side="right", padx=5)

    table_cb.bind("<<ComboboxSelected>>", lambda e: refresh())
    refresh()

    if parent is None:
        win.mainloop()
