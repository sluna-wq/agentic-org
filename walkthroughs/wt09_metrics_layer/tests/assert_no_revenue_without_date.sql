-- tests/assert_no_revenue_without_date.sql
--
-- Custom dbt test: assert that no order in fct_orders has a non-null
-- revenue amount (amount_usd_converted > 0) combined with a null
-- recognized_at when that order is flagged as is_revenue_recognized = true.
--
-- WHY THIS MATTERS:
-- The canonical metric definition uses recognized_at as the date field.
-- If a row has is_revenue_recognized = true but recognized_at is NULL,
-- that row will silently disappear from any monthly revenue query that
-- filters on date_trunc('month', recognized_at). Revenue is lost with no
-- error. This test makes that invisible data quality problem visible.
--
-- WHAT TRIGGERS A FAILURE:
-- - An order with status 'completed' or 'invoiced' that is missing a
--   recognized_at timestamp (e.g., due to an ERP sync gap)
-- - Any ETL bug that sets is_revenue_recognized = true without setting
--   recognized_at
--
-- IN dbt: This test returns rows that represent failures.
-- A passing test returns zero rows.
-- A failing test returns one row per problematic order.
--
-- TO RUN MANUALLY:
--   SELECT * FROM this query against your fct_orders table.
--   Zero rows = test passes. Any rows = data quality issue to investigate.

select
    order_id,
    customer_id,
    status,
    currency,
    amount_usd_converted,
    amount_usd_face,
    recognized_at,
    is_revenue_recognized,
    created_at,
    paid_at,
    'revenue recognized flag set but recognized_at is null' as failure_reason
from {{ ref('fct_orders') }}
where
    -- The order is flagged as recognized revenue
    is_revenue_recognized = true
    -- But the date field is missing — the row would silently drop from
    -- any query filtering on date_trunc('month', recognized_at)
    and recognized_at is null
    -- Confirm there is actual money at stake (not a $0 adjustment row)
    and coalesce(amount_usd_converted, 0) > 0
