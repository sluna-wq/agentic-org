-- assert_stg_orders_grain: stg_orders must have exactly one row per order_id
-- This test fails (returns rows) if the fan-out bug is reintroduced.
-- A join to raw_order_items inside stg_orders will cause this test to fail.

select
    order_id,
    count(*) as row_count
from {{ ref('stg_orders') }}
group by 1
having count(*) > 1

-- Returns 0 rows when stg_orders is clean (1 row per order_id).
-- Returns N rows when fan-out is present — test fails, build stops.
