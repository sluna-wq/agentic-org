-- WT-05: Why Is This Query So Slow? — Post-Fix Verification
-- Run these after applying the fix. All checks should pass (return 0 rows or match expected).

-- ============================================================
-- CHECK 1: stg_orders grain is restored (1 row per order)
-- ============================================================
select
    'stg_orders grain check'    as check_name,
    case
        when count(*) = count(distinct order_id) then 'PASS'
        else 'FAIL — fan-out still present'
    end                         as result,
    count(*)                    as total_rows,
    count(distinct order_id)    as distinct_orders
from {{ ref('stg_orders') }};
-- Expected: total_rows = distinct_orders = 50


-- ============================================================
-- CHECK 2: Revenue total matches raw source
-- ============================================================
with
    reported as (
        select sum(total_revenue) as revenue from {{ ref('fct_revenue_daily') }}
    ),
    actual as (
        select sum(amount) as revenue from raw.raw_orders where status = 'completed'
    )
select
    'revenue accuracy'          as check_name,
    reported.revenue            as reported_revenue,
    actual.revenue              as actual_revenue,
    abs(reported.revenue - actual.revenue) as discrepancy,
    case
        when abs(reported.revenue - actual.revenue) < 0.01 then 'PASS'
        else 'FAIL — discrepancy of ' || abs(reported.revenue - actual.revenue)
    end                         as result
from reported, actual;
-- Expected: discrepancy = 0.00, result = PASS


-- ============================================================
-- CHECK 3: fct_orders has no duplicate order_ids
-- ============================================================
select
    'fct_orders uniqueness'     as check_name,
    count(*)                    as duplicate_order_count
from (
    select order_id, count(*) as n
    from {{ ref('fct_orders') }}
    group by 1
    having n > 1
) dupes;
-- Expected: 0


-- ============================================================
-- CHECK 4: stg_order_items exists and has correct row count
-- ============================================================
select
    'stg_order_items row count' as check_name,
    count(*)                    as row_count
from {{ ref('stg_order_items') }};
-- Expected: 50 (one item per order in this dataset)

select
    'stg_order_items grain'     as check_name,
    case
        when count(*) = count(distinct item_id) then 'PASS'
        else 'FAIL'
    end                         as result
from {{ ref('stg_order_items') }};


-- ============================================================
-- CHECK 5: Cross-check order amounts vs line item totals
-- ============================================================
-- For orders with a single item, amount should equal line_total
select
    o.order_id,
    o.amount                    as header_amount,
    oi.line_total               as item_total,
    abs(o.amount - oi.line_total) as difference
from {{ ref('stg_orders') }} o
join {{ ref('stg_order_items') }} oi on o.order_id = oi.order_id
where abs(o.amount - oi.line_total) > 0.01
order by difference desc;
-- Expected: 0 rows (all amounts match their single line item)
-- Note: in real scenarios, multi-item orders would have different totals.


-- ============================================================
-- CHECK 6: Revenue by region is plausible
-- ============================================================
select
    region,
    sum(total_revenue)          as revenue,
    sum(order_count)            as orders,
    round(sum(total_revenue) / sum(order_count), 2) as avg_order_value
from {{ ref('fct_revenue_daily') }}
group by 1
order by 2 desc;
-- Sanity check: avg_order_value should be in the $75-$1200 range
-- No region should be zero (all regions are in the dataset)
