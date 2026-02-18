-- WT-05: Why Is This Query So Slow? — Investigation Queries
-- Work through these in order. Each step narrows the problem.
-- The scenario: fct_revenue_daily is returning inflated numbers AND running slowly.

-- ============================================================
-- STEP 1: Confirm the symptom — row counts don't add up
-- ============================================================

-- How many raw orders do we have?
select count(*) as raw_order_count from raw.raw_orders;
-- Expected: 50

-- How many rows does stg_orders produce?
select count(*) as stg_order_row_count from {{ ref('stg_orders') }};
-- If this is 50: model is correct (1 row per order)
-- If this is > 50: fan-out! (N rows per order = N line items per order)

-- Check the ratio — this is your first signal
select
    (select count(*) from {{ ref('stg_orders') }})::float /
    (select count(*) from raw.raw_orders)
    as fanout_ratio;
-- A ratio of ~1.0 = clean. Ratio > 1 = fan-out = revenue inflation.


-- ============================================================
-- STEP 2: Find the specific orders that are duplicated
-- ============================================================

-- Which order_ids appear more than once in stg_orders?
select
    order_id,
    count(*) as row_count
from {{ ref('stg_orders') }}
group by 1
having count(*) > 1
order by 2 desc
limit 10;

-- Now check those same orders in raw_order_items
-- Do they have multiple line items?
select
    order_id,
    count(*) as item_count
from raw.raw_order_items
group by 1
order by 2 desc
limit 10;

-- Hypothesis: orders with N items → N rows in stg_orders
-- If item_count matches row_count above → fan-out confirmed, source is the stg join


-- ============================================================
-- STEP 3: Quantify the revenue inflation
-- ============================================================

-- What does fct_revenue_daily report as total revenue?
select sum(total_revenue) as reported_revenue from {{ ref('fct_revenue_daily') }};

-- What is the ACTUAL total revenue (from raw, one row per order)?
select sum(amount) as actual_revenue from raw.raw_orders where status = 'completed';

-- The difference is your inflation factor.
-- expected: reported_revenue / actual_revenue ≈ fan-out ratio from step 1

-- Order count inflation check:
select sum(order_count) as reported_orders from {{ ref('fct_revenue_daily') }};
select count(*) as actual_orders from raw.raw_orders where status = 'completed';


-- ============================================================
-- STEP 4: Trace the bug to its source — inspect the join
-- ============================================================

-- Look at stg_orders source code (open models/staging/stg_orders.sql)
-- The bug: stg_orders JOINs raw_order_items inside the staging model.
-- Staging models should be thin wrappers — no joins, no aggregations.
-- The join belongs in an intermediate model if we want line-item detail,
-- or in the mart if we want to enrich order rows with item totals.

-- Confirm: what columns come from raw_orders vs raw_order_items?
-- raw_orders: order_id, customer_id, product_id, order_date, status, amount, region, sales_rep_id
-- raw_order_items: item_id, order_id, product_id, quantity, unit_price, discount_pct

-- The join adds item_id, quantity, unit_price, discount_pct to each order row.
-- But since an order can have multiple items → 1 order row becomes N item rows.


-- ============================================================
-- STEP 5: Assess blast radius — what else reads stg_orders?
-- ============================================================

-- In a real project: dbt ls --select stg_orders+
-- For this walkthrough, we know from the DAG:
--   stg_orders → fct_orders (enriched orders)
--   stg_orders → fct_revenue_daily (daily aggregation)
-- Both are materialized as tables → both are serving dashboards with wrong numbers.

-- Check fct_orders for fan-out symptoms:
select
    order_id,
    count(*) as row_count
from {{ ref('fct_orders') }}
group by 1
having count(*) > 1
order by 2 desc;
-- If rows > 0: fct_orders is also affected

-- Total downstream exposure:
-- Revenue dashboard → inflated totals (fct_revenue_daily)
-- Order detail view → duplicated order rows (fct_orders)
