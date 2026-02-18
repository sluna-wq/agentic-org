-- WT-06: The Data Is Stale — Verification Queries
-- Run these after applying the fix (correcting the orchestrator selector
-- and re-running the mart layer with `dbt run --select marts.*`).
-- All checks should pass (return expected results or zero rows for alert queries).

-- ============================================================
-- CHECK 1: Mart data is now current
-- ============================================================

-- fct_revenue_daily should show data through the latest raw date
select
    max(order_date)                     as latest_mart_date,
    current_date - max(order_date)      as days_stale,
    case
        when current_date - max(order_date) <= 1 then 'PASS: within SLA'
        else 'FAIL: still stale'
    end                                 as check_result
from {{ ref('fct_revenue_daily') }};
-- Expected: days_stale = 0 or 1, check_result = 'PASS: within SLA'

-- fct_daily_signups should also be current
select
    max(signup_date)                    as latest_signup_date,
    current_date - max(signup_date)     as days_stale,
    case
        when current_date - max(signup_date) <= 1 then 'PASS: within SLA'
        else 'FAIL: still stale'
    end                                 as check_result
from {{ ref('fct_daily_signups') }};

-- Both marts are fresh. The dashboard is healthy again.


-- ============================================================
-- CHECK 2: Pipeline run log reflects the corrected execution
-- ============================================================

-- The corrective run should appear in the pipeline log with models_run = 'all'
select
    run_id,
    run_date,
    status,
    exit_code,
    models_run,
    ran_mart_models,
    is_phantom_success,
    duration_seconds
from {{ ref('stg_pipeline_runs') }}
order by run_date desc, run_id desc
limit 5;
-- Most recent run should show:
--   ran_mart_models = true
--   is_phantom_success = false
--   duration_seconds ~= 140+ (full run, not 40s staging-only)

-- No phantom successes in the last 24 hours:
select count(*) as phantom_runs_last_24h
from {{ ref('stg_pipeline_runs') }}
where is_phantom_success = true
  and run_date >= current_date - 1;
-- Expected: 0


-- ============================================================
-- CHECK 3: Freshness SLA — both marts within threshold
-- ============================================================

-- This query should return zero rows (no stale marts)
with mart_freshness as (
    select 'fct_revenue_daily' as mart, max(order_date) as last_date
    from {{ ref('fct_revenue_daily') }}
    union all
    select 'fct_daily_signups' as mart, max(signup_date) as last_date
    from {{ ref('fct_daily_signups') }}
)
select
    mart,
    last_date,
    current_date - last_date            as days_stale,
    'STALE'                             as status
from mart_freshness
where current_date - last_date > 1;
-- Expected: zero rows returned (no marts are stale)
-- If rows appear: something is still stale, investigate further.


-- ============================================================
-- CHECK 4: Data integrity — mart totals match raw sources
-- ============================================================

-- Revenue mart totals should match raw orders
select
    round(
        (select sum(total_revenue) from {{ ref('fct_revenue_daily') }}) -
        (select sum(amount) from {{ ref('stg_orders') }} where status = 'completed'),
    2)                                  as revenue_discrepancy;
-- Expected: 0.00 (mart matches source)
-- Any non-zero value suggests the mart is still out of sync.

-- Signup count should match raw events
select
    (select sum(signup_count) from {{ ref('fct_daily_signups') }}) -
    (select count(*) from {{ ref('stg_events') }} where is_signup = true)
    as signup_count_discrepancy;
-- Expected: 0


-- ============================================================
-- CHECK 5: The freshness test passes
-- ============================================================

-- Run the test manually to confirm it passes:
--   dbt test --select assert_freshness
--
-- Or check what the test would return (should return zero rows = PASS):
select
    max(order_date)                     as last_revenue_date,
    current_date                        as today,
    current_date - max(order_date)      as hours_since_update_approx,
    case
        when current_date - max(order_date) <= 1
            then 'TEST PASSES: data is fresh'
        else 'TEST FAILS: data is stale — returned rows signal failure'
    end                                 as test_status
from {{ ref('fct_revenue_daily') }};
-- Expected: test_status = 'TEST PASSES: data is fresh'


-- ============================================================
-- SUMMARY: Full health report
-- ============================================================

select 'fct_revenue_daily'             as mart,
       max(order_date)                  as last_data_date,
       current_date - max(order_date)   as days_stale,
       'PASS'                           as status
from {{ ref('fct_revenue_daily') }}
having current_date - max(order_date) <= 1

union all

select 'fct_daily_signups'             as mart,
       max(signup_date)                 as last_data_date,
       current_date - max(signup_date)  as days_stale,
       'PASS'                           as status
from {{ ref('fct_daily_signups') }}
having current_date - max(signup_date) <= 1;

-- If both rows appear with status=PASS: all clear.
-- If a mart is missing from this result: it's still stale.
