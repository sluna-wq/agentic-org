-- fct_revenue_daily: daily revenue aggregation
-- DOWNSTREAM VICTIM: this model inherits the fan-out from stg_orders.
-- The SUM(amount) is inflated because stg_orders has multiple rows per order.
-- Dashboard shows ~3.2x actual revenue. Finance is asking questions.

with orders as (
    select * from {{ ref('stg_orders') }}
),

daily as (
    select
        order_date,
        region,
        count(order_id)          as order_count,   -- also inflated (counts items not orders)
        sum(amount)              as total_revenue,  -- BUG: inflated by fan-out
        avg(amount)              as avg_order_value
    from orders
    where status = 'completed'
    group by 1, 2
)

select * from daily
