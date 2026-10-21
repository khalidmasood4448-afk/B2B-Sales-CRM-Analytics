-- Analyze opportunities by sales stage
SELECT
    stage,
    COUNT(*) AS opportunity_count,
    SUM(amount) AS total_opportunity_value
FROM opportunities
WHERE amount_is_invalid = 0
GROUP BY stage
ORDER BY total_opportunity_value DESC;