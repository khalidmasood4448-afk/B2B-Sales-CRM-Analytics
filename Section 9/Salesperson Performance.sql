SELECT
    s.rep_name,
    SUM(d.deal_value) AS total_revenue
FROM deals d
JOIN sales_reps s
    ON d.rep_id = s.rep_id
WHERE d.deal_value_is_invalid = 0
GROUP BY s.rep_id, s.rep_name
ORDER BY total_revenue DESC;