-- fct_customer_ltv: lifetime value per customer
-- BUG: inflated because duplicate payments are all counted

with payments as (
    select * from {{ ref('stg_payments') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

ltv as (
    select
        p.customer_id,
        c.first_name,
        c.last_name,
        count(distinct p.payment_id) as payment_count,
        sum(p.amount)                as lifetime_value,
        min(p.paid_at)               as first_payment_at,
        max(p.paid_at)               as last_payment_at
    from payments p
    left join customers c using (customer_id)
    group by 1, 2, 3
)

select * from ltv
order by lifetime_value desc
