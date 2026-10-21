--Total Pipeline Value

SELECT
    SUM(amount) AS total_pipeline_value
FROM opportunities
WHERE amount_is_invalid = 0;