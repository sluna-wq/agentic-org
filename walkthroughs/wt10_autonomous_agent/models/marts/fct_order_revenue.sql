-- fct_order_revenue: order-level revenue rollup
-- Intended grain: one row per order_id per month
--
-- BUG: GRAIN VIOLATION — FAN-OUT JOIN
--
-- This model was updated on 2026-02-14 (WT-04 schema migration context) to join
-- raw_order_items so that product_name and product_id could be included in the output.
-- The join was added at the order grain without first aggregating items.
--
-- Result: orders with multiple line items produce multiple rows.
--   - A 2-item order → 2 rows (order revenue counted twice)
--   - A 3-item order → 3 rows (order revenue counted three times)
--
-- For January 2026:
--   Correct order count: 60 orders
--   Rows in this model: ~103 rows (because 43 orders have 2+ items)
--   Inflated revenue: actual ~$540K → reported ~$667K (+~$127K, +23.5%)
--
-- Fix: aggregate stg_order_items to order grain BEFORE joining.
-- See fct_order_revenue_fixed.sql for the corrected version.

with orders as (
    select * from {{ ref('stg_orders') }}
),

-- BUG: this CTE is at ITEM grain, not ORDER grain
order_items as (
    select * from {{ ref('stg_order_items') }}
),

-- BUG: joining at order grain to an item-grain table without aggregating first
-- Each order with N items will produce N rows
joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_month,
        o.status,
        o.total_amount,
        i.product_id,
        i.product_name,
        i.line_total
    from orders o
    -- BUG: this is a one-to-many join — not aggregated to order grain
    left join order_items i
        on o.order_id = i.order_id
),

-- BUG: aggregating here partially masks the problem but the order_id is no longer unique
-- because we grouped on product_id — orders with multiple products become multiple rows
monthly as (
    select
        order_month,
        product_id,
        product_name,
        count(distinct order_id)    as order_count,
        -- BUG: this sum double-counts total_amount for multi-item orders
        sum(total_amount)           as total_revenue
    from joined
    group by 1, 2, 3
)

select *
from monthly
order by order_month, product_id
