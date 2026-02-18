-- stg_products: clean product catalog
with source as (
    select * from {{ source('raw', 'raw_products') }}
)

select
    product_id,
    product_name,
    category,
    unit_price,
    cost,
    unit_price - cost                                    as gross_margin,
    round((unit_price - cost) / unit_price * 100, 1)    as margin_pct,
    is_active::boolean                                   as is_active
from source
