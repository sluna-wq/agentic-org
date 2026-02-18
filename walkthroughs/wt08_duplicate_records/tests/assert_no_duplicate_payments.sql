-- assert_no_duplicate_payments.sql
-- CI gate: fails if any semantic duplicates exist in stg_payments
-- A semantic duplicate = same (order_id, customer_id, amount) more than once
-- This test catches ETL retry duplicates that evade the payment_id unique test

with payment_counts as (
    select
        order_id,
        customer_id,
        amount,
        count(*) as occurrence_count
    from {{ ref('stg_payments') }}
    group by 1, 2, 3
),

violations as (
    select *
    from payment_counts
    where occurrence_count > 1
)

select
    order_id,
    customer_id,
    amount,
    occurrence_count
from violations
-- dbt test fails if this query returns any rows
