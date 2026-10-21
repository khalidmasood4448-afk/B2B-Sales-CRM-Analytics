from pathlib import Path
"""
B2B Sales & CRM Analytics Capstone — PySpark Challenge

Matches the ACTUAL raw dataset columns (as uploaded):
  customers(customer_id, company_name, industry, email, phone, region_id,
            signup_date, is_missing_contact_info)
  sales_reps(rep_id, rep_name, email, region_id, hire_date)
  products(product_id, product_name, category, list_price)
  regions(region_id, region_name, country)
  opportunities(opportunity_id, customer_id, rep_id, product_id, stage,
                 amount, created_date, close_date,
                 [amount_is_invalid], [date_is_invalid])   <- flags optional, see note below
  deals(deal_id, opportunity_id, customer_id, rep_id, deal_value,
        close_date, [deal_value_is_invalid])               <- flag optional
  activities(activity_id, opportunity_id, rep_id, activity_type,
             activity_date, notes)

NOTE ON QUALITY-FLAG COLUMNS
------------------------------
Some copies of this dataset include pre-computed quality flags
(amount_is_invalid, date_is_invalid, deal_value_is_invalid); some don't.
This script checks for each flag column before using it, so it runs
correctly either way:
  - If the flag column exists: flagged values are NULLed out before they
    feed into aggregations (row and flag are both kept).
  - If the flag column is missing: the raw value is used as-is with no
    cleaning applied at this step (you may still want basic sanity filters
    — e.g. amount > 0 — if your Pandas stage didn't already handle this).
"""

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.window import Window

spark = (
    SparkSession.builder
    .appName("B2B_CRM_Capstone_PySpark")
    .config("spark.sql.shuffle.partitions", "8")
    .config("spark.sql.autoBroadcastJoinThreshold", "20mb")
    .getOrCreate()
)

# ---------------------------------------------------------------------------
# Paths — use raw strings (r"...") or forward slashes for Windows paths.
# A normal string like "D:\Data...\customers.csv" is read by Python as
# escape sequences (\D, \C etc aren't valid ones, hence the SyntaxWarning);
# it happens to still resolve on Windows but is fragile — always prefix
# Windows path literals with r" or use forward slashes.
# ---------------------------------------------------------------------------
DATA_DIR = Path(__file__).resolve().parents[2] / "Data" / "Cleaned"
OUTPUT_DIR = Path(__file__).resolve().parents[2] / "Data" / "SparkOutput"

# ---------------------------------------------------------------------------
# 1. Load raw data
# ---------------------------------------------------------------------------
customers = spark.read.csv(f"{DATA_DIR}/customers.csv", header=True, inferSchema=True)
sales_reps = spark.read.csv(f"{DATA_DIR}/sales_reps.csv", header=True, inferSchema=True)
products = spark.read.csv(f"{DATA_DIR}/products.csv", header=True, inferSchema=True)
regions = spark.read.csv(f"{DATA_DIR}/regions.csv", header=True, inferSchema=True)
opportunities = spark.read.csv(f"{DATA_DIR}/opportunities.csv", header=True, inferSchema=True)
deals = spark.read.csv(f"{DATA_DIR}/deals.csv", header=True, inferSchema=True)
activities = spark.read.csv(f"{DATA_DIR}/activities.csv", header=True, inferSchema=True)

print("opportunities columns found:", opportunities.columns)
print("deals columns found:", deals.columns)

opportunities = (
    opportunities
    .withColumn("created_date", F.to_date("created_date"))
    .withColumn("close_date", F.to_date("close_date"))
)
deals = deals.withColumn("close_date", F.to_date("close_date"))
activities = activities.withColumn("activity_date", F.to_date("activity_date"))

# ---------------------------------------------------------------------------
# 2. OPPORTUNITY TRANSFORMATIONS
# ---------------------------------------------------------------------------
# Null out flagged amounts/dates ONLY IF the flag column actually
# exists in this copy of the data — otherwise pass the raw value through
# unchanged. This is what fixes the crash you hit.
has_amount_flag = "amount_is_invalid" in opportunities.columns
has_date_flag = "date_is_invalid" in opportunities.columns

opportunities = opportunities.withColumn(
    "amount_clean",
    F.when(F.col("amount_is_invalid") == False, F.col("amount")) if has_amount_flag
    else F.col("amount")
)
opportunities = opportunities.withColumn(
    "created_date_clean",
    F.when(F.col("date_is_invalid") == False, F.col("created_date")) if has_date_flag
    else F.col("created_date")
)
opportunities = opportunities.withColumn(
    "close_date_clean",
    F.when(F.col("date_is_invalid") == False, F.col("close_date")) if has_date_flag
    else F.col("close_date")
)

if not has_amount_flag:
    print("NOTE: 'amount_is_invalid' not found in this file — amount used as-is, no flag-based cleaning applied.")
if not has_date_flag:
    print("NOTE: 'date_is_invalid' not found in this file — dates used as-is, no flag-based cleaning applied.")

# Standardize stage values defensively (trim/capitalize).
opportunities = opportunities.withColumn(
    "stage_clean", F.initcap(F.trim(F.col("stage")))
)

# Derived fields: pipeline age, win/loss flags.
opportunities = (
    opportunities
    .withColumn(
        "pipeline_age_days",
        F.datediff(
            F.coalesce(F.col("close_date_clean"), F.current_date()),
            F.col("created_date_clean")
        )
    )
    .withColumn("is_won", F.when(F.col("stage_clean") == "Won", 1).otherwise(0))
    .withColumn(
        "is_closed",
        F.when(F.col("stage_clean").isin("Won", "Lost"), 1).otherwise(0)
    )
)

# Enrich with dimensions.
# BROADCAST JOIN: sales_reps, products, regions, and customers are all
# small relative to opportunities — broadcasting avoids shuffling the
# large fact table for what is otherwise a lookup.
opp_enriched = (
    opportunities
    .join(F.broadcast(customers.select("customer_id", "company_name", "industry", "region_id")),
          "customer_id", "left")
    .join(F.broadcast(sales_reps.select(
              F.col("rep_id"), F.col("rep_name"),
              F.col("region_id").alias("rep_region_id"))),
          "rep_id", "left")
    .join(F.broadcast(products.select("product_id", "product_name", "category", "list_price")),
          "product_id", "left")
    .join(F.broadcast(regions), "region_id", "left")
)

# Roll up deals onto opportunities (same defensive flag check).
has_deal_flag = "deal_value_is_invalid" in deals.columns
deals_clean = deals.withColumn(
    "deal_value_clean",
    F.when(F.col("deal_value_is_invalid") == False, F.col("deal_value")) if has_deal_flag
    else F.col("deal_value")
)
if not has_deal_flag:
    print("NOTE: 'deal_value_is_invalid' not found in deals.csv — deal_value used as-is.")

deal_summary = deals_clean.groupBy("opportunity_id").agg(
    F.sum("deal_value_clean").alias("total_deal_value"),
    F.count("deal_id").alias("deal_count")
)
opp_enriched = opp_enriched.join(deal_summary, "opportunity_id", "left")

# Window function: rank each opportunity by amount within its region.
region_window = Window.partitionBy("region_id").orderBy(F.desc("amount_clean"))
opp_enriched = opp_enriched.withColumn("rank_in_region", F.rank().over(region_window))

# ---------------------------------------------------------------------------
# 3. ACTIVITY TRANSFORMATIONS
# ---------------------------------------------------------------------------
activity_agg = activities.groupBy("opportunity_id").agg(
    F.count("activity_id").alias("activity_count"),
    F.max("activity_date").alias("last_activity_date"),
    F.min("activity_date").alias("first_activity_date")
)
activity_agg = activity_agg.withColumn(
    "days_since_last_activity",
    F.datediff(F.current_date(), F.col("last_activity_date"))
)

activity_type_counts = (
    activities.groupBy("opportunity_id")
    .pivot("activity_type")
    .agg(F.count("activity_id"))
    .na.fill(0)
)

# SHUFFLE JOIN: opportunities and activity_agg are both too large to
# broadcast safely — standard sort-merge join on opportunity_id.
final_df = (
    opp_enriched
    .join(activity_agg, "opportunity_id", "left")
    .join(activity_type_counts, "opportunity_id", "left")
)

# ---------------------------------------------------------------------------
# 4. Partition for write
# ---------------------------------------------------------------------------
final_df = final_df.repartition("region_id")

# ---------------------------------------------------------------------------
# 5. explain() — required for viva
# ---------------------------------------------------------------------------
print("\n=== Physical plan: opportunity enrichment (broadcast joins) ===")
opp_enriched.explain(mode="formatted")

print("\n=== Physical plan: final joined dataset (activity shuffle join) ===")
final_df.explain(mode="formatted")

# ---------------------------------------------------------------------------
# 6. Write outputs
# ---------------------------------------------------------------------------
(
    final_df.write
    .mode("overwrite")
    .partitionBy("region_id")
    .parquet(f"{OUTPUT_DIR}/opportunities_transformed")
)
(
    activity_agg.write
    .mode("overwrite")
    .parquet(f"{OUTPUT_DIR}/activity_summary")
)

print("\n=== Row counts ===")
print("opportunities transformed:", final_df.count())
print("activity summary:", activity_agg.count())

print("\n=== Sample business check: total pipeline value & closed revenue ===")
final_df.agg(
    F.sum("amount_clean").alias("total_pipeline_value"),
    F.sum(F.when(F.col("stage_clean") == "Won", F.col("amount_clean"))).alias("closed_won_revenue"),
    F.avg("amount_clean").alias("avg_deal_size"),
    (F.sum("is_won") / F.sum("is_closed")).alias("win_rate")
).show(truncate=False)

print("\n=== Sample: top 5 opportunities by rank in region 1 ===")
final_df.filter(F.col("region_id") == 1).orderBy("rank_in_region").select(
    "opportunity_id", "region_id", "rep_name", "amount_clean", "stage_clean", "rank_in_region"
).show(5, truncate=False)

spark.stop()