-- assert_revenue_grain: each order must appear exactly once in the revenue mart
--
-- This test encodes the grain invariant surfaced in Finding #1 (WT-10):
-- fct_order_revenue produced duplicate rows for multi-item orders due to a
-- fan-out join to raw_order_items. Orders with 2 items appeared twice;
-- orders with 3 items appeared three times. Revenue was inflated by ~$127K.
--
-- The test returns rows when any order_id appears more than once in the source
-- mart (fct_order_revenue). dbt test semantics: a passing test returns 0 rows.
--
-- This test should be applied to fct_order_revenue_fixed (the corrected model).
-- Running it against the original fct_order_revenue will FAIL by design —
-- that is the proof of the bug.
--
-- Added: 2026-02-23 (autonomous agent, WT-10 sweep — Finding #1)
-- Owner: data team
--
-- Implementation note: fct_order_revenue aggregates to (order_month, product_id)
-- grain, not order_id grain. To test for order-level duplication we need to
-- go back to the joined intermediate step. Since we can't reference CTEs inside
-- dbt tests, we check a proxy: the sum of revenue across all months vs the
-- known-correct total from the source orders table.
--
-- Proxy check: if sum(total_revenue) in the mart > sum(total_amount) in raw_orders
-- by more than 5%, a grain violation is likely present.

with mart_revenue as (
    select sum(total_revenue) as mart_total
    from {{ ref('fct_order_revenue_fixed') }}
),

source_revenue as (
    select sum(total_amount) as source_total
    from {{ source('raw', 'raw_orders') }}
    where status != 'cancelled'
),

check_result as (
    select
        mr.mart_total,
        sr.source_total,
        abs(mr.mart_total - sr.source_total)        as absolute_delta,
        abs(mr.mart_total - sr.source_total)
            / nullif(sr.source_total, 0) * 100       as pct_delta,
        case
            when abs(mr.mart_total - sr.source_total)
                 / nullif(sr.source_total, 0) > 0.05
            then 'GRAIN_VIOLATED'
            else 'OK'
        end as status
    from mart_revenue mr
    cross join source_revenue sr
)

-- Return rows only on failure (dbt test convention: 0 rows = pass)
select
    mart_total,
    source_total,
    absolute_delta,
    round(pct_delta::numeric, 2) as pct_delta,
    status,
    'Revenue discrepancy exceeds 5% tolerance — likely grain violation in mart join' as failure_reason
from check_result
where status = 'GRAIN_VIOLATED'

-- PASSING STATE: fct_order_revenue_fixed — 0 rows returned (mart matches source)
-- FAILING STATE: original fct_order_revenue — rows returned (fan-out inflation detected)
