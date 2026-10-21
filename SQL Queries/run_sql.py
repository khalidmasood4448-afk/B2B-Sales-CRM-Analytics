from pathlib import Path

import sqlite3

# Database location
DB = Path(__file__).resolve().parents[1] / "Database" / "crm_analytics.db"

# SQL file location
SQL_FILE = r"D:\Data Engineering Internship Projects and query\Python Projects\CAPSTONE CHALLENGE\Task 3\step3.sql"


# Connect to database
conn = sqlite3.connect(DB)


# Open SQL file
with open(SQL_FILE, "r", encoding="utf-8") as file:
    sql_script = file.read()


# Run SQL script
conn.executescript(sql_script)


print("SQL script executed successfully!")


# Close database connection
conn.close()