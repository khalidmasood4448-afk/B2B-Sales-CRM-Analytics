-- Section 8 — Slowly Changing Dimension (SCD) 


-- =============================================================
-- PART 1 — INITIAL SALES REPRESENTATIVE VERSION
-- =============================================================
-- Jamie Baird initially belongs to Region 12.

INSERT INTO DimSalesRep
(
    rep_id,
    rep_name,
    email,
    region_id,
    effective_start_date,
    effective_end_date,
    is_current
)
VALUES
(
    487,
    'Jamie Baird',
    'jamie.baird@example.com',
    12,
    '2023-01-15',
    NULL,
    1
);


-- =============================================================
-- PART 2 — INITIAL SALES
-- =============================================================
-- These sales belong to the original Region 12 version.

INSERT INTO FactSales
(
    opportunity_id,
    sales_rep_sk,
    deal_value,
    close_date
)
SELECT
    9001,
    sales_rep_sk,
    15000,
    '2024-06-10'
FROM DimSalesRep
WHERE rep_id = 487
  AND is_current = 1;


INSERT INTO FactSales
(
    opportunity_id,
    sales_rep_sk,
    deal_value,
    close_date
)
SELECT
    9002,
    sales_rep_sk,
    22000,
    '2025-11-02'
FROM DimSalesRep
WHERE rep_id = 487
  AND is_current = 1;


-- =============================================================
-- PART 3 — SCD TYPE 2 UPDATE
-- =============================================================
-- Jamie Baird moves from Region 12 to Region 7.
-- The old record is NOT deleted.
-- It is expired and marked as historical.


UPDATE DimSalesRep
SET
    effective_end_date = '2026-02-28',
    is_current = 0
WHERE rep_id = 487
  AND is_current = 1;


-- Create a new version for the new region.

INSERT INTO DimSalesRep
(
    rep_id,
    rep_name,
    email,
    region_id,
    effective_start_date,
    effective_end_date,
    is_current
)
VALUES
(
    487,
    'Jamie Baird',
    'jamie.baird@example.com',
    7,
    '2026-03-01',
    NULL,
    1
);


-- =============================================================
-- PART 4 — NEW SALE USING CURRENT SCD VERSION
-- =============================================================
-- This new sale uses the new sales_rep_sk for Region 7.

INSERT INTO FactSales
(
    opportunity_id,
    sales_rep_sk,
    deal_value,
    close_date
)
SELECT
    9003,
    sales_rep_sk,
    30500,
    '2026-04-15'
FROM DimSalesRep
WHERE rep_id = 487
  AND is_current = 1;


-- =============================================================
-- PART 5 — VERIFICATION 1: SCD HISTORY
-- =============================================================
-- Shows both historical and current versions.

SELECT
    sales_rep_sk,
    rep_id,
    rep_name,
    region_id,
    effective_start_date,
    effective_end_date,
    is_current
FROM DimSalesRep
WHERE rep_id = 487
ORDER BY effective_start_date;


-- =============================================================
-- PART 6 — VERIFICATION 2: HISTORICAL SALES ATTRIBUTION
-- =============================================================
-- Confirms that old sales remain connected to Region 12
-- while the new sale is connected to Region 7.

SELECT
    f.opportunity_id,
    f.close_date,
    f.deal_value,
    d.rep_id,
    d.rep_name,
    d.region_id,
    d.effective_start_date,
    d.effective_end_date
FROM FactSales f
JOIN DimSalesRep d
    ON f.sales_rep_sk = d.sales_rep_sk
ORDER BY f.close_date;


-- =============================================================
-- PART 7 — VERIFICATION 3: CURRENT RECORD
-- =============================================================
-- Shows only the currently active SCD version.

SELECT
    rep_id,
    rep_name,
    region_id,
    effective_start_date,
    effective_end_date,
    is_current
FROM DimSalesRep
WHERE rep_id = 487
  AND is_current = 1;
