-- Fact table: one row per order with payment and item details
with order_payments as (
    select * from {{ ref('int_order_payments') }}
),

order_items_agg as (
    select
        order_id,
        count(*) as item_count,
        sum(quantity) as total_units,
        count(distinct product_id) as unique_products
    from {{ ref('stg_order_items') }}
    group by 1
),

final as (
    select
        op.order_id,
        op.customer_id,
        op.ordered_at,
        op.order_status,
        op.shipping_method,
        op.shipping_country,
        op.discount_code,
        op.currency,
        op.payment_method,

        -- Financials
        op.subtotal,
        op.tax_amount,
        op.shipping_cost,
        op.order_total,
        op.amount_paid,
        op.amount_refunded,
        op.order_total - op.amount_refunded as net_revenue,

        -- Items
        coalesce(oi.item_count, 0) as item_count,
        coalesce(oi.total_units, 0) as total_units,
        coalesce(oi.unique_products, 0) as unique_products,

        -- Timing
        op.last_payment_at,
        op.payment_count,

        -- Flags
        op.discount_code is not null as has_discount,
        op.amount_refunded > 0 as has_refund,
        op.order_status in ('completed', 'shipped') as is_successful

    from order_payments op
    left join order_items_agg oi on op.order_id = oi.order_id
)

select * from final
