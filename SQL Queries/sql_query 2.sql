-- Closed Revenue

SELECT
    SUM(deal_value) AS closed_revenue
FROM deals
WHERE deal_value_is_invalid = 0;