-- analyses/02_trace_conflicts.sql
--
-- PURPOSE: Decompose the delta between team definitions order by order.
-- After 01_detect_conflicts.sql shows you the three totals, this file
-- answers: WHY are the numbers different? Which specific orders account
-- for each gap?
--
-- This is the "root cause" step. An agent running this automatically would
-- produce a structured report: "Here are the 3 conflicts and the orders
-- that demonstrate each one." That report goes to the CFO as the basis
-- for the three decisions.
--
-- CONFLICT TAXONOMY:
--   Conflict #1 — Status filter gap (Finance vs Sales)
--   Conflict #2 — Date field shift (orders that cross month boundaries)
--   Conflict #3 — FX conversion gap (Product vs Sales on non-USD orders)

-- ============================================================
-- CONFLICT #1: STATUS FILTER
-- Which orders does Finance count that Sales does NOT count?
-- Answer: all 'invoiced' orders in the recognized month.
-- These are orders where the invoice was sent and revenue recognized
-- (Finance counts them) but cash hasn't arrived (Sales doesn't see them
-- as "completed deals").
-- ============================================================
with conflict_1_status as (

    select
        order_id,
        customer_id,
        status,
        currency,
        amount_usd_face,
        created_at,
        recognized_at,
        'conflict_1_status_filter'          as conflict_type,
        'in Finance, NOT in Sales'          as description,
        -- The dollar amount at stake in this conflict for this order
        amount_usd_face                     as delta_usd
    from {{ ref('fct_orders') }}
    where
        -- Finance includes these; Sales does not.
        status = 'invoiced'
        -- Within January 2026 on the Finance date basis (recognized_at)
        and recognized_at is not null
        and date_trunc('month', recognized_at) = '2026-01-01'

),

-- ============================================================
-- CONFLICT #2: DATE FIELD SHIFT
-- Which orders appear in a DIFFERENT month depending on whether you
-- use created_at, paid_at, or recognized_at?
-- These are "boundary orders" — placed in December but recognized in
-- January, or placed in January but recognized in February.
-- The same order counts as January revenue under one definition and
-- December (or February) revenue under another.
-- ============================================================
conflict_2_date_shift as (

    select
        order_id,
        customer_id,
        status,
        currency,
        amount_usd_face,
        created_at,
        paid_at,
        recognized_at,
        date_trunc('month', created_at)     as sales_month,
        date_trunc('month', paid_at)        as product_month,
        date_trunc('month', recognized_at)  as finance_month,
        'conflict_2_date_field'             as conflict_type,

        -- Describe which months this order lands in under each definition
        case
            when date_trunc('month', created_at)    != date_trunc('month', recognized_at)
            and  date_trunc('month', paid_at)       != date_trunc('month', recognized_at)
                then 'all three definitions assign different months'
            when date_trunc('month', created_at)    != date_trunc('month', recognized_at)
                then 'Sales and Finance assign different months'
            when date_trunc('month', paid_at)       != date_trunc('month', recognized_at)
                then 'Product and Finance assign different months'
            else 'no date conflict for this order'
        end                                 as description,

        amount_usd_face                     as delta_usd

    from {{ ref('fct_orders') }}
    where
        -- Orders where the three date fields land in different months
        status in ('completed', 'invoiced')
        and recognized_at is not null
        and paid_at is not null
        and (
            date_trunc('month', created_at)    != date_trunc('month', recognized_at)
            or date_trunc('month', paid_at)    != date_trunc('month', recognized_at)
        )
        -- Focus on orders touching January 2026 under any definition
        and (
            date_trunc('month', created_at)    = '2026-01-01'
            or date_trunc('month', paid_at)    = '2026-01-01'
            or date_trunc('month', recognized_at) = '2026-01-01'
        )

),

-- ============================================================
-- CONFLICT #3: FX CONVERSION
-- Which orders produce a different USD total depending on whether
-- you use face value (Sales, Finance) vs FX-converted (Product)?
-- These are all non-USD orders. The delta is:
--   amount_usd_converted - amount_usd_face
-- A positive delta means the foreign currency is worth MORE than
-- face value (e.g., GBP order for 6200 GBP face-valued at $6200 USD
-- but worth ~$7,893 at 1.274 rate).
-- ============================================================
conflict_3_fx as (

    select
        order_id,
        customer_id,
        status,
        currency,
        amount_usd_face,
        amount_usd_converted,
        round(amount_usd_converted - amount_usd_face, 2)
                                            as fx_delta_usd,
        fx_conversion_date,
        recognized_at,
        'conflict_3_fx_conversion'          as conflict_type,
        'FX-converted differs from face value: '
            || currency
            || ' order worth $'
            || round(amount_usd_face, 0)
            || ' face but $'
            || round(amount_usd_converted, 0)
            || ' converted'
                                            as description,
        round(amount_usd_converted - amount_usd_face, 2)
                                            as delta_usd

    from {{ ref('fct_orders') }}
    where
        -- Only non-USD orders have FX impact
        currency != 'USD'
        and is_revenue_recognized = true
        and recognized_at is not null
        and date_trunc('month', recognized_at) = '2026-01-01'

),

-- ============================================================
-- SUMMARY: Total dollar impact of each conflict
-- This is the one-page executive summary for the CFO.
-- "Here are the three things you need to decide, and here is
-- what each decision is worth in revenue for January 2026."
-- ============================================================
conflict_summary as (

    select
        'Conflict #1: Status filter' as conflict,
        'invoiced orders Finance counts but Sales does not' as root_cause,
        count(*) as order_count,
        round(sum(delta_usd), 2) as dollar_impact,
        'CFO must decide: should accrued-but-unpaid invoices count as revenue?' as decision_required
    from conflict_1_status

    union all

    select
        'Conflict #2: Date field' as conflict,
        'orders that cross month boundaries depending on date basis' as root_cause,
        count(*) as order_count,
        round(sum(delta_usd), 2) as dollar_impact,
        'CFO must decide: which date defines "when" revenue happened — deal date, payment date, or recognition date?' as decision_required
    from conflict_2_date_shift

    union all

    select
        'Conflict #3: FX conversion' as conflict,
        'non-USD orders reported at face value vs spot-rate USD' as root_cause,
        count(*) as order_count,
        round(sum(delta_usd), 2) as dollar_impact,
        'CFO must decide: should FX conversion be applied, and at which date?' as decision_required
    from conflict_3_fx

)

-- ============================================================
-- FINAL OUTPUT: The three conflicts with order detail
-- Run the summary query first. Then inspect each conflict CTE for
-- the specific orders that are causing each gap.
-- ============================================================
select * from conflict_summary
order by conflict;

-- To inspect individual orders for each conflict, run these separately:
/*
-- Conflict #1 orders (invoiced, in Finance not Sales):
select * from conflict_1_status order by recognized_at;

-- Conflict #2 orders (cross-month boundary):
select order_id, currency, amount_usd_face,
       sales_month, product_month, finance_month, description
from conflict_2_date_shift order by recognized_at;

-- Conflict #3 orders (FX impact):
select order_id, currency, amount_usd_face, amount_usd_converted, fx_delta_usd
from conflict_3_fx order by abs(fx_delta_usd) desc;
*/
