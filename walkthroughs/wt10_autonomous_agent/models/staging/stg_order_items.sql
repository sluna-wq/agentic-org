-- stg_order_items: line-item records
-- Source: raw.raw_order_items
-- Grain: one row per item_id (NOT per order_id)
--
-- IMPORTANT: order_id is NOT unique in this table.
-- One order can have 1–3 items depending on what was purchased.
-- To compute order-level revenue from items, GROUP BY order_id and SUM line_total.
--
-- The grain violation in fct_order_revenue happens because the model joins
-- stg_orders to this table without aggregating to order grain first,
-- duplicating every multi-item order.

with source as (
    select * from {{ source('raw', 'raw_order_items') }}
),

staged as (
    select
        item_id::varchar                        as item_id,
        order_id::varchar                       as order_id,
        product_id::varchar                     as product_id,
        trim(product_name)::varchar             as product_name,
        quantity::integer                       as quantity,
        unit_price::numeric(12, 2)              as unit_price,
        line_total::numeric(12, 2)              as line_total
    from source
)

select * from staged
