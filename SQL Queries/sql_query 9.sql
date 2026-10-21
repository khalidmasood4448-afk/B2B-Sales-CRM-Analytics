-- Join opportunities with deals
SELECT
    o.opportunity_id,
    o.customer_id,
    o.rep_id,
    o.stage,
    o.amount,
    d.deal_value,
    d.close_date
FROM opportunities AS o
JOIN deals AS d
    ON o.opportunity_id = d.opportunity_id;