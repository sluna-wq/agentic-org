-- WT-05: Why Is This Query So Slow? — Reference Solution
-- The fix: restructure stg_orders to be a clean one-row-per-order model.
-- Move line-item detail to a separate stg_order_items model.
-- Update fct_orders to enrich from both, correctly.

-- ============================================================
-- FIX 1: stg_orders — remove the join, clean orders only
-- Replace models/staging/stg_orders.sql with this:
-- ============================================================

/*
-- models/staging/stg_orders.sql (FIXED)
with source as (
    select * from {{ source('raw', 'raw_orders') }}
)

select
    order_id,
    customer_id,
    product_id,
    order_date::date    as order_date,
    status,
    amount,
    region,
    sales_rep_id
from source
*/

-- WHY: staging models should be thin wrappers.
-- One source table → one staging model. No joins. No aggregations.
-- This keeps grain correct (1 row per order) and keeps staging fast + reusable.


-- ============================================================
-- FIX 2: stg_order_items — new staging model for line items
-- Create models/staging/stg_order_items.sql:
-- ============================================================

/*
-- models/staging/stg_order_items.sql (NEW)
with source as (
    select * from {{ source('raw', 'raw_order_items') }}
)

select
    item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_pct,
    -- Compute line item total here, once, correctly
    round(quantity * unit_price * (1 - discount_pct), 2) as line_total
from source
*/

-- WHY: line items are a separate grain from orders. They belong in their own model.
-- Downstream models can join when they need item detail, but most don't.


-- ============================================================
-- FIX 3: fct_orders — enrich orders with correct item totals
-- Update models/marts/fct_orders.sql:
-- ============================================================

/*
-- models/marts/fct_orders.sql (FIXED)
with orders as (
    select * from {{ ref('stg_orders') }}         -- clean, 1 row per order
),

-- Aggregate line items to order level BEFORE joining
order_item_totals as (
    select
        order_id,
        count(*)            as item_count,
        sum(line_total)     as items_revenue,
        sum(quantity)       as total_units
    from {{ ref('stg_order_items') }}
    group by 1
),

customers as (
    select * from {{ ref('stg_customers') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

enriched as (
    select
        o.order_id,
        o.order_date,
        o.status,
        o.amount,           -- header-level amount from raw_orders
        oi.items_revenue,   -- sum of line items (for cross-check)
        oi.item_count,
        oi.total_units,
        o.region,
        c.full_name          as customer_name,
        c.customer_segment,
        p.product_name,
        p.category,
        p.margin_pct
    from orders o
    left join order_item_totals oi on o.order_id = oi.order_id
    left join customers c on o.customer_id = c.customer_id
    left join products p on o.product_id = p.product_id
)

select * from enriched
*/

-- KEY INSIGHT: aggregate before joining, not after.
-- Always resolve grain before adding dimensions.
-- If you join a many-table without aggregating first, you inflate the one-table.


-- ============================================================
-- FIX 4: fct_revenue_daily — no changes needed after Fix 1
-- ============================================================

-- fct_revenue_daily reads stg_orders. Once stg_orders is fixed (1 row per order),
-- fct_revenue_daily's SUM(amount) and COUNT(order_id) will be correct automatically.
-- This is the power of fixing upstream: all downstream models self-heal.

-- Verify after applying fixes:
-- select sum(total_revenue) from {{ ref('fct_revenue_daily') }};
-- Should match: select sum(amount) from raw.raw_orders where status = 'completed';


-- ============================================================
-- MATERIALIZATION NOTE: should fct_revenue_daily be a table or view?
-- ============================================================

-- Current config: +materialized: table (correct for a mart)
-- Views re-run the query every time — fine for small data, slow for aggregations.
-- Tables persist the result — dashboards read pre-computed data.
-- Incremental materialization: for large datasets, only process new dates:

/*
-- dbt_project.yml or model config block:
{{ config(
    materialized='incremental',
    unique_key='order_date || region',
    on_schema_change='append_new_columns'
) }}

-- Then in the model, add an incremental filter:
{% if is_incremental() %}
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
*/

-- WHEN TO USE INCREMENTAL:
-- ✓ Table grows append-only (new days, new orders)
-- ✓ Historical data doesn't change
-- ✓ Full refresh is too slow (millions of rows)
-- ✗ Data can be updated retroactively (use full table or snapshots instead)
