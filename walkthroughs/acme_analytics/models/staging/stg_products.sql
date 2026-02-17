with source as (
    select * from {{ source('raw', 'raw_products') }}
),

cleaned as (
    select
        product_id,
        nullif(trim(product_name), '') as product_name,
        nullif(trim(category), '') as category,
        nullif(trim(subcategory), '') as subcategory,
        case when unit_price > 0 then cast(unit_price as decimal(10,2)) else null end as unit_price,
        case when cost_price > 0 then cast(cost_price as decimal(10,2)) else null end as cost_price,
        nullif(trim(supplier), '') as supplier,
        cast(is_active as boolean) as is_active,
        cast(created_at as timestamp) as created_at,
        cast(weight_kg as decimal(10,2)) as weight_kg
    from source
    where
        product_name not like 'DISCONTINUED%'
)

select * from cleaned
