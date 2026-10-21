-- Compare monthly revenue with the previous month
WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', close_date) AS revenue_month,
        SUM(deal_value) AS revenue
    FROM deals
    WHERE deal_value_is_invalid = 0
    GROUP BY revenue_month
)
SELECT
    revenue_month,
    revenue,
    LAG(revenue) OVER (
        ORDER BY revenue_month
    ) AS previous_month_revenue
FROM monthly_revenue
ORDER BY revenue_month;