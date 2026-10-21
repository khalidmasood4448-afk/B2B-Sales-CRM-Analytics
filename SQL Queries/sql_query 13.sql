-- Rank salespeople within each region

WITH salesperson_revenue AS (
    SELECT
        s.rep_id,
        s.rep_name,
        r.region_name,
        SUM(d.deal_value) AS total_revenue
    FROM deals AS d
    JOIN sales_reps AS s
        ON d.rep_id = s.rep_id
    JOIN regions AS r
        ON s.region_id = r.region_id
    WHERE d.deal_value_is_invalid = 0
    GROUP BY
        s.rep_id,
        s.rep_name,
        r.region_name
)
SELECT
    rep_id,
    rep_name,
    region_name,
    total_revenue,
    RANK() OVER (
        PARTITION BY region_name
        ORDER BY total_revenue DESC
    ) AS regional_rank
FROM salesperson_revenue
ORDER BY region_name, regional_rank;