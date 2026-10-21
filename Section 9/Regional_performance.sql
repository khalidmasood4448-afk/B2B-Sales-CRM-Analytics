SELECT
    s.region_id,
    SUM(f.deal_value) AS total_revenue
FROM FactSales f
JOIN DimSalesRep s
    ON f.sales_rep_sk = s.sales_rep_sk
GROUP BY s.region_id
ORDER BY total_revenue DESC;