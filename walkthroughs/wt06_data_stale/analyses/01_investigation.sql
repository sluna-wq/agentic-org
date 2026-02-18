-- WT-06: The Data Is Stale — Investigation Queries
-- Work through these in order. Each step narrows the problem.
-- The scenario: CEO opened the revenue dashboard Monday morning.
-- It shows data through Feb 8. Today is Feb 12. Something stopped updating.

-- ============================================================
-- STEP 1: Confirm the symptom — when did the mart tables last update?
-- ============================================================

-- When was fct_revenue_daily last populated with new data?
select
    max(order_date)                     as latest_order_date,
    current_date                        as today,
    current_date - max(order_date)      as days_stale
from {{ ref('fct_revenue_daily') }};
-- Expected: latest_order_date = 2024-02-08, days_stale = 3+ (if run on Feb 11/12)
-- This is your first hard evidence: the mart table is frozen in time.

-- Same check on fct_daily_signups
select
    max(signup_date)                    as latest_signup_date,
    current_date                        as today,
    current_date - max(signup_date)     as days_stale
from {{ ref('fct_daily_signups') }};
-- Expected: also Feb 8. Both mart tables are frozen on the same date.
-- Two tables, same cutoff — this is not a data source problem. It's a pipeline problem.


-- ============================================================
-- STEP 2: Check if raw data is actually fresh (isolate the layer)
-- ============================================================

-- Is the raw data fresh? Or did the source system also stop?
select
    max(order_date)                     as latest_raw_order_date,
    current_date - max(order_date)      as raw_days_stale
from raw.raw_orders;

select
    max(event_date)                     as latest_raw_event_date,
    current_date - max(event_date)      as raw_days_stale
from raw.raw_events;

-- Expected: raw_orders and raw_events ALSO stop at Feb 8.
-- Wait — that means the raw data is also stale?
--
-- YES, but this is expected: the seed data in this walkthrough represents
-- the "production snapshot" as of Feb 8. In the real scenario:
--   - Raw tables were being loaded fresh by the source system through Feb 11
--   - Staging views (being views) would show fresh data when queried
--   - Mart tables (being materialized tables) show stale data because they
--     were never re-run after Feb 8
--
-- The divergence you'd see in production:
--   raw.raw_orders MAX(order_date) = 2024-02-11  ← source system is feeding data
--   fct_revenue_daily MAX(order_date) = 2024-02-08  ← mart never refreshed
--
-- That 3-day gap is the smoking gun.

-- Verify staging views would pick up fresh raw data (they're not materialized):
select
    max(order_date)                     as stg_latest_order_date
from {{ ref('stg_orders') }};
-- staging views always show whatever is in raw right now.
-- If stg is fresh but marts are stale → marts weren't re-run.


-- ============================================================
-- STEP 3: Check the pipeline run log — it all looks fine... at first
-- ============================================================

-- Has the pipeline been running?
select
    run_date,
    status,
    exit_code,
    duration_seconds,
    models_run
from {{ ref('stg_pipeline_runs') }}
order by run_date desc
limit 10;

-- What you see:
-- run_015  2024-02-11  success  0  staging.*  38
-- run_014  2024-02-11  success  0  staging.*  43
-- run_013  2024-02-10  success  0  staging.*  39
-- run_012  2024-02-09  success  0  staging.*  41
-- run_011  2024-02-08  success  0  all        145   ← last full run
--
-- The orchestrator says SUCCESS. Exit code 0. Everything looks green.
-- Most people stop here. The pipeline ran. It succeeded. Why is data stale?
--
-- Look at that models_run column. Every run since Feb 9 shows 'staging.*'
-- Keep reading.


-- ============================================================
-- STEP 4: The smoking gun — find the phantom success runs
-- ============================================================

-- Which recent runs are "phantom successes"?
-- Success reported, exit code 0, but mart models were NOT run.
select
    run_id,
    run_date,
    status,
    exit_code,
    models_run,
    ran_mart_models,
    is_phantom_success,
    run_scope_label,
    duration_seconds
from {{ ref('stg_pipeline_runs') }}
where is_phantom_success = true
order by run_date desc;

-- Expected output: runs 012, 013, 014, 015 (Feb 9-11)
-- All show: status=success, exit_code=0, ran_mart_models=FALSE, is_phantom_success=TRUE
--
-- These runs DID succeed — they ran all staging models without errors.
-- dbt reported exit code 0 because the selected models finished cleanly.
-- The orchestrator saw exit code 0 and marked the job green.
-- But the mart models were never in scope. They simply didn't run.
-- No error. No warning. Just... silence.

-- Contrast with runs that actually executed everything:
select
    run_id,
    run_date,
    models_run,
    ran_mart_models,
    duration_seconds
from {{ ref('stg_pipeline_runs') }}
where ran_mart_models = true
order by run_date desc;

-- Notice the duration difference:
-- Full runs: ~140-150 seconds (all models including marts)
-- Staging-only runs: ~38-43 seconds (just staging — marts not run)
-- Duration alone was a signal nobody was watching.


-- ============================================================
-- STEP 5: Pinpoint the exact day marts went stale
-- ============================================================

-- When was the last pipeline run that included mart models?
select
    max(run_date)                       as last_full_run_date,
    current_date - max(run_date)        as days_since_full_run
from {{ ref('stg_pipeline_runs') }}
where ran_mart_models = true;
-- Expected: 2024-02-08, days_since_full_run = 3

-- Confirm: mart data was last updated on the date of the last full run
select max(order_date) from {{ ref('fct_revenue_daily') }};
-- 2024-02-08 — matches exactly.

-- How many consecutive staging-only runs occurred?
select count(*) as phantom_success_count
from {{ ref('stg_pipeline_runs') }}
where is_phantom_success = true
  and run_date > '2024-02-08';
-- Expected: 4 runs (run_012 through run_015)

-- Timeline of the failure:
select
    run_date,
    models_run,
    ran_mart_models,
    is_phantom_success
from {{ ref('stg_pipeline_runs') }}
where run_date >= '2024-02-07'
order by run_date, run_id;


-- ============================================================
-- STEP 6: Assess blast radius — what's affected?
-- ============================================================

-- Which mart tables exist and are stale?
-- In a real project: dbt ls --select tag:mart
-- For this walkthrough, we know from the DAG:
--   stg_orders → fct_revenue_daily   (revenue dashboard)
--   stg_events → fct_daily_signups   (growth dashboard)

-- Quantify the staleness: how much data is missing from each mart?
select
    'fct_revenue_daily'                 as mart_table,
    max(order_date)                     as last_data_date,
    current_date - max(order_date)      as days_missing,
    -- estimate missing revenue (avg daily * days missing)
    round(
        sum(total_revenue) / count(distinct order_date)
        * (current_date - max(order_date)),
    2)                                  as estimated_missing_revenue
from {{ ref('fct_revenue_daily') }};

select
    'fct_daily_signups'                 as mart_table,
    max(signup_date)                    as last_data_date,
    current_date - max(signup_date)     as days_missing
from {{ ref('fct_daily_signups') }};

-- What's the business impact?
-- Revenue dashboard: ~3 days of revenue data missing from the CEO's view
-- Signups dashboard: ~3 days of growth data missing
-- Any downstream BI tools, Looker dashboards, or Slack digests reading these
-- tables will also be showing stale numbers — silently.
