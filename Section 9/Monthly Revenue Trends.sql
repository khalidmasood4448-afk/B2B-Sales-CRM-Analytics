SELECT
    strftime('%Y-%m', close_date_sk) AS month,
    SUM(deal_value) AS monthly_revenue
FROM FactSales
GROUP BY month
ORDER BY month;