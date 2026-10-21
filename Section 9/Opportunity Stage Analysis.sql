SELECT
    stage,
    COUNT(*) AS opportunity_count,
    SUM(amount) AS total_value
FROM opportunities
GROUP BY stage
ORDER BY total_value DESC;