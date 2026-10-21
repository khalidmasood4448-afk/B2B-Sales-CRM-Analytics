# Section 8 — Historical Data / SCD Business Case

## Business Case
A salesperson moves from one sales region to another. Historical deals must
remain associated with the previous region; new deals must use the new
region.

## Decision: SCD Type 2 on DimSalesRep

| Type | What it does | Why it's wrong/right here |
|---|---|---|
| Type 1 (overwrite) | Update `region_id` in place | **Wrong** — silently rewrites history; every past deal by this rep would appear to have always belonged to the new region. |
| Type 2 (new row + effective dates) | Expire the old row, insert a new row | **Correct** — preserves the old region on old rows, gives new deals a distinct key for the new region. |
| Type 3 (add "previous value" column) | Add `previous_region_id` | Rejected — only stores one prior value, doesn't scale to a rep moving regions multiple times, and doesn't tell you *when* deals should switch over. |

Type 2 is the only option that satisfies "historical deals must remain
associated with the previous region" without any date-based patching logic
at query time.

## DimSalesRep (Type 2) Schema

```
sales_rep_sk        INT         PRIMARY KEY   -- surrogate key, changes each version
rep_id              INT                       -- natural/business key, stable across versions
rep_name            VARCHAR
email               VARCHAR
region_id           INT                       -- FK to DimRegion, THE versioned attribute
region_name         VARCHAR
effective_start_date DATE
effective_end_date   DATE        NULL         -- NULL = currently active
is_current           BOOLEAN
```

## Fact Table Rule
`FactOpportunity` / `FactSales` store **`sales_rep_sk`** (the surrogate key),
never the natural `rep_id` directly. This is the mechanism that makes the
history "just work": each fact row is permanently bound to whichever
DimSalesRep version was current when that deal was loaded/closed. No
as-of-date joins are needed at query time — the correct region is already
baked into the row.

## Worked Example

**Before the move** — Rep 487 in Region 12:

| sales_rep_sk | rep_id | region_id | effective_start_date | effective_end_date | is_current |
|---|---|---|---|---|---|
| 501 | 487 | 12 | 2023-01-15 | NULL | True |

Deals closed against this rep before the move load with `sales_rep_sk = 501`.

**Rep 487 moves to Region 7 on 2026-03-01.** ETL process:
1. `UPDATE DimSalesRep SET effective_end_date = '2026-02-28', is_current = False WHERE sales_rep_sk = 501`
2. `INSERT` a new row for `rep_id = 487` with `region_id = 7`, `effective_start_date = '2026-03-01'`, `is_current = True` → gets new surrogate key `812`.

**After the move:**

| sales_rep_sk | rep_id | region_id | effective_start_date | effective_end_date | is_current |
|---|---|---|---|---|---|
| 501 | 487 | 12 | 2023-01-15 | 2026-02-28 | False |
| 812 | 487 | 7  | 2026-03-01 | NULL       | True |

- Deals closed **before** 2026-03-01 already have `sales_rep_sk = 501` → report against Region 12. Untouched.
- Deals closed **on/after** 2026-03-01 get loaded with `sales_rep_sk = 812` → report against Region 7.
- `SELECT ... FROM FactSales f JOIN DimSalesRep d ON f.sales_rep_sk = d.sales_rep_sk WHERE d.rep_id = 487` returns **both** versions — correct for "all of this person's history," while filtering `d.is_current = True` gives you just their current assignment.

## Loading Logic (ETL / PySpark or SQL, run on each batch)
1. Compare incoming `sales_reps` snapshot to current `DimSalesRep` rows (`is_current = True`) on `rep_id`.
2. Where `region_id` differs → expire the old row (`effective_end_date`, `is_current = False`) and insert a new row with a new surrogate key.
3. Where `rep_id` is new → insert as a fresh current row.
4. Fact-table loads always look up the *current* `sales_rep_sk` for the rep_id at the time the source deal/opportunity record was created — this is what fixes the correct dimension version onto each fact row permanently.

See `scd_type2_implementation.sql` for a runnable version of this logic.
