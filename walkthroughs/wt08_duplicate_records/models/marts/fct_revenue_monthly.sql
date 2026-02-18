-- fct_revenue_monthly: monthly revenue aggregation
-- BUG: summing payments without deduplication inflates revenue
-- Each ETL retry duplicate counts as a separate payment

with payments as (
    select * from {{ ref('stg_payments') }}
),

monthly as (
    select
        payment_month,
        count(distinct payment_id)   as payment_count,
        count(distinct order_id)     as order_count,
        sum(amount)                  as gross_revenue
    from payments
    group by 1
)

select * from monthly
order by payment_month
