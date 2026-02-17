with source as (
    select * from {{ source('raw', 'raw_payments') }}
),

cleaned as (
    select
        payment_id,
        order_id,
        lower(payment_method) as payment_method,
        cast(amount as decimal(10,2)) as amount,
        upper(currency) as currency,
        lower(status) as payment_status,
        cast(created_at as timestamp) as paid_at,
        processor_id,
        nullif(trim(failure_reason), '') as failure_reason
    from source
)

select * from cleaned
