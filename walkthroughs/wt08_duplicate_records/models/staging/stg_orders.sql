with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

staged as (
    select
        order_id,
        customer_id,
        order_date::date as order_date,
        status,
        total_amount
    from source
)

select * from staged
