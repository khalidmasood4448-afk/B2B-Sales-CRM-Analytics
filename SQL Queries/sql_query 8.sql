-- Monthly revenue
SELECT
    strftime('%Y-%m', close_date) AS revenue_month,
    SUM(deal_value) AS monthly_revenue
FROM deals
WHERE deal_value_is_invalid = 0
GROUP BY revenue_month
ORDER BY revenue_month;