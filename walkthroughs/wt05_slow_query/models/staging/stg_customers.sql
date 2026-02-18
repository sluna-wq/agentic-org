-- stg_customers: clean customer records
with source as (
    select * from {{ source('raw', 'raw_customers') }}
)

select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name   as full_name,
    lower(email)                      as email,
    created_at::date                  as created_date,
    region,
    customer_segment,
    lifetime_orders
from source
