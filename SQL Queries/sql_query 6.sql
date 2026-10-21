-- Compare regional performance
SELECT
    r.region_name,
    COUNT(d.deal_id) AS number_of_deals,
    SUM(d.deal_value) AS total_revenue,
    ROUND(AVG(d.deal_value), 2) AS average_deal_size
FROM deals AS d
JOIN sales_reps AS s
    ON d.rep_id = s.rep_id
JOIN regions AS r
    ON s.region_id = r.region_id
WHERE d.deal_value_is_invalid = 0
GROUP BY r.region_id, r.region_name
ORDER BY total_revenue DESC;