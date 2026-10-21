# Section 7 — Data Warehouse Design (Star Schema)

## Design decision: two fact tables, not one

The business questions split naturally into two grains, so this design uses
**both** `FactOpportunity` and `FactSales` rather than forcing everything
into one table:

- **Pipeline questions** (total pipeline value, win rate, stage analysis,
  pipeline age) need one row per *opportunity*, including open ones.
- **Revenue questions** (closed revenue, avg deal size, monthly revenue
  trends) need one row per *closed deal transaction* — an opportunity can
  have zero, one, or (per the raw `deals.csv`) occasionally more than one
  deal record.

Cramming both into a single fact table would force nulls across half the
measures depending on row type, and would double-count pipeline value if a
deal has multiple payment/transaction rows. Two fact tables sharing the same
conformed dimensions is the cleaner Kimball-style answer.

---

## FactOpportunity

**Grain: one row per opportunity** (every opportunity, open or closed).

| Column | Type | Notes |
|---|---|---|
| `opportunity_sk` | INT, PK | Surrogate key |
| `opportunity_id` | INT | Degenerate dimension — natural key, kept for traceability/drill-back to source |
| `customer_sk` | INT, FK → DimCustomer | |
| `sales_rep_sk` | INT, FK → DimSalesRep | Points at the rep version active when the opportunity was created |
| `product_sk` | INT, FK → DimProduct | |
| `created_date_sk` | INT, FK → DimDate | |
| `close_date_sk` | INT, FK → DimDate, nullable | NULL while opportunity is still open |
| `stage` | VARCHAR | Kept as a plain attribute (small, stable value set: Open/Qualified/Proposal/Negotiation/Won/Lost) rather than its own dimension — not worth a join for 6 fixed values |
| **`amount`** | DECIMAL | Measure — pipeline value of this opportunity |
| **`pipeline_age_days`** | INT | Measure — days opportunity has been open (or was open before closing) |
| **`is_won`** | BOOLEAN | Measure — 1/0 flag, sums directly into win-rate calcs |
| **`is_closed`** | BOOLEAN | Measure — 1/0 flag |
| **`activity_count`** | INT | Measure — from the PySpark activity rollup |

## FactSales

**Grain: one row per deal (closed transaction).**

| Column | Type | Notes |
|---|---|---|
| `sales_sk` | INT, PK | Surrogate key |
| `deal_id` | INT | Degenerate dimension — natural key |
| `opportunity_id` | INT | Degenerate dimension — links back to the originating opportunity *by value*, not by FK (facts don't reference other facts in Kimball design) |
| `customer_sk` | INT, FK → DimCustomer | |
| `sales_rep_sk` | INT, FK → DimSalesRep | Points at the rep version active when the deal closed — this is the FK that makes the SCD Type 2 design from Section 8 pay off |
| `product_sk` | INT, FK → DimProduct | |
| `close_date_sk` | INT, FK → DimDate | |
| **`deal_value`** | DECIMAL | Measure — actual closed revenue |

---

## Dimensions

### DimCustomer
`customer_sk` (PK) · `customer_id` (natural key) · `company_name` · `industry` · `region_sk` (FK → DimRegion)
— Type 1 (overwrite). Customer attributes here (industry, name) aren't
being asked to preserve history; only the sales rep's region assignment is.

### DimSalesRep (Type 2 — see Section 8)
`sales_rep_sk` (PK) · `rep_id` (natural key) · `rep_name` · `region_sk` (FK) · `effective_start_date` · `effective_end_date` · `is_current`

### DimProduct
`product_sk` (PK) · `product_id` (natural key) · `product_name` · `category` · `list_price`
— Type 1. If price history mattered for margin analysis this would become
Type 2 too, but that's out of scope for this assignment's business questions.

### DimRegion
`region_sk` (PK) · `region_id` (natural key) · `region_name` · `country`

### DimDate
`date_sk` (PK, format YYYYMMDD) · `full_date` · `day` · `month` · `quarter` · `year` · `day_name` · `is_weekend`
— Standard conformed date dimension, shared by both facts via `created_date_sk`/`close_date_sk`.

---

## Why this satisfies the business questions

| Business question | Answered from |
|---|---|
| Total pipeline value | `SUM(FactOpportunity.amount)` |
| Closed revenue | `SUM(FactSales.deal_value)` |
| Win/conversion rate | `SUM(is_won) / SUM(is_closed)` on FactOpportunity |
| Avg deal size | `AVG(FactSales.deal_value)` |
| Salesperson/regional performance | Join either fact to DimSalesRep → DimRegion |
| Opportunity stage analysis | `GROUP BY stage` on FactOpportunity |
| Monthly revenue trends | Join FactSales to DimDate, `GROUP BY year, month` |
| Rep performance across a region move | DimSalesRep Type 2 keeps old/new region split correctly (Section 8) |

See `dw_star_schema.mermaid` for the visual schema and
`dw_schema.sql` for runnable DDL.
