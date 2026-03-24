-- fct_order_revenue_fixed: corrected order-level revenue rollup
-- SOLUTION for Finding #1 (grain violation)
--
-- Fix applied 2026-02-23 by autonomous agent (WT-10 sweep).
-- Root cause: original fct_order_revenue joined stg_order_items at order grain
-- without pre-aggregating. Multi-item orders produced multiple rows, inflating
-- revenue by ~$127K (23.5%) for January 2026.
--
-- Fix: aggregate order_items to order grain FIRST (items_by_order CTE),
-- then join to orders. Result: one row per order_id per month. Always.
--
-- Regression test: assert_revenue_grain.sql — each order_id must appear exactly once.
-- Deployed: 2026-02-23 06:18 (autonomous agent fix, reviewed by data team 09:15)

with orders as (
    select * from {{ ref('stg_orders') }}
),

-- FIXED: aggregate items to order grain BEFORE joining
items_by_order as (
    select
        order_id,
        -- Take the dominant product name (highest line_total) for labeling
        max(case when line_total > 0 then product_name else null end) as primary_product_name,
        max(case when line_total > 0 then product_id   else null end) as primary_product_id,
        count(*)                                                       as item_count,
        sum(line_total)                                                as items_total
    from {{ ref('stg_order_items') }}
    group by 1
),

-- FIXED: this join is now order grain → order grain (one-to-one)
joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_month,
        o.status,
        o.total_amount,
        i.primary_product_id    as product_id,
        i.primary_product_name  as product_name,
        i.item_count
    from orders o
    left join items_by_order i
        on o.order_id = i.order_id
),

monthly as (
    select
        order_month,
        product_id,
        product_name,
        count(distinct order_id)    as order_count,
        -- FIXED: sum(total_amount) is now correct — no duplicated rows
        sum(total_amount)           as total_revenue
    from joined
    group by 1, 2, 3
)

select *
from monthly
order by order_month, product_id
