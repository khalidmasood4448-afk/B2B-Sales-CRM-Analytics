-- Create a view for valid closed deals
CREATE VIEW IF NOT EXISTS valid_closed_deals AS
SELECT
    deal_id,
    opportunity_id,
    customer_id,
    rep_id,
    deal_value,
    close_date
FROM deals
WHERE deal_value_is_invalid = 0;

-- View the results
SELECT *
FROM valid_closed_deals;