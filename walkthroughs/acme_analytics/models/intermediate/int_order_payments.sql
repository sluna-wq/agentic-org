-- Join orders with their successful payments
with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

order_payments as (
    select
        o.order_id,
        o.customer_id,
        o.ordered_at,
        o.order_status,
        o.shipping_method,
        o.shipping_country,
        o.discount_code,
        o.subtotal,
        o.tax_amount,
        o.shipping_cost,
        o.order_total,
        o.currency,
        sum(case when p.payment_status = 'success' and p.amount > 0 then p.amount else 0 end) as amount_paid,
        sum(case when p.amount < 0 then abs(p.amount) else 0 end) as amount_refunded,
        count(distinct p.payment_id) as payment_count,
        max(p.paid_at) as last_payment_at,
        max(p.payment_method) as payment_method
    from orders o
    left join payments p on o.order_id = p.order_id
    group by 1,2,3,4,5,6,7,8,9,10,11,12
)

select * from order_payments
