-- WT-06: The Data Is Stale — Solution Queries
-- Root cause: orchestrator running `dbt run --select staging.*`
-- Fix: correct the selector so all models (including marts) execute.

-- ============================================================
-- THE FIX: Orchestrator Command Correction
-- ============================================================

-- BROKEN (what the orchestrator was running Feb 9-11):
--   dbt run --select staging.*
--
-- This command runs ONLY models in the staging/ directory.
-- It excludes all models in marts/ — they are silently skipped.
-- dbt exits 0 because all selected models succeeded.
-- The orchestrator sees 0 → marks job green → nobody notices.

-- CORRECT OPTION 1 — Run all models (simplest fix):
--   dbt run
--
-- No --select flag means "run everything." This is the safest default.
-- Use this unless you have a specific reason to run a subset.

-- CORRECT OPTION 2 — Explicit mart inclusion:
--   dbt run --select staging.* marts.*
--
-- If you must use selectors (e.g., for partial refresh performance),
-- name all the layers explicitly. Never assume "staging ran" means "done."

-- CORRECT OPTION 3 — Tag-based selection (most maintainable):
--   First, tag your models in YAML:
--     models:
--       - name: fct_revenue_daily
--         config:
--           tags: ['mart', 'finance']
--   Then run: dbt run --select tag:mart+
--
-- Tag-based selection survives model renames and folder restructures.

-- CORRECT OPTION 4 — Run all plus freshness check after:
--   dbt run && dbt source freshness
--
-- Run everything, then validate freshness immediately.
-- Fail the job if any source or mart is outside SLA.


-- ============================================================
-- IMMEDIATE REMEDIATION: Re-run the mart layer now
-- ============================================================

-- After fixing the orchestrator config, manually trigger:
--   dbt run --select marts.*
--
-- This will refresh fct_revenue_daily and fct_daily_signups
-- using the staging views (which pull from raw, which is current).
-- The mart tables will jump from Feb 8 data to Feb 11 data.

-- Verify the backfill worked (run these after dbt run --select marts.*):
select
    max(order_date)                     as new_max_date,
    count(distinct order_date)          as days_populated
from {{ ref('fct_revenue_daily') }};
-- Should show Feb 11 (or current date of raw data)

select
    max(signup_date)                    as new_max_signup_date
from {{ ref('fct_daily_signups') }};
-- Should also show Feb 8 (data was always there — now it's in the mart)


-- ============================================================
-- PREVENTION: Freshness monitoring queries
-- Schedule these as automated checks or add to orchestration
-- ============================================================

-- Check 1: Is the revenue mart within SLA? (Run every hour)
-- Returns a row (causing an alert) if stale beyond threshold.
select
    'fct_revenue_daily'                 as table_name,
    max(order_date)                     as last_update,
    current_date - max(order_date)      as age_days,
    case
        when current_date - max(order_date) > 1 then 'STALE'
        else 'OK'
    end                                 as freshness_status
from {{ ref('fct_revenue_daily') }}
having current_date - max(order_date) > 1;
-- Returns zero rows if fresh. Returns a row if stale → trigger alert.

-- Check 2: Is every mart table within SLA? (Generalized pattern)
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
    case
        when current_date - last_date = 0 then 'FRESH'
        when current_date - last_date = 1 then 'WARN'
        else 'STALE'
    end                                 as status
from mart_freshness
order by days_stale desc;

-- Check 3: Pipeline audit — was the last run a full run?
select
    run_id,
    run_date,
    models_run,
    ran_mart_models,
    is_phantom_success
from {{ ref('stg_pipeline_runs') }}
order by run_date desc, run_id desc
limit 1;
-- If is_phantom_success = true → the last run was a partial success. Alert.

-- Check 4: Duration anomaly detection
-- Full runs take ~140-150s. Staging-only runs take ~40s.
-- A sudden drop in run duration is a signal that the scope changed.
select
    run_date,
    duration_seconds,
    avg(duration_seconds) over (
        order by run_date
        rows between 7 preceding and 1 preceding
    )                                   as rolling_7d_avg,
    duration_seconds / avg(duration_seconds) over (
        order by run_date
        rows between 7 preceding and 1 preceding
    )                                   as duration_ratio
from {{ ref('stg_pipeline_runs') }}
where status = 'success'
order by run_date desc;
-- A duration_ratio < 0.5 on a "successful" run is suspicious.
-- It likely means the run scope was narrower than usual.


-- ============================================================
-- ADD TO DBT PROJECT: Freshness source configuration
-- ============================================================

-- In src_acme.yml, add loaded_at_field and freshness thresholds:
--
-- sources:
--   - name: raw
--     freshness:
--       warn_after: {count: 1, period: day}
--       error_after: {count: 2, period: day}
--     tables:
--       - name: raw_orders
--         loaded_at_field: _loaded_at  # timestamp column added by ingestion layer
--
-- Then run: dbt source freshness
-- This makes dbt natively aware of source freshness SLAs.
-- Integrate into your CI/CD pipeline to block deploys on stale sources.
