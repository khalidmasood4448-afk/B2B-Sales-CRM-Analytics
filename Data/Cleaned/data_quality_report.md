# Data Quality Profiling & Cleaning Report

```
All raw files loaded successfully.

--- SALES REPS ---
Rows: 2000
Missing values:
rep_id        0
rep_name      0
email         0
region_id    59
hire_date     0
dtype: int64
Invalid region IDs: 15

--- CUSTOMERS ---
Rows: 30300
Missing values:
customer_id        0
company_name     301
industry        1216
email           1809
phone           2421
region_id          0
signup_date        0
dtype: int64
Duplicate customers removed: 4011

--- OPPORTUNITIES ---
Rows: 152500
Missing values:
opportunity_id       0
customer_id        405
rep_id             711
product_id           0
stage                0
amount            1221
created_date         0
close_date         905
dtype: int64
Duplicate opportunities removed: 2500
Invalid opportunity amounts: 2679
Invalid opportunity dates: 6145
Invalid opportunity rep IDs: 150

--- DEALS ---
Rows: 29824
Missing values:
deal_id             0
opportunity_id      0
customer_id        77
rep_id            153
deal_value        522
close_date        158
dtype: int64
Duplicate deals removed: 10953
Invalid deal values: 693

--- ACTIVITIES ---
Rows: 500000
Missing values:
activity_id            0
opportunity_id         0
rep_id              3000
activity_type          0
activity_date          0
notes             150204
dtype: int64

--- SAVING CLEANED DATA ---
Saved: regions.csv
Saved: sales_reps.csv
Saved: products.csv
Saved: customers.csv
Saved: opportunities.csv
Saved: deals.csv
Saved: activities.csv
```
