
DROP VIEW IF EXISTS vw_opportunity_enriched;
CREATE VIEW vw_opportunity_enriched AS
SELECT
    o.opportunity_id,
    o.customer_id,
    o.rep_id,
    o.product_id,
    o.stage,
    o.amount,
    o.created_date,
    o.close_date,
    r.rep_name,
    r.region_id,
    reg.region_name,
    CASE
        WHEN o.stage = 'Won'  THEN 'Closed'
        WHEN o.stage = 'Lost' THEN 'Closed'
        ELSE 'Open'
    END AS pipeline_status,
    CASE WHEN o.stage = 'Won' THEN 1 ELSE 0 END AS is_won
FROM opportunities o
LEFT JOIN sales_reps r ON o.rep_id = r.rep_id
LEFT JOIN regions reg ON r.region_id = reg.region_id;


-- ----------------------------------------------------------------------------
-- 1. TOTAL PIPELINE VALUE AND CLOSED REVENUE
--    Pipeline = value of everything still open (Open/Qualified/Proposal/Negotiation).
--    Closed revenue = sum of amount for Won opportunities.
-- ----------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN pipeline_status = 'Open' THEN amount ELSE 0 END) AS total_pipeline_value,
    SUM(CASE WHEN stage = 'Won' THEN amount ELSE 0 END)             AS total_closed_revenue
FROM vw_opportunity_enriched;


-- ----------------------------------------------------------------------------
-- 2. CONVERSION / WIN RATE AND AVERAGE DEAL SIZE
--    Win rate = Won / (Won + Lost)  -- i.e. of decided opportunities, % won.
--    Average deal size computed from the deals table (actual closed value).
-- ----------------------------------------------------------------------------
SELECT
    SUM(is_won) AS won_count,
    SUM(CASE WHEN stage = 'Lost' THEN 1 ELSE 0 END) AS lost_count,
    ROUND(100.0 * SUM(is_won)
        / NULLIF(SUM(CASE WHEN stage IN ('Won','Lost') THEN 1 ELSE 0 END), 0), 2) AS win_rate_pct
FROM vw_opportunity_enriched;

SELECT ROUND(AVG(deal_value), 2) AS avg_deal_size
FROM deals
WHERE deal_value IS NOT NULL;


-- ----------------------------------------------------------------------------
-- 3. SALESPERSON AND REGIONAL PERFORMANCE
--    Aggregation + join across reps/regions/opportunities.
-- ----------------------------------------------------------------------------
-- 3a. Per salesperson
SELECT
    r.rep_id,
    r.rep_name,
    reg.region_name,
    COUNT(o.opportunity_id)                                   AS total_opps,
    SUM(CASE WHEN o.stage = 'Won' THEN 1 ELSE 0 END)          AS won_deals,
    ROUND(SUM(CASE WHEN o.stage = 'Won' THEN o.amount ELSE 0 END), 2) AS revenue_won
FROM sales_reps r
LEFT JOIN opportunities o ON r.rep_id = o.rep_id
LEFT JOIN regions reg ON r.region_id = reg.region_id
GROUP BY r.rep_id, r.rep_name, reg.region_name
ORDER BY revenue_won DESC
LIMIT 20;

-- 3b. Per region
SELECT
    reg.region_id,
    reg.region_name,
    COUNT(o.opportunity_id)                                    AS total_opps,
    ROUND(SUM(CASE WHEN o.stage = 'Won' THEN o.amount ELSE 0 END), 2) AS revenue_won,
    ROUND(100.0 * SUM(CASE WHEN o.stage = 'Won' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN o.stage IN ('Won','Lost') THEN 1 ELSE 0 END), 0), 2) AS win_rate_pct
FROM regions reg
LEFT JOIN sales_reps r ON reg.region_id = r.region_id
LEFT JOIN opportunities o ON r.rep_id = o.rep_id
GROUP BY reg.region_id, reg.region_name
ORDER BY revenue_won DESC;


-- ----------------------------------------------------------------------------
-- 4. OPPORTUNITY STAGE ANALYSIS AND MONTHLY REVENUE TRENDS
-- ----------------------------------------------------------------------------
-- 4a. Stage breakdown
SELECT
    stage,
    COUNT(*)               AS opp_count,
    ROUND(SUM(amount), 2)  AS total_value,
    ROUND(AVG(amount), 2)  AS avg_value
FROM opportunities
GROUP BY stage
ORDER BY opp_count DESC;

-- 4b. Monthly revenue trend (Won opportunities, by close month)
SELECT
    strftime('%Y-%m', close_date) AS close_month,
    COUNT(*)                      AS deals_won,
    ROUND(SUM(amount), 2)         AS monthly_revenue
FROM opportunities
WHERE stage = 'Won' AND close_date IS NOT NULL
GROUP BY close_month
ORDER BY close_month;


-- ----------------------------------------------------------------------------
-- 5. WINDOW FUNCTIONS
-- ----------------------------------------------------------------------------
-- 5a. Rank top salespeople WITHIN EACH REGION by revenue won
--     (RANK() OVER PARTITION BY ... ORDER BY ...)
--     SQLite has no QUALIFY clause, so the rank filter is applied in an
--     outer query instead (Postgres users could use QUALIFY rank <= 3 directly).
WITH rep_revenue AS (
    SELECT
        r.rep_id,
        r.rep_name,
        reg.region_id,
        reg.region_name,
        SUM(CASE WHEN o.stage = 'Won' THEN o.amount ELSE 0 END) AS revenue_won
    FROM sales_reps r
    JOIN regions reg ON r.region_id = reg.region_id
    LEFT JOIN opportunities o ON r.rep_id = o.rep_id
    GROUP BY r.rep_id, r.rep_name, reg.region_id, reg.region_name
),
ranked AS (
    SELECT
        region_name,
        rep_name,
        revenue_won,
        RANK() OVER (PARTITION BY region_id ORDER BY revenue_won DESC) AS rank_in_region
    FROM rep_revenue
)
SELECT region_name, rep_name, ROUND(revenue_won, 2) AS revenue_won, rank_in_region
FROM ranked
WHERE rank_in_region <= 3
ORDER BY region_name, rank_in_region;


-- 5b. Compare periods: month-over-month revenue change using LAG()
WITH monthly AS (
    SELECT
        strftime('%Y-%m', close_date) AS close_month,
        SUM(amount) AS monthly_revenue
    FROM opportunities
    WHERE stage = 'Won' AND close_date IS NOT NULL
    GROUP BY close_month
)
SELECT
    close_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(LAG(monthly_revenue) OVER (ORDER BY close_month), 2) AS prev_month_revenue,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY close_month))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY close_month), 0), 2
    ) AS pct_change_vs_prev_month
FROM monthly
ORDER BY close_month;


-- 5c. Running (cumulative) revenue total across the year — window frame demo
SELECT
    strftime('%Y-%m', close_date) AS close_month,
    ROUND(SUM(amount), 2) AS monthly_revenue,
    ROUND(SUM(SUM(amount)) OVER (ORDER BY strftime('%Y-%m', close_date)
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS running_total_revenue
FROM opportunities
WHERE stage = 'Won' AND close_date IS NOT NULL
GROUP BY close_month
ORDER BY close_month;