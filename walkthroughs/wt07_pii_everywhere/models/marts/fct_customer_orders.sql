-- fct_customer_orders: order-level fact table joined with customer attributes
-- PROBLEM: stg_customers carries PII (email, phone, ssn_last4) via SELECT *
-- Those columns flow directly into this mart — and into every BI tool querying it.

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status,
        o.amount,
        o.region,
        -- Safe customer fields
        c.first_name,
        c.last_name,
        c.plan,
        c.country,
        -- BUG: these columns exist on c.* because stg_customers did SELECT *
        -- They will appear in query results and BI exports
        c.email,      -- PII: should not be here
        c.phone,      -- PII: should not be here
        c.ssn_last4   -- PII: should not be here
    from orders o
    left join customers c on o.customer_id = c.customer_id
)

select * from joined
