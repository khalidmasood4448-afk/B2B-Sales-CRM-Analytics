# B2B Sales & CRM Analytics

A data engineering and analytics capstone project that transforms raw CRM data into clean datasets, SQLite tables, PySpark outputs, a dimensional warehouse design, and business-focused sales insights.

## Project Overview

The project analyzes customers, sales representatives, products, opportunities, deals, regions, and sales activities. It demonstrates a practical data workflow: data quality checks, database loading, distributed transformations, dimensional modeling, historical tracking with Slowly Changing Dimension (SCD) Type 2, and SQL-based KPI analysis.

## Project Requirements and What Has Been Implemented

| Requirement | Implementation in this repository |
|---|---|
| Clean and validate the source CRM CSV files | `Python Code/clean_data.py` reads the raw CSVs, checks data quality, standardizes selected values, and writes cleaned CSVs plus a quality report. |
| Load cleaned data into a database | `Python Code/create_database.py` loads the cleaned CSV datasets into SQLite tables. |
| Verify database creation | `Python Code/test_database.py` lists the tables in the SQLite database. |
| Transform data with PySpark | `Pyspark/PySpark_Script/pyspark_transformations.py` processes CRM data, derives useful fields, joins datasets, summarizes activities, and writes Parquet outputs. |
| Design a star-schema warehouse | `Data Warehouse Design/dw_design.md`, `dw_schema.sql`, and `dw_star_schema.mermaid` document the warehouse model and table definitions. |
| Preserve salesperson region history | `SCD Type 2/scd_design.md` explains the business case; `scd_type2_implementation.sql` demonstrates the Type 2 versioning process. |
| Answer sales and pipeline questions with SQL | `Section 9/` contains queries for deal size, monthly revenue, opportunity stages, regional and salesperson performance, pipeline value, and win conversion. |
| Translate the analysis into business actions | `Section 9/3 Business Recommendations.md` records recommendations based on the analysis. `Scetion 10/Real-World Business Value.md` covers the business value. |
| Keep additional SQL exercises and supporting material | `SQL Queries/` contains `run_sql.py`, `step3.sql`, and `sql_query 1.sql` through `sql_query 15.sql`. |

## Data Workflow

1. **Raw data:** CSVs are stored under `Data/Raw/`.
2. **Data cleaning:** `clean_data.py` applies quality checks and writes cleaned files under `Data/Cleaned/` along with `data_quality_report.md`.
3. **Database loading:** `create_database.py` loads cleaned datasets into SQLite. `test_database.py` can be used to inspect the available tables.
4. **Distributed processing:** The PySpark script reads the cleaned datasets, parses dates, handles quality flags where available, derives opportunity metrics, joins related entities, summarizes activities, and writes Parquet outputs under `Data/SparkOutput/`.
5. **Warehouse modeling:** The design separates opportunity pipeline measures from closed-deal revenue using `FactOpportunity` and `FactSales`, supported by shared dimensions.
6. **Analysis:** SQL queries calculate sales and pipeline KPIs; the recommendations documents connect these metrics to possible business actions.

## Main Data Entities

The source files cover:

- `customers.csv` — customer and company information
- `sales_reps.csv` — salesperson information and regional assignment
- `products.csv` — product attributes
- `regions.csv` — region information
- `opportunities.csv` — sales pipeline opportunities
- `deals.csv` — closed-deal/revenue records
- `activities.csv` — CRM activity history

## Data Warehouse Design

The proposed star schema uses two fact tables with shared dimensions:

- **`FactOpportunity`**: one row per opportunity, including open and closed opportunities. Supports pipeline value, stage analysis, opportunity age, and win-conversion calculations.
- **`FactSales`**: one row per deal/closed transaction. Supports closed revenue, average deal size, and revenue trends.
- **Dimensions**: `DimCustomer`, `DimSalesRep`, `DimProduct`, `DimRegion`, and `DimDate` provide descriptive context for analysis.

`DimSalesRep` is designed for **SCD Type 2** history. When a salesperson's region changes, the previous dimension version is expired and a new version is inserted with a new surrogate key. Fact rows retain the dimension key associated with their historical assignment.

## Business Questions Covered

The included SQL analysis is intended to answer questions such as:

- What is the total value of the sales pipeline?
- How much revenue was generated from closed deals?
- What is the average deal size?
- How does revenue trend month by month?
- How many opportunities and how much value exist at each stage?
- Which regions and salespeople generate the most revenue?
- What is the win/conversion rate?
- How should the business investigate lost opportunities and improve follow-ups?

## Repository Guide

```text
CAPSTONE CHALLENGE_B2B Sales & CRM Analytics/
├── Data/
│   ├── Raw/                       # Original CRM CSVs
│   ├── Cleaned/                   # Cleaned CSVs and data quality report
│   ├── SparkOutput/               # PySpark Parquet outputs
│   └── crm_analytics.db           # SQLite database file
├── Database/                      # Additional database artifact
├── Data Warehouse Design/         # Star schema design, DDL, and Mermaid ER diagram
├── Python Code/                   # Cleaning, database loading, database test scripts
├── Pyspark/
│   ├── PySpark_Script/             # PySpark transformations
│   └── CSV's/                     # Output preview CSVs
├── SCD Type 2/                    # Type 2 design and SQL example
├── Section 9/                     # KPI queries and business recommendations
├── Scetion 10/                    # Real-world business value notes
└── SQL Queries/                   # Additional SQL query exercises and helper script
```

## Setup and Execution

### Requirements

- Python 3.10+ (or a compatible Python version)
- `pandas` and `numpy` for data cleaning
- `pyspark` for Spark transformations
- SQLite support (included with Python)
- A Java runtime compatible with the installed PySpark version

Install the Python packages used by the main scripts:

```bash
pip install pandas numpy pyspark
```

### Suggested execution order

1. Review the source files under `Data/Raw/`.
2. Run `Python Code/clean_data.py` to create the cleaned datasets and quality report.
3. Run `Python Code/create_database.py` to load cleaned datasets into SQLite.
4. Run `Python Code/test_database.py` to check which tables were created.
5. Run the PySpark transformation script when Spark and Java are configured.
6. Review the warehouse design and execute the SQL files against a database whose schema matches the query.

> **Important before running:** The reviewed Python and PySpark scripts currently contain hard-coded paths pointing to an older folder named `CAPSTONE CHALLENGE`. Update these paths to the current project directory or replace them with paths derived from the script location. The scripts may not run from a fresh clone until this is corrected.

## Final Validation Notes

The main project assets and documentation are present, but the repository still needs a final consistency check before it should be described as fully reproducible:

1. **Path consistency:** Update the hard-coded paths in the cleaning, database, and PySpark scripts.
2. **Warehouse SQL:** `Data Warehouse Design/dw_schema.sql` ends with an incomplete commented monthly-revenue example. Finish the example or remove the incomplete lines.
3. **SCD Type 2 alignment:** The SCD design/implementation refers to columns such as `email` and `region_id`, while the warehouse DDL models the representative's region using `region_sk` and does not define `email`. Align the DDL and implementation before executing them together.
4. **Monthly revenue query:** `Section 9/Monthly Revenue Trends.sql` groups by `close_date_sk`, which is a date surrogate key in the proposed warehouse. Join `FactSales` to `DimDate` and group by the calendar year/month instead.
5. **Regional revenue query:** `Section 9/Regional_performance.sql` should join `DimRegion` through `DimSalesRep.region_sk` to obtain the region identifier/name.
6. **Query target tables:** Some KPI queries reference source-style tables such as `deals` and `opportunities`, while others use warehouse tables such as `FactSales` and `FactOpportunity`. Run each query against the database/schema it was written for, or standardize the queries on one model.
7. **Database artifacts:** Check whether `Data/crm_analytics.db` and `Database/crm_analytics.db` are duplicates or represent different stages, and keep the intended one(s) in the repository.

These items are identified from a review of the available files; the complete project has not yet been rerun end-to-end in a clean environment.

## Expected Outcomes

- Cleaned CRM data files and a data-quality report
- SQLite tables for querying the cleaned datasets
- Partitioned Parquet outputs from PySpark transformations
- A documented dimensional model and SCD Type 2 design
- SQL queries for sales and pipeline KPIs
- Practical recommendations linked to the analysis

## Author / Project Context

**Project:** B2B Sales & CRM Analytics — Data Engineering Capstone

This repository demonstrates data cleaning, Python/SQLite, PySpark transformations, dimensional modeling, historical dimension handling, SQL analytics, and business interpretation in one end-to-end project.
