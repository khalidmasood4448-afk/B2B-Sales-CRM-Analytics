-- Categorize opportunities by amount
SELECT
    opportunity_id,
    amount,
    CASE
        WHEN amount >= 100000 THEN 'Large'
        WHEN amount >= 50000 THEN 'Medium'
        ELSE 'Small'
    END AS opportunity_size
FROM opportunities
WHERE amount_is_invalid = 0;