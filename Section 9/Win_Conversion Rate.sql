SELECT
    SUM(CASE WHEN stage = 'Won' THEN 1 ELSE 0 END) * 100.0
    / NULLIF(SUM(CASE WHEN stage NOT IN ('Open', 'Lost') THEN 1 ELSE 0 END), 0)
    AS win_rate_percent
FROM opportunities;