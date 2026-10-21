-- Find opportunities above the average amount
SELECT
    opportunity_id,
    customer_id,
    amount
FROM opportunities
WHERE amount > (
    SELECT AVG(amount)
    FROM opportunities
    WHERE amount_is_invalid = 0
)
AND amount_is_invalid = 0
ORDER BY amount DESC;