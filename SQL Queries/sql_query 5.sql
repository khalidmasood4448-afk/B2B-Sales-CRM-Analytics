--Salesperson Performance
-- Show each salesperson

SELECT
    rep_id,

   
    COUNT(*) AS number_of_deals,
    SUM(deal_value) AS total_revenue,
    ROUND(AVG(deal_value), 2) AS average_deal_size

FROM deals

WHERE deal_value_is_invalid = 0

GROUP BY rep_id

ORDER BY total_revenue DESC;