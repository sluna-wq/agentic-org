-- Aggregate order history per customer
with order_payments as (
    select * from {{ ref('int_order_payments') }}
),

customer_orders as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        count(distinct case when order_status = 'completed' then order_id end) as completed_orders,
        count(distinct case when order_status = 'returned' then order_id end) as returned_orders,
        count(distinct case when order_status = 'cancelled' then order_id end) as cancelled_orders,
        sum(case when order_status = 'completed' then order_total else 0 end) as lifetime_revenue,
        sum(amount_refunded) as lifetime_refunds,
        avg(case when order_status = 'completed' then order_total end) as avg_order_value,
        min(ordered_at) as first_order_at,
        max(ordered_at) as last_order_at,
        datediff('day', min(ordered_at), max(ordered_at)) as customer_tenure_days
    from order_payments
    group by 1
)

select * from customer_orders
