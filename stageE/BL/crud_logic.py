"""
crud_logic.py - שכבת לוגיקה עסקית עבור פעולות ה-CRUD.

המודול מתווך בין מסך ה-CRUD הגנרי (PL) לבין שכבת הגישה לנתונים (DAL),
ממיר ערכים לטיפוסים הנכונים ומחזיר הודעות שגיאה ידידותיות בעברית.
"""
from DAL import database
from BL.db_metadata import TABLES


def get_table_names():
    """מחזיר רשימת (מפתח_טבלה, תווית) להצגה בתפריט בחירת הטבלה."""
    return [(key, meta["label"]) for key, meta in TABLES.items()]


def get_meta(table_key):
    return TABLES[table_key]


def load_grid(table_key):
    """שולף את כל הנתונים להצגה ברשת (כולל JOIN-ים שמציגים שמות)."""
    meta = TABLES[table_key]
    return database.run_select(meta["select"])


def load_fk_options(column):
    """מחזיר אפשרויות לתיבת בחירה של מפתח זר: רשימת (מזהה, תווית)."""
    if column.get("fk"):
        return database.get_fk_options(column["fk"])
    return []


def _convert(value, ctype):
    """ממיר מחרוזת מהטופס לטיפוס המתאים ל-DB. מחרוזת ריקה -> NULL."""
    if value is None:
        return None
    value = str(value).strip()
    if value == "":
        return None
    if ctype == "int":
        return int(value)
    if ctype == "decimal":
        return float(value)
    # date / timestamp / text מועברים כמחרוזת ו-psycopg2/PostgreSQL ימירו
    return value


def _build_data(meta, raw_values, include_pk=True, skip_auto=True):
    """בונה dict {עמודה: ערך_מומר} מתוך ערכי הטופס הגולמיים."""
    data = {}
    for c in meta["columns"]:
        if c["auto"] and skip_auto:
            continue
        if not include_pk and c["pk"]:
            continue
        if c["name"] in raw_values:
            data[c["name"]] = _convert(raw_values[c["name"]], c["type"])
    return data


def fetch_for_update(table_key, pk_raw_values):
    """
    תהליך העדכון: המשתמש מילא את המפתח -> נביא את שאר השדות.
    מחזיר dict של הערכים הקיימים או None אם לא נמצאה שורה.
    """
    meta = TABLES[table_key]
    pk_vals = []
    for pk in meta["pk"]:
        c = next(col for col in meta["columns"] if col["name"].lower() == pk)
        pk_vals.append(_convert(pk_raw_values[c["name"]], c["type"]))
    return database.fetch_row(table_key, meta["pk"], pk_vals)


def insert(table_key, raw_values):
    meta = TABLES[table_key]
    data = _build_data(meta, raw_values, include_pk=True)
    database.insert_row(table_key, data)


def update(table_key, raw_values):
    meta = TABLES[table_key]
    pk_vals = []
    for pk in meta["pk"]:
        c = next(col for col in meta["columns"] if col["name"].lower() == pk)
        pk_vals.append(_convert(raw_values[c["name"]], c["type"]))
    data = _build_data(meta, raw_values, include_pk=False)
    return database.update_row(table_key, meta["pk"], pk_vals, data)


def delete(table_key, pk_raw_values):
    meta = TABLES[table_key]
    pk_vals = []
    for pk in meta["pk"]:
        c = next(col for col in meta["columns"] if col["name"].lower() == pk)
        pk_vals.append(_convert(pk_raw_values[c["name"]], c["type"]))
    return database.delete_row(table_key, meta["pk"], pk_vals)
