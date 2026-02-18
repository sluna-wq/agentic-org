with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

staged as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        created_at::date as created_date
    from source
)

select * from staged
