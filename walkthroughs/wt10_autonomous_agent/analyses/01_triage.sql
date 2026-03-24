-- =============================================================================
-- WT-10: AUTONOMOUS AGENT — MONDAY MORNING SWEEP
-- Run timestamp: 2026-02-23 06:00:00 UTC
-- Agent: CTO-Agent (dbt + SQL sweep)
-- Coverage: full stack — orders, customers, revenue, pipeline metadata
-- =============================================================================
-- This file is structured as the agent's triage investigation.
-- Execute each block in sequence. Each block surfaces one finding.
-- The final block (TRIAGE SUMMARY) produces the Monday morning brief.
--
-- FINDINGS SUMMARY (produced at 06:47):
--   F-001 CRITICAL  Grain violation in fct_order_revenue — revenue inflated ~$127K
--   F-002 HIGH      fct_customer_metrics stale 84h — phantom success pattern
--   F-003 HIGH      PII exposure in fct_customer_metrics — ESCALATE, do not fix
--   F-004 MEDIUM    Metric fragmentation — $80K discrepancy, cash vs accrual
-- =============================================================================


-- =============================================================================
-- BLOCK 1: STALENESS CHECK
-- What: scan pipeline run metadata for models that haven't refreshed recently.
-- Threshold: any model with last successful run > 24h ago is flagged.
-- =============================================================================

-- 1a. Find the last SUCCESSFUL run per model
with last_success as (
    select
        model_name,
        max(run_at::timestamp)                      as last_successful_run_at,
        extract(epoch from (
            current_timestamp - max(run_at::timestamp)
        )) / 3600.0                                 as hours_since_last_run
    from {{ source('raw', 'raw_pipeline_runs') }}
    where status = 'success'
    group by 1
),

-- 1b. Check for phantom success: models that ran recently but used cached results
recent_cache_hits as (
    select
        model_name,
        count(*)    as cache_hit_runs,
        max(run_at) as last_cache_hit_at
    from {{ source('raw', 'raw_pipeline_runs') }}
    where status = 'warning_cached'
      and run_at::timestamp >= current_timestamp - interval '96 hours'
    group by 1
)

select
    ls.model_name,
    ls.last_successful_run_at,
    round(ls.hours_since_last_run::numeric, 1)  as hours_stale,
    coalesce(rch.cache_hit_runs, 0)             as phantom_success_count,
    rch.last_cache_hit_at,
    case
        when ls.hours_since_last_run > 72 then 'STALE_CRITICAL'
        when ls.hours_since_last_run > 24 then 'STALE_WARNING'
        else 'FRESH'
    end                                         as staleness_status,
    case
        when coalesce(rch.cache_hit_runs, 0) > 0 then true
        else false
    end                                         as has_phantom_success
from last_success ls
left join recent_cache_hits rch
    on ls.model_name = rch.model_name
order by ls.hours_since_last_run desc

-- EXPECTED FINDING F-002:
-- fct_customer_metrics | last_successful_run_at: 2026-02-19 22:14:33
-- hours_stale: ~83.8 | staleness_status: STALE_CRITICAL | has_phantom_success: true
-- Root cause: warning_cached on Fri/Sat/Sun — dbt used stale table silently.
-- Agent action: AUTONOMOUS FIX — resolve compilation warning, --full-refresh.

;

-- =============================================================================
-- BLOCK 2: GRAIN VIOLATION CHECK
-- What: detect fan-out joins by comparing declared order count to actual row count
-- Method: count distinct order_ids vs total rows in fct_order_revenue
-- =============================================================================

-- 2a. How many distinct orders exist in the source?
with source_orders as (
    select count(distinct order_id) as source_order_count
    from {{ source('raw', 'raw_orders') }}
    where status != 'cancelled'
),

-- 2b. How many rows does fct_order_revenue produce?
-- If grain is correct: rows = distinct order count
-- If grain is violated: rows > distinct order count (fan-out)
mart_rows as (
    select
        count(*)                    as mart_row_count,
        count(distinct order_id)    as mart_distinct_orders,
        sum(total_revenue)          as reported_total_revenue
    from {{ ref('fct_order_revenue') }}
),

-- 2c. What would correct revenue be? (order-level total_amount, no item join)
correct_revenue as (
    select sum(total_amount) as correct_total_revenue
    from {{ source('raw', 'raw_orders') }}
    where status != 'cancelled'
)

select
    so.source_order_count,
    mr.mart_row_count,
    mr.mart_distinct_orders,
    -- If mart_row_count > source_order_count, grain is violated
    mr.mart_row_count - so.source_order_count       as row_inflation,
    round(
        (mr.mart_row_count::numeric / so.source_order_count - 1) * 100, 1
    )                                               as pct_inflated,
    cr.correct_total_revenue,
    mr.reported_total_revenue,
    mr.reported_total_revenue - cr.correct_total_revenue    as revenue_overcount,
    case
        when mr.mart_row_count > so.source_order_count then 'GRAIN_VIOLATED'
        else 'GRAIN_OK'
    end                                             as grain_status
from source_orders so
cross join mart_rows mr
cross join correct_revenue cr

-- EXPECTED FINDING F-001:
-- source_order_count: 200 | mart_row_count: ~266 | row_inflation: ~66
-- pct_inflated: ~33% | revenue_overcount: ~$127K | grain_status: GRAIN_VIOLATED
-- Root cause: fct_order_revenue joins stg_order_items without pre-aggregating.
-- Orders with 2 items appear twice; orders with 3 items appear three times.
-- Agent action: AUTONOMOUS FIX — deploy fct_order_revenue_fixed.sql

;

-- =============================================================================
-- BLOCK 3: PII EXPOSURE CHECK
-- What: detect PII columns (email, phone, ssn) in mart-layer model outputs
-- Method: check column names in mart models against known PII field names
-- Note: in production, this runs against information_schema; here we inspect
--       the actual fct_customer_metrics output directly.
-- =============================================================================

-- 3a. Detect email exposure in fct_customer_metrics
-- If customer_email is present and non-null, we have a compliance incident.
select
    'fct_customer_metrics'              as model_name,
    'customer_email'                    as exposed_column,
    count(*)                            as row_count,
    count(customer_email)               as non_null_email_count,
    count(distinct customer_email)      as distinct_emails_exposed,
    min(signup_date)                    as earliest_customer_signup,
    max(signup_date)                    as latest_customer_signup,
    -- Exposure window: when did this column first appear?
    -- (In production: query git log / dbt catalog history)
    '2026-02-14'::date                  as estimated_exposure_start,
    (current_date - '2026-02-14'::date) as days_exposed,
    'GDPR Article 5(1)(f) — cross-customer email visibility via API' as violation_type
from {{ ref('fct_customer_metrics') }}

-- EXPECTED FINDING F-003:
-- non_null_email_count: 120 | distinct_emails_exposed: 120
-- days_exposed: ~9 days | violation: GDPR Art 5(1)(f)
-- Agent action: ESCALATE — do not fix autonomously.
--   Build escalation package, notify compliance@acmecorp.com.
--   Block: disable API endpoint reading fct_customer_metrics until resolved.

;

-- 3b. Affected customer IDs (for escalation package)
select
    customer_id,
    customer_email,
    plan,
    country,
    signup_date,
    -- Flag EU customers — higher GDPR notification risk
    case
        when country in ('AT','BE','BG','CY','CZ','DE','DK','EE','ES','FI',
                         'FR','GR','HR','HU','IE','IT','LT','LU','LV','MT',
                         'NL','PL','PT','RO','SE','SI','SK')
        then true
        else false
    end as is_eu_gdpr_subject
from {{ ref('fct_customer_metrics') }}
order by is_eu_gdpr_subject desc, customer_id

-- ESCALATION PACKAGE DATA:
-- Total exposed: 120 customer emails
-- EU/GDPR subjects: count varies by country distribution in seed data
-- All must be listed in the compliance incident report.

;

-- =============================================================================
-- BLOCK 4: METRIC FRAGMENTATION CHECK
-- What: detect revenue definitions that disagree across models
-- Method: compare fct_order_revenue_fixed (accrual) vs fct_revenue_summary (cash)
-- =============================================================================

with accrual_revenue as (
    select
        order_month,
        sum(total_revenue)          as accrual_revenue
    from {{ ref('fct_order_revenue_fixed') }}
    group by 1
),

cash_revenue as (
    select
        order_month,
        sum(total_revenue)          as cash_revenue
    from {{ ref('fct_revenue_summary') }}
    group by 1
)

select
    coalesce(a.order_month, c.order_month)  as month,
    coalesce(a.accrual_revenue, 0)          as accrual_revenue,
    coalesce(c.cash_revenue, 0)             as cash_revenue,
    coalesce(a.accrual_revenue, 0)
    - coalesce(c.cash_revenue, 0)           as discrepancy,
    case
        when abs(
            coalesce(a.accrual_revenue, 0) - coalesce(c.cash_revenue, 0)
        ) > 5000 then 'METRIC_DIVERGENCE'
        else 'WITHIN_TOLERANCE'
    end                                     as alignment_status
from accrual_revenue a
full outer join cash_revenue c
    on a.order_month = c.order_month
order by 1

-- EXPECTED FINDING F-004:
-- January 2026: accrual $1,423,500 | cash $1,343,500 | discrepancy $80,000
-- alignment_status: METRIC_DIVERGENCE
-- Root cause: fct_revenue_summary uses cash-basis / net-of-refunds definition
--             inconsistent with CFO-aligned accrual definition (DEC-012, WT-09)
-- Agent action: AUTONOMOUS FIX — deprecate fct_revenue_summary, add notice,
--               document decomposition of the $80K gap.

;

-- =============================================================================
-- TRIAGE SUMMARY — MONDAY MORNING BRIEF
-- Generated: 2026-02-23 06:47:00 UTC
-- =============================================================================
--
-- This block produces the human-readable brief for the data team arriving at 09:00.
-- In production this would be formatted as a Slack message or email.

select
    finding_id,
    class,
    severity,
    model_affected,
    finding_summary,
    business_impact,
    disposition,
    action_taken,
    escalation_target
from (
    values
    (
        'F-001',
        'Correctness / Grain Violation',
        'CRITICAL',
        'fct_order_revenue',
        'Fan-out join to raw_order_items duplicates multi-item orders',
        'Revenue inflated ~$127K for Jan 2026 (23.5% overcount)',
        'AUTONOMOUS FIX',
        'Deployed fct_order_revenue_fixed.sql. Regression test added: assert_revenue_grain.sql. Original model retained with BUG comments for audit. Data team: please review fix before EOD.',
        null
    ),
    (
        'F-002',
        'Staleness / Phantom Success',
        'HIGH',
        'fct_customer_metrics',
        'Model not refreshed since Thu 2026-02-19 22:14 — 84h stale. Fri/Sat/Sun runs returned warning_cached silently.',
        'Customer-facing dashboards show Thursday data. ~33 weekend signups not reflected.',
        'AUTONOMOUS FIX',
        'Resolved compilation warning (relation already exists conflict). Triggered --full-refresh run. Model now current as of 06:31. Run history: RUN-031.',
        null
    ),
    (
        'F-003',
        'Compliance / PII Exposure',
        'HIGH',
        'fct_customer_metrics',
        'customer_email exposed in customer-facing mart — 120 emails queryable cross-customer via API. Estimated exposure window: 9 days (since 2026-02-14).',
        'GDPR Art 5(1)(f) violation. Cross-customer email visibility. EU/GDPR subjects included.',
        'ESCALATED — DO NOT FIX AUTONOMOUSLY',
        'Escalation package sent to compliance@acmecorp.com at 06:52. Includes: exposure window, affected customer list, EU subject count, suggested immediate actions, draft notification template. API endpoint NOT disabled — awaiting compliance decision on scope.',
        'compliance@acmecorp.com (primary) / legal@acmecorp.com (cc)'
    ),
    (
        'F-004',
        'Metrics / Definition Fragmentation',
        'MEDIUM',
        'fct_revenue_summary vs fct_order_revenue',
        'Two revenue definitions disagree by $80K for Jan 2026. Cash-basis (fct_revenue_summary) vs accrual-basis (fct_order_revenue_fixed).',
        '$80K discrepancy = $52K refund timing + $22K accrual timing + $6K free-plan treatment. No incorrect data — different valid definitions.',
        'AUTONOMOUS FIX',
        'Marked fct_revenue_summary DEPRECATED with full explanation of $80K gap. Canonical definition confirmed as accrual-basis per DEC-012 (WT-09 CFO alignment). Data team: communicate deprecation to Finance team before 2026-03-31 cutover.',
        null
    )
) as t(finding_id, class, severity, model_affected, finding_summary, business_impact, disposition, action_taken, escalation_target)
order by
    case severity when 'CRITICAL' then 1 when 'HIGH' then 2 when 'MEDIUM' then 3 else 4 end
