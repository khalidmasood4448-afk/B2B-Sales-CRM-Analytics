from pathlib import Path
import sqlite3

DB = Path(__file__).resolve().parents[1] / "Database" / "crm_analytics.db"

conn = sqlite3.connect(DB)

cursor = conn.cursor()

cursor.execute("""
SELECT name
FROM sqlite_master
WHERE type='table';
""")

tables = cursor.fetchall()

for table in tables:
    print(table[0])

conn.close()