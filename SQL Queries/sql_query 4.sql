-- Average value of a closed deal

SELECT
    ROUND(AVG(deal_value), 2) AS average_deal_size
FROM deals
WHERE deal_value_is_invalid = 0;