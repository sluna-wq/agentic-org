-- fct_marketing_reach: which customers were exported to which vendor
-- Joins export log with customer profile — PII leak propagates here too

with exports as (
    select * from {{ ref('stg_marketing_exports') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

enriched as (
    select
        e.export_id,
        e.export_date,
        e.customer_id,
        e.export_type,
        e.destination,
        e.status,
        -- Safe fields
        c.first_name,
        c.last_name,
        c.plan,
        c.country,
        -- BUG: PII columns present because stg_customers did SELECT *
        c.email,      -- PII: this went to the vendor
        c.phone,      -- PII: this went to the vendor
        c.ssn_last4   -- PII: this went to the vendor
    from exports e
    left join customers c on e.customer_id = c.customer_id
)

select * from enriched
