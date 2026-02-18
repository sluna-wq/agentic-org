-- stg_payments: naive staging with no deduplication
-- BUG: ETL retries create duplicate rows for the same transaction
-- payment_id is unique (new UUID per retry), so dbt unique test passes
-- But (order_id, customer_id, amount) is NOT unique — same transaction, different ID

with source as (
    select * from {{ source('raw', 'raw_payments') }}
),

staged as (
    select
        payment_id,
        order_id,
        customer_id,
        amount,
        status,
        paid_at,
        date_trunc('month', paid_at::date) as payment_month
    from source
    where status = 'succeeded'
)

select * from staged
