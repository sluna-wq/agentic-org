-- Daily revenue aggregation for dashboards
with orders as (
    select * from {{ ref('fct_orders') }}
    where is_successful
),

daily as (
    select
        cast(ordered_at as date) as order_date,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as unique_customers,
        sum(order_total) as gross_revenue,
        sum(amount_refunded) as refunds,
        sum(net_revenue) as net_revenue,
        sum(total_units) as units_sold,
        avg(order_total) as avg_order_value,
        sum(case when has_discount then 1 else 0 end) as discounted_orders,
        sum(case when shipping_method = 'overnight' then 1 else 0 end) as express_orders
    from orders
    group by 1
)

select * from daily
