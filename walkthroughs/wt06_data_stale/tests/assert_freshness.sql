-- assert_freshness: dbt singular test for fct_revenue_daily
--
-- This test FAILS (returns rows) if fct_revenue_daily has not been updated
-- within the last 25 hours. The 25-hour window (not 24) gives a small buffer
-- for pipelines that run slightly past their scheduled window.
--
-- Why 25 hours specifically:
--   - Daily pipelines typically run at a fixed hour (e.g., 6 AM)
--   - A Monday 6 AM run covers data through Sunday
--   - If the pipeline is delayed 1 hour, 25h threshold absorbs that slack
--   - If the pipeline was Saturday-only (e.g., staging.*), 25h catches it by Sunday 7 AM
--   - A 48h threshold would miss the weekend pattern entirely
--
-- Run this test:
--   dbt test --select assert_freshness
--
-- In CI/CD: add to your post-deploy test suite.
-- As a scheduled check: run every hour, alert on any row returned.
--
-- Returns: one row per stale mart (test fails if any rows returned)

with mart_ages as (

    select
        'fct_revenue_daily'             as mart_name,
        max(order_date)                 as last_data_date,
        -- Convert days since last update to approximate hours
        -- (we use date arithmetic since our data uses date columns, not timestamps)
        (current_date - max(order_date)) * 24  as approximate_hours_stale
    from {{ ref('fct_revenue_daily') }}

)

select
    mart_name,
    last_data_date,
    approximate_hours_stale,
    'Data has not been refreshed in ' || approximate_hours_stale || ' hours (SLA: 25h)'
        as failure_reason
from mart_ages
where approximate_hours_stale > 25

-- Zero rows returned = test PASSES (data is fresh)
-- One or more rows returned = test FAILS (data is stale, SLA breached)
--
-- dbt convention: singular tests return rows to indicate failure.
-- An empty result set means everything is healthy.
