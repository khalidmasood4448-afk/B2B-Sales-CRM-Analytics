
-- =============================================================
--  Data Warehouse Schema
-- =============================================================

CREATE TABLE DimRegion (
    region_sk    INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id    INTEGER NOT NULL UNIQUE,
    region_name  TEXT NOT NULL,
    country      TEXT
);

CREATE TABLE DimDate (
    date_sk      INTEGER PRIMARY KEY,      -- format YYYYMMDD
    full_date    DATE NOT NULL,
    day          INTEGER,
    month        INTEGER,
    quarter      INTEGER,
    year         INTEGER,
    day_name     TEXT,
    is_weekend   BOOLEAN
);

CREATE TABLE DimProduct (
    product_sk   INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id   TEXT NOT NULL UNIQUE,     -- e.g. P1000
    product_name TEXT,
    category     TEXT,
    list_price   NUMERIC
);

CREATE TABLE DimCustomer (
    customer_sk  INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id  INTEGER NOT NULL UNIQUE,
    company_name TEXT,
    industry     TEXT,
    region_sk    INTEGER REFERENCES DimRegion(region_sk)
);

-- Type 2 SCD
-- The same rep_id can have multiple historical versions.
CREATE TABLE DimSalesRep (
    sales_rep_sk        INTEGER PRIMARY KEY AUTOINCREMENT,
    rep_id              INTEGER NOT NULL,
    rep_name            TEXT,
    region_sk           INTEGER REFERENCES DimRegion(region_sk),
    effective_start_date DATE NOT NULL,
    effective_end_date   DATE,             -- NULL = current
    is_current           BOOLEAN NOT NULL DEFAULT 1
);

-- ---------------- FACTS ----------------

-- Grain: one row per opportunity
CREATE TABLE FactOpportunity (
    opportunity_sk    INTEGER PRIMARY KEY AUTOINCREMENT,
    opportunity_id    INTEGER NOT NULL UNIQUE,
    customer_sk       INTEGER REFERENCES DimCustomer(customer_sk),
    sales_rep_sk      INTEGER REFERENCES DimSalesRep(sales_rep_sk),
    product_sk        INTEGER REFERENCES DimProduct(product_sk),
    created_date_sk   INTEGER REFERENCES DimDate(date_sk),
    close_date_sk     INTEGER REFERENCES DimDate(date_sk),
    stage             TEXT,
    amount            NUMERIC,
    pipeline_age_days INTEGER,
    is_won            BOOLEAN,
    is_closed         BOOLEAN,
    activity_count    INTEGER
);

-- Grain: one row per closed deal

CREATE TABLE FactSales (
    sales_sk        INTEGER PRIMARY KEY AUTOINCREMENT,
    deal_id         INTEGER NOT NULL UNIQUE,
    opportunity_id  INTEGER NOT NULL,
    customer_sk     INTEGER REFERENCES DimCustomer(customer_sk),
    sales_rep_sk    INTEGER REFERENCES DimSalesRep(sales_rep_sk),
    product_sk      INTEGER REFERENCES DimProduct(product_sk),
    close_date_sk   INTEGER REFERENCES DimDate(date_sk),
    deal_value      NUMERIC
);

-- ---------------- Example Business Queries ----------------

-- Total pipeline value & win rate
-- SELECT
--     SUM(amount) AS total_pipeline,
--     SUM(is_won) * 1.0 / NULLIF(SUM(is_closed), 0) AS win_rate
-- FROM FactOpportunity;

-- Monthly revenue trend
-- SELECT
--     d.year,
--     d.month,
--     SUM(f.deal_value) AS revenue
-- FROM FactSales f
-- JOIN DimDate d
--     ON f.close_date_