-- stg_orders: one row per order, cleaned and typed
-- Grain: one row per order_id
-- Source: raw.raw_orders

with source as (

    select * from {{ ref('raw_orders') }}

),

staged as (

    select
        order_id,
        customer_id,
        cast(order_date as date)            as order_date,
        cast(amount as numeric(10, 2))      as amount,
        lower(status)                       as status,

        -- derived
        date_trunc('month', cast(order_date as date))  as order_month,
        case
            when amount >= 300 then 'high'
            when amount >= 100 then 'medium'
            else 'low'
        end                                 as order_size_tier

    from source

)

select * from staged
