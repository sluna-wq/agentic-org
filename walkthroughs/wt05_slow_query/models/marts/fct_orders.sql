-- fct_orders: one row per order with customer + product enrichment
-- DOWNSTREAM VICTIM: built on stg_orders which has the fan-out bug.
-- customer_name and product_name are duplicated across rows.
-- Any aggregation here double/triple counts.

with orders as (
    select * from {{ ref('stg_orders') }}
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
        o.amount,
        o.region,
        c.full_name          as customer_name,
        c.customer_segment,
        p.product_name,
        p.category,
        p.margin_pct
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join products p on o.product_id = p.product_id
)

select * from enriched
