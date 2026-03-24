-- stg_orders: clean order records
-- Source: raw.raw_orders
-- Grain: one row per order_id
--
-- NOTE: total_amount here is the declared order-level total.
-- Do NOT use this field in aggregations that also join to raw_order_items.
-- If you join raw_orders to raw_order_items at order grain without first
-- aggregating items, each multi-item order gets duplicated rows.
-- Use stg_order_items aggregated to order grain for revenue rollups.

with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

staged as (
    select
        order_id::varchar                   as order_id,
        customer_id::varchar                as customer_id,
        order_date::date                    as order_date,
        date_trunc('month', order_date::date)::date as order_month,
        lower(trim(status))::varchar        as status,
        total_amount::numeric(12, 2)        as total_amount
    from source
    where status != 'cancelled'
)

select * from staged
