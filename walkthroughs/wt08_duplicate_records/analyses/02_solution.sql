-- WT-08 Solution: Deduplicate at the staging layer

-- FIX: Update stg_payments.sql to use this CTE pattern.
-- Keep the earliest payment per (order_id, customer_id, amount).
-- Add is_duplicate flag for auditability.

with source as (
    select * from {{ source('raw', 'raw_payments') }}
    where status = 'succeeded'
),

ranked as (
    select
        *,
        row_number() over (
            partition by order_id, customer_id, amount
            order by paid_at asc
        ) as row_num
    from source
),

deduplicated as (
    select
        payment_id,
        order_id,
        customer_id,
        amount,
        status,
        paid_at,
        date_trunc('month', paid_at::date) as payment_month,
        case when row_num > 1 then true else false end as is_duplicate
    from ranked
)

-- Production query: only canonical payments
select * from deduplicated where is_duplicate = false;

-- Audit query: see all duplicates that were suppressed
-- select * from deduplicated where is_duplicate = true;
