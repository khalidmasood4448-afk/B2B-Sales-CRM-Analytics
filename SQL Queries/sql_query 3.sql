-- percentage of opportunities were won

SELECT
    ROUND(
        100.0 * SUM(
            CASE
                WHEN stage = 'Won' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS win_rate_percentage
FROM opportunities;