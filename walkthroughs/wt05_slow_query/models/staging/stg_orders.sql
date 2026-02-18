-- stg_orders: clean and type-cast raw orders
-- PROBLEM: this model fans out due to the join with raw_order_items
-- Every order_id appears N times (once per line item), but callers
-- treat this as one-row-per-order. The fan-out silently multiplies revenue.

with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

-- BUG: joining order_items here creates a fan-out.
-- An order with 3 items becomes 3 rows in this "orders" model.
-- Downstream aggregations (SUM of amount) are therefore 3x inflated.
order_items as (
    select * from {{ source('raw', 'raw_order_items') }}
),

joined as (
    select
        o.order_id,
        o.customer_id,
        o.product_id,
        o.order_date::date                  as order_date,
        o.status,
        o.amount,
        o.region,
        o.sales_rep_id,
        oi.item_id,
        oi.quantity,
        oi.unit_price,
        oi.discount_pct
    from source o
    -- This join is the bug: left join means every order duplicated per line item
    left join order_items oi on o.order_id = oi.order_id
)

select * from joined
