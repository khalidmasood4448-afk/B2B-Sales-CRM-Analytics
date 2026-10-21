from pathlib import Path
import pandas as pd
import sqlite3

CLEAN = Path(__file__).resolve().parents[1] / "Data" / "Cleaned"

DB = Path(__file__).resolve().parents[1] / "Database" / "crm_analytics.db"

conn = sqlite3.connect(DB)

tables = [
    "regions",
    "sales_reps",
    "products",
    "customers",
    "opportunities",
    "deals",
    "activities"
]

for table in tables:

    df = pd.read_csv(f"{CLEAN}\\{table}.csv")

    df.to_sql(
        table,
        conn,
        if_exists="replace",
        index=False
    )

    print(f"Loaded: {table}")

conn.close()

print("\nDatabase created successfully!")
print(DB)