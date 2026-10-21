from pathlib import Path
import pandas as pd
import numpy as np
import os

# 1. PATHS

RAW = Path(__file__).resolve().parents[1] / "Data" / "Raw"

CLEAN = Path(__file__).resolve().parents[1] / "Data" / "Cleaned"

os.makedirs(CLEAN, exist_ok=True)

report = []

def log(message):
    print(message)
    report.append(message)

# 2. LOAD DATA

regions = pd.read_csv(f"{RAW}/regions.csv")
reps = pd.read_csv(f"{RAW}/sales_reps.csv")
products = pd.read_csv(f"{RAW}/products.csv")
customers = pd.read_csv(f"{RAW}/customers.csv")
opportunities = pd.read_csv(f"{RAW}/opportunities.csv")
deals = pd.read_csv(f"{RAW}/deals.csv")
activities = pd.read_csv(f"{RAW}/activities.csv")

log("All raw files loaded successfully.")

# 3. CONVERT DATE COLUMNS

opportunities["created_date"] = pd.to_datetime(
    opportunities["created_date"], errors="coerce"
)

opportunities["close_date"] = pd.to_datetime(
    opportunities["close_date"], errors="coerce"
)

deals["close_date"] = pd.to_datetime(
    deals["close_date"], errors="coerce"
)

activities["activity_date"] = pd.to_datetime(
    activities["activity_date"], errors="coerce"
)

customers["signup_date"] = pd.to_datetime(
    customers["signup_date"], errors="coerce"
)

reps["hire_date"] = pd.to_datetime(
    reps["hire_date"], errors="coerce"
)

# 4. SALES REPS

log("\n--- SALES REPS ---")

reps_clean = reps.copy()

log(f"Rows: {len(reps_clean)}")
log(f"Missing values:\n{reps_clean.isnull().sum()}")

valid_regions = regions["region_id"]

invalid_region = (
    ~reps_clean["region_id"].isin(valid_regions)
    & reps_clean["region_id"].notna()
)

log(f"Invalid region IDs: {invalid_region.sum()}")

reps_clean.loc[invalid_region, "region_id"] = np.nan

reps_clean["region_id"] = reps_clean["region_id"].astype("Int64")

# 5. CUSTOMERS

log("\n--- CUSTOMERS ---")

customers_clean = customers.copy()

log(f"Rows: {len(customers_clean)}")
log(f"Missing values:\n{customers_clean.isnull().sum()}")

before = len(customers_clean)

customers_clean = customers_clean.drop_duplicates(
    subset=["company_name", "email"],
    keep="first"
)

log(f"Duplicate customers removed: {before - len(customers_clean)}")

customers_clean["company_name"] = (
    customers_clean["company_name"]
    .fillna("UNKNOWN COMPANY")
)

customers_clean["is_missing_contact_info"] = (
    customers_clean["email"].isnull()
    | customers_clean["phone"].isnull()
)

# 6. OPPORTUNITIES

log("\n--- OPPORTUNITIES ---")

opps_clean = opportunities.copy()

log(f"Rows: {len(opps_clean)}")
log(f"Missing values:\n{opps_clean.isnull().sum()}")

before = len(opps_clean)

opps_clean = opps_clean.drop_duplicates()

log(f"Duplicate opportunities removed: {before - len(opps_clean)}")


# Standardize stages

stage_map = {
    "open": "Open",
    "qualified": "Qualified",
    "proposal": "Proposal",
    "proposal sent": "Proposal",
    "negotiation": "Negotiation",
    "in negotiation": "Negotiation",
    "won": "Won",
    "closed won": "Won",
    "closed-won": "Won",
    "lost": "Lost",
    "closed lost": "Lost",
    "closed-lost": "Lost"
}

opps_clean["stage"] = (
    opps_clean["stage"]
    .str.strip()
    .str.lower()
    .map(stage_map)
)

# Check invalid amounts

opps_clean["amount_is_invalid"] = (
    opps_clean["amount"].isnull()
    | (opps_clean["amount"] <= 0)
    | (opps_clean["amount"] > 1000000)
)

log(
    f"Invalid opportunity amounts: "
    f"{opps_clean['amount_is_invalid'].sum()}"
)

opps_clean.loc[
    opps_clean["amount_is_invalid"],
    "amount"
] = np.nan

# Check invalid dates

closed = opps_clean["stage"].isin(["Won", "Lost"])

opps_clean["date_is_invalid"] = (
    opps_clean["close_date"].isnull()
    | (opps_clean["close_date"] < opps_clean["created_date"])
    | (
        closed
        & (opps_clean["close_date"] > pd.Timestamp.today())
    )
)

log(
    f"Invalid opportunity dates: "
    f"{opps_clean['date_is_invalid'].sum()}"
)

opps_clean.loc[
    opps_clean["date_is_invalid"],
    "close_date"
] = pd.NaT

# Validate rep IDs

opps_clean["rep_id"] = opps_clean["rep_id"].astype("Int64")
opps_clean["customer_id"] = opps_clean["customer_id"].astype("Int64")

invalid_rep = (
    ~opps_clean["rep_id"].isin(reps["rep_id"])
    & opps_clean["rep_id"].notna()
)

log(f"Invalid opportunity rep IDs: {invalid_rep.sum()}")

opps_clean.loc[invalid_rep, "rep_id"] = pd.NA

# 7. DEALS

log("\n--- DEALS ---")

deals_clean = deals.copy()

log(f"Rows: {len(deals_clean)}")
log(f"Missing values:\n{deals_clean.isnull().sum()}")

before = len(deals_clean)

deals_clean = deals_clean.drop_duplicates(
    subset=["opportunity_id"],
    keep="first"
)

log(f"Duplicate deals removed: {before - len(deals_clean)}")


# Check invalid deal values

deals_clean["deal_value_is_invalid"] = (
    deals_clean["deal_value"].isnull()
    | (deals_clean["deal_value"] < 0)
)

log(
    f"Invalid deal values: "
    f"{deals_clean['deal_value_is_invalid'].sum()}"
)

deals_clean.loc[
    deals_clean["deal_value_is_invalid"],
    "deal_value"
] = np.nan

# 8. ACTIVITIES

log("\n--- ACTIVITIES ---")

activities_clean = activities.copy()

log(f"Rows: {len(activities_clean)}")
log(f"Missing values:\n{activities_clean.isnull().sum()}")

activities_clean["rep_id"] = (
    activities_clean["rep_id"].astype("Int64")
)

# 9. SAVE CLEANED DATA

log("\n--- SAVING CLEANED DATA ---")

cleaned_data = {
    "regions": regions,
    "sales_reps": reps_clean,
    "products": products,
    "customers": customers_clean,
    "opportunities": opps_clean,
    "deals": deals_clean,
    "activities": activities_clean
}

for name, df in cleaned_data.items():

    df.to_csv(
        f"{CLEAN}/{name}.csv",
        index=False
    )

    log(f"Saved: {name}.csv")

# 10. SAVE DATA QUALITY REPORT

report_path = f"{CLEAN}/data_quality_report.md"

with open(report_path, "w", encoding="utf-8") as file:

    file.write("# Data Quality Profiling & Cleaning Report\n\n")

    file.write("```\n")

    file.write("\n".join(report))

    file.write("\n```\n")

# DONE

print("\n========================================")
print("DATA CLEANING COMPLETED")
print("========================================")
print(f"Cleaned files saved in:\n{CLEAN}")
print(f"Report saved in:\n{report_path}")