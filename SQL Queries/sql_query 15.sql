-- Calculate revenue change from the previous month
WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', close_date) AS revenue_month,
        SUM(deal_value) AS revenue
    FROM deals
    WHERE deal_value_is_invalid = 0
    GROUP BY revenue_month
),
revenue_comparison AS (
    SELECT
        revenue_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY revenue_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    revenue_month,
    revenue,
    previous_month_revenue,
    ROUND(
        revenue - previous_month_revenue,
        2
    ) AS revenue_change
FROM revenue_comparison
ORDER BY revenue_month;