with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

cleaned as (
    select
        customer_id,
        nullif(trim(first_name), '') as first_name,
        nullif(trim(last_name), '') as last_name,
        nullif(trim(lower(email)), '') as email,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(is_active as boolean) as is_active,
        case
            when customer_segment in ('premium', 'standard', 'enterprise') then customer_segment
            else 'unknown'
        end as customer_segment,
        nullif(trim(phone), '') as phone,
        nullif(trim(upper(country)), '') as country
    from source
    where
        customer_id is not null
        and nullif(trim(first_name), '') is not null
        and lower(coalesce(email, '')) not like '%test%'
)

select * from cleaned
