-- analyses/03_canonical_metrics.sql
--
-- PURPOSE: The canonical revenue query after CFO decisions are locked.
--
-- CFO DECISIONS APPLIED (signed off 2026-01-31):
--   Decision 1 — Status: completed + invoiced  (accrual basis)
--   Decision 2 — Date: recognized_at           (GAAP recognition date)
--   Decision 3 — Currency: FX-converted at spot rate on recognized_at
--
-- This query produces the "one number" the CFO asked for.
-- It is the source of truth that all dashboards should query.
-- It also demonstrates that the three team definitions reconcile
-- to this single number when the three decisions are applied.
--
-- RUN ORDER:
--   1. dbt seed && dbt run
--   2. Run 01_detect_conflicts.sql — see the three different totals
--   3. Run 02_trace_conflicts.sql  — understand why they differ
--   4. Make the three CFO decisions
--   5. Run this file — see the canonical number
--   6. Run tests/assert_no_revenue_without_date.sql — validate data quality

-- ============================================================
-- CANONICAL MONTHLY REVENUE — JANUARY 2026
-- The one number.
-- ============================================================
with canonical_revenue as (

    select
        date_trunc('month', recognized_at)      as revenue_month,
        count(*)                                as order_count,
        count(case when currency != 'USD' then 1 end)
                                                as fx_order_count,

        -- The canonical USD revenue total (FX-converted, accrual basis)
        round(sum(amount_usd_converted), 2)     as total_revenue_usd,

        -- For audit: what would face-value USD have been?
        round(sum(amount_usd_face), 2)          as total_revenue_usd_face_value,

        -- FX impact: how much did currency conversion change the number?
        round(sum(amount_usd_converted) - sum(amount_usd_face), 2)
                                                as fx_conversion_impact_usd,

        -- Percentage of revenue from non-USD orders (after conversion)
        round(
            100.0 * sum(case when currency != 'USD' then amount_usd_converted else 0 end)
            / nullif(sum(amount_usd_converted), 0),
            1
        )                                       as pct_revenue_non_usd

    from {{ ref('fct_orders') }}
    where
        -- Decision 1: Include completed AND invoiced (accrual basis)
        is_revenue_recognized = true
        -- Decision 2: Use recognized_at as the date basis
        and recognized_at is not null
        and date_trunc('month', recognized_at) = '2026-01-01'
        -- Decision 3: FX conversion is applied in fct_orders via amount_usd_converted
    group by 1

),

-- ============================================================
-- REVENUE BY STATUS BUCKET
-- Show the composition: how much is from completed vs invoiced?
-- This transparency is valuable for the CFO — it shows the
-- accounts-receivable component of the monthly number.
-- ============================================================
revenue_by_status as (

    select
        date_trunc('month', recognized_at)      as revenue_month,
        status,
        count(*)                                as order_count,
        round(sum(amount_usd_converted), 2)     as revenue_usd
    from {{ ref('fct_orders') }}
    where
        is_revenue_recognized = true
        and recognized_at is not null
        and date_trunc('month', recognized_at) = '2026-01-01'
    group by 1, 2

),

-- ============================================================
-- REVENUE BY CURRENCY BUCKET
-- Show the FX exposure: how much revenue is in each currency
-- before and after conversion?
-- ============================================================
revenue_by_currency as (

    select
        date_trunc('month', recognized_at)      as revenue_month,
        currency,
        count(*)                                as order_count,
        round(sum(amount_local), 2)             as revenue_local_currency,
        round(sum(amount_usd_converted), 2)     as revenue_usd_converted,
        round(sum(amount_usd_face), 2)          as revenue_usd_face,
        round(sum(amount_usd_converted) - sum(amount_usd_face), 2)
                                                as fx_impact_usd
    from {{ ref('fct_orders') }}
    where
        is_revenue_recognized = true
        and recognized_at is not null
        and date_trunc('month', recognized_at) = '2026-01-01'
    group by 1, 2

),

-- ============================================================
-- RECONCILIATION WITH OLD TEAM DEFINITIONS
-- Confirm that the canonical number makes sense relative to what
-- each team was previously reporting. Document the delta and why.
-- This output goes to each team lead as part of the transition.
-- ============================================================
reconciliation as (

    select
        'Sales (completed, created_at, face USD)'       as old_definition,
        round(sum(case when status = 'completed'
            and date_trunc('month', created_at) = '2026-01-01'
            then amount_usd_face else 0 end), 2)        as old_total,

        round((select sum(amount_usd_converted)
               from {{ ref('fct_orders') }}
               where is_revenue_recognized = true
               and recognized_at is not null
               and date_trunc('month', recognized_at) = '2026-01-01'), 2)
                                                        as canonical_total,

        round(
            (select sum(amount_usd_converted)
             from {{ ref('fct_orders') }}
             where is_revenue_recognized = true
             and recognized_at is not null
             and date_trunc('month', recognized_at) = '2026-01-01')
            -
            sum(case when status = 'completed'
                and date_trunc('month', created_at) = '2026-01-01'
                then amount_usd_face else 0 end),
            2
        )                                               as delta_vs_canonical,

        'Sales counted only completed, used deal date, ignored FX' as delta_explanation

    from {{ ref('fct_orders') }}
    where date_trunc('month', created_at) = '2026-01-01'

)

-- ============================================================
-- OUTPUT 1: The canonical number (the one number for the CFO)
-- ============================================================
select
    'CANONICAL REVENUE — January 2026'      as report,
    revenue_month,
    order_count,
    fx_order_count                          as orders_requiring_fx_conversion,
    total_revenue_usd                       as total_revenue_usd_canonical,
    total_revenue_usd_face_value,
    fx_conversion_impact_usd,
    pct_revenue_non_usd                     as pct_non_usd_orders
from canonical_revenue;

/*
-- OUTPUT 2: Revenue composition by status
select * from revenue_by_status order by status;

-- OUTPUT 3: Revenue by currency with FX impact
select * from revenue_by_currency order by currency;

-- OUTPUT 4: Reconciliation vs old definitions
select * from reconciliation;
*/
