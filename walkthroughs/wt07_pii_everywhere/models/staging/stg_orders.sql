-- stg_orders: clean and type-cast raw orders
select
    order_id,
    customer_id,
    product_id,
    order_date::date  as order_date,
    status,
    amount,
    region
from {{ source('raw', 'raw_orders') }}
