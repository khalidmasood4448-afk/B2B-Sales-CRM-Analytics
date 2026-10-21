# B2B Sales & CRM Analytics

A data engineering and analytics capstone that processes CRM datasets with Python, SQLite, PySpark, SQL, and dimensional data warehouse design. The project covers data quality checks, database loading, distributed transformations, star schema modeling, Slowly Changing Dimension (SCD) Type 2, and sales-focused business analysis.

## Project Overview

The project works with CRM data about customers, sales representatives, products, opportunities, deals, regions, and sales activities. Its goal is to turn raw CSV files into cleaner datasets and useful analytical outputs, then document how a dimensional warehouse can support sales and pipeline reporting.

## Project Requirements and Implementation

| Requirement | Implementation |
|---|---|
| Clean and validate raw CRM CSVs | `Python Code/clean_data.py` checks data quality, applies selected cleaning rules, writes cleaned CSVs, and produces a quality report. |
| Load cleaned data into SQLite | `Python Code/create_database.py` loads cleaned datasets into SQLite tables. |
| Verify database tables | `Python Code/test_database.py` lists tables in the configured SQLite database. |
| Transform CRM data with PySpark | `Pyspark/PySpark_Script/pyspark_transformations.py` parses dates, derives opportunity metrics, joins related datasets, summarizes activities, and writes Parquet outputs. |
| Design a dimensional warehouse | `Data Warehouse Design/dw_design.md`, `dw_schema.sql`, and `dw_star_schema.mermaid` document the star schema and table definitions. |
| Preserve salesperson history | `SCD Type 2/scd_design.md` explains the business case; `scd_type2_implementation.sql` demonstrates a Type 2 history example. |
| Analyze sales and pipeline performance | `Section 9/` contains KPI queries for deal size, revenue trends, opportunity stages, regional and salesperson performance, pipeline value, and conversion. |
| Connect findings to business actions | `Section 9/3 Business Recommendations.md` records recommendations; `Section 10/Real-World Business Value.md` describes the potential business value. |
| Keep supporting SQL exercises | `SQL Queries/` contains `run_sql.py`, `step3.sql`, and `sql_query 1.sql` through `sql_query 15.sql`. |

## Data Workflow

1. **Raw data:** Original CRM CSV files are stored in `Data/Raw/`.
2. **Data cleaning:** Run `Python Code/clean_data.py`. Cleaned CSVs and `data_quality_report.md` are written to `Data/Cleaned/`.
3. **SQLite loading:** Run `Python Code/create_database.py` to load the cleaned CSVs into SQLite.
4. **Database verification:** Run `Python Code/test_database.py` to list the available tables.
5. **PySpark transformation:** Run the PySpark script after installing and configuring a compatible Java runtime and PySpark environment. It reads `Data/Cleaned/` and writes generated Parquet outputs under `Data/SparkOutput/`.
6. **Warehouse design and analysis:** Review the proposed fact and dimension tables, SCD Type 2 example, and SQL analytics.

## Main Data Entities

| File | Description |
|---|---|
| `customers.csv` | Customer and company attributes |
| `sales_reps.csv` | Sales representative information and regional assignments |
| `products.csv` | Product attributes |
| `regions.csv` | Region information |
| `opportunities.csv` | Sales pipeline opportunities |
| `deals.csv` | Deal/revenue records |
| `activities.csv` | CRM activity history |

## Data Warehouse Design

The proposed star schema separates pipeline analysis from closed-deal revenue using two fact tables and shared dimensions.

- **`FactOpportunity`**: one row per opportunity, including open and closed opportunities. It supports pipeline value, stage analysis, opportunity age, and win/conversion calculations.
- **`FactSales`**: one row per closed deal/transaction. It supports closed revenue, average deal size, and revenue trends.
- **Dimensions:** `DimCustomer`, `DimSalesRep`, `DimProduct`, `DimRegion`, and `DimDate` provide descriptive context for analysis.

`DimSalesRep` is designed for **SCD Type 2**. When a sales representative changes region, the previous dimension version is expired and a new version is inserted with a new surrogate key. Fact rows should retain the appropriate dimension key to preserve historical reporting.

## Business Questions Covered

The included SQL analysis is intended to address questions such as:

- What is the total value of the sales pipeline?
- How much revenue was generated from closed deals?
- What is the average deal size?
- How does revenue change month by month?
- How many opportunities and how much value are in each stage?
- Which regions and sales representatives generate the most revenue?
- What is the win/conversion rate?
- What actions could improve follow-up and reduce lost opportunities?

## Repository Structure

```text
B2B-Sales-CRM-Analytics/
├── .gitignore
├── README.md
├── Data/
│   ├── Raw/                         # Original CRM CSVs
│   └── Cleaned/                     # Cleaned CSVs and quality report
├── Data Warehouse Design/           # Warehouse documentation, DDL, and Mermaid diagram
├── Pyspark/
│   ├── PySpark_Script/              # PySpark transformation script
│   └── CSV's/                       # Output preview CSVs
├── Python Code/                     # Cleaning, database loading, and database-check scripts
├── SCD Type 2/                      # SCD Type 2 design, SQL example, and verification output
├── Section 9/                       # KPI queries and business recommendations
├── Section 10/                      # Real-world business value notes
└── SQL Queries/                     # Additional SQL exercises and helper script
```

**Generated files are not committed to GitHub:** `.gitignore` excludes local SQLite database files (`*.db`, `*.sqlite`, `*.sqlite3`) and generated `Data/SparkOutput/`. These files can be recreated locally by running the appropriate scripts. The CSV preview files in `Pyspark/CSV's/` are included as examples.

## Setup and Execution

### Requirements

- Python 3.10+ (or a compatible version)
- `pandas` and `numpy` for data cleaning
- `pyspark` for Spark transformations
- SQLite support (included with Python)
- A Java runtime compatible with the installed PySpark version

Install the Python packages from the project root:

```bash
python -m pip install pandas numpy pyspark
```

### Suggested execution order

Run the following commands from the repository root. On Windows PowerShell, quote paths containing spaces as shown.

1. **Create the database output directory** (the folder is not tracked because generated database files are ignored):

   ```powershell
   New-Item -ItemType Directory -Force Database
   ```

2. **Clean the raw data:**

   ```powershell
   python "Python Code/clean_data.py"
   ```

3. **Load the cleaned datasets into SQLite:**

   ```powershell
   python "Python Code/create_database.py"
   ```

4. **Verify the SQLite tables:**

   ```powershell
   python "Python Code/test_database.py"
   ```

5. **Run the PySpark transformations** after Java/Spark are configured:

   ```powershell
   python "Pyspark/PySpark_Script/pyspark_transformations.py"
   ```

6. Review the SQL and warehouse design files. Run each SQL query only against a database whose tables and column names match that query.

## Validation Notes and Known Follow-up Work

The Python scripts were checked for syntax errors with `py_compile` after their path variables were updated to use paths relative to the project. This confirms Python syntax only; the full pipeline has **not** been rerun end-to-end from a fresh clone.

A few SQL and schema consistency items still need attention before the project can be described as fully reproducible:

1. **Warehouse DDL example:** `Data Warehouse Design/dw_schema.sql` ends with an incomplete commented monthly-revenue example. Finish the example or remove the unfinished comment lines.
2. **SCD Type 2 alignment:** The SCD design/implementation refers to columns such as `email` and `region_id`, while the warehouse DDL uses `region_sk` and does not define `email`. Align the implementation and DDL before running them together.
3. **Monthly revenue query:** `Section 9/Monthly Revenue Trends.sql` applies `strftime` to `close_date_sk`, which is a date surrogate key in the proposed warehouse. Join `FactSales` to `DimDate` and group by calendar year/month instead.
4. **Regional revenue query:** `Section 9/Regional_performance.sql` references `DimSalesRep.region_id`, which is not defined in the provided warehouse DDL. Join `DimRegion` through `DimSalesRep.region_sk` to return the region identifier or name.
5. **Query table targets:** Some KPI queries use source-style tables such as `deals` and `opportunities`; others use warehouse tables such as `FactSales` and `FactOpportunity`. Run each query against its intended schema or standardize the query set.
6. **Schema verification query:** `Data Warehouse Design/SELECT name.sql` checks for warehouse table names in SQLite's `sqlite_master`; its results depend on whether those tables have actually been created in the database being inspected.

## Business Recommendations

The recommendation notes in `Section 9/3 Business Recommendations.md` focus on improving follow-up for open and qualified opportunities, reviewing practices in stronger regions and sales teams, and investigating causes of lost opportunities. Validate the underlying KPI outputs before using specific figures or presenting these as confirmed business conclusions.

## Privacy Note

Before publishing or sharing the repository, confirm that the raw and cleaned CSV files contain only synthetic, public, or otherwise authorized data. Do not publish personal customer information, confidential business data, credentials, API keys, or other secrets.

## Project Summary

**Project:** B2B Sales & CRM Analytics — Data Engineering Capstone

This repository demonstrates a practical combination of data cleaning, Python/SQLite, PySpark transformations, dimensional modeling, SCD Type 2 concepts, SQL-based sales analysis, and business interpretation. Remaining SQL and schema consistency items are documented above so the project's current status is transparent.
