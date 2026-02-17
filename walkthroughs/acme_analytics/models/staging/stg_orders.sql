with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

cleaned as (
    select
        order_id,
        customer_id,
        cast(order_date as timestamp) as ordered_at,
        lower(status) as order_status,
        lower(shipping_method) as shipping_method,
        upper(shipping_address_country) as shipping_country,
        nullif(trim(discount_code), '') as discount_code,
        cast(subtotal as decimal(10,2)) as subtotal,
        cast(tax as decimal(10,2)) as tax_amount,
        cast(shipping_cost as decimal(10,2)) as shipping_cost,
        cast(total as decimal(10,2)) as order_total,
        upper(currency) as currency,
        nullif(trim(notes), '') as notes
    from source
    where
        customer_id > 0
        and lower(notes) not like '%test%'
)

select * from cleaned
