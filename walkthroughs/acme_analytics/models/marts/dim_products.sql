-- Product dimension with sales metrics
with products as (
    select * from {{ ref('stg_products') }}
),

product_sales as (
    select
        oi.product_id,
        count(distinct oi.order_id) as times_ordered,
        sum(oi.quantity) as total_units_sold,
        sum(oi.line_total) as total_revenue,
        avg(oi.unit_price) as avg_selling_price
    from {{ ref('stg_order_items') }} oi
    inner join {{ ref('stg_orders') }} o on oi.order_id = o.order_id
    where o.order_status = 'completed'
    group by 1
),

final as (
    select
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        p.unit_price as list_price,
        p.cost_price,
        p.unit_price - p.cost_price as unit_margin,
        case when p.unit_price > 0
            then round((p.unit_price - p.cost_price) / p.unit_price * 100, 1)
            else null
        end as margin_pct,
        p.supplier,
        p.is_active,
        p.weight_kg,

        coalesce(ps.times_ordered, 0) as times_ordered,
        coalesce(ps.total_units_sold, 0) as total_units_sold,
        coalesce(ps.total_revenue, 0) as total_revenue,
        ps.avg_selling_price

    from products p
    left join product_sales ps on p.product_id = ps.product_id
)

select * from final
