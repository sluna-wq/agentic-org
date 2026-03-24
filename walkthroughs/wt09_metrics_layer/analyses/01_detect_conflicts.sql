-- analyses/01_detect_conflicts.sql
--
-- PURPOSE: Run all three team definitions side by side on January 2026.
-- This is the first thing an analyst (or an agent) should run when
-- confronted with "three teams have three different revenue numbers."
--
-- EXPECTED OUTPUT (against the seed data):
--   sales_revenue_jan_2026:    ~$143,200  (completed, created_at, face USD)
--   finance_revenue_jan_2026:  ~$246,800  (completed+invoiced, recognized_at, face USD)
--   product_revenue_jan_2026:  ~$148,450  (completed, paid_at, FX-converted)
--
-- The gap between Finance and Sales (~$103,600) is almost entirely explained
-- by the status filter: Finance includes invoiced orders that Sales excludes.
-- Run analyses/02_trace_conflicts.sql to decompose each gap order-by-order.
--
-- The gap between Product and Sales (~$5,250) is almost entirely explained
-- by FX conversion: Product converts GBP/EUR orders to USD at spot rates,
-- while Sales uses face value. Run 02_trace_conflicts.sql to see which orders
-- are the FX contributors.

-- ============================================================
-- STEP 1: SALES TEAM DEFINITION
-- "Monthly revenue" = completed orders, grouped by created_at month,
-- face-value USD (no FX conversion).
--
-- Why Sales does this: The CRM marks a deal "won" when the order is
-- created and status is set to 'completed'. Sales reps are measured on
-- created_at month. Invoiced orders are not in the CRM view because
-- the billing system sends invoices for enterprise deals after a deal
-- is marked won-pending-payment.
-- ============================================================
with sales_revenue as (

    select
        date_trunc('month', created_at)     as revenue_month,
        'sales'                             as team,
        'completed only'                    as status_filter,
        'created_at'                        as date_field,
        'USD face value (no FX)'            as currency_method,
        count(*)                            as order_count,
        sum(amount_usd_face)                as total_revenue_usd
    from {{ ref('fct_orders') }}
    where
        -- CONFLICT #1: Sales only counts 'completed' orders.
        -- The 'invoiced' status doesn't exist in the Sales CRM view.
        status = 'completed'
        -- CONFLICT #2: Sales uses created_at as the date basis.
        -- Revenue is attributed to the month the deal was created.
        and date_trunc('month', created_at) = '2026-01-01'
    group by 1, 2, 3, 4, 5

),

-- ============================================================
-- STEP 2: FINANCE TEAM DEFINITION
-- "Monthly revenue" = completed + invoiced orders, grouped by recognized_at
-- month, face-value USD.
--
-- Why Finance does this: Finance uses accrual accounting. An approved
-- invoice creates an accounts receivable — the revenue is "earned" when
-- the invoice is sent, not when cash arrives. recognized_at is set by
-- the ERP when Finance approves the invoice. They use face-value USD
-- because FX gains/losses are a separate line item in the P&L and are
-- not bundled into the revenue line.
-- ============================================================
finance_revenue as (

    select
        date_trunc('month', recognized_at)  as revenue_month,
        'finance'                           as team,
        'completed + invoiced'              as status_filter,
        'recognized_at'                     as date_field,
        'USD face value (no FX)'            as currency_method,
        count(*)                            as order_count,
        sum(amount_usd_face)                as total_revenue_usd
    from {{ ref('fct_orders') }}
    where
        -- CONFLICT #1: Finance counts both 'completed' and 'invoiced'.
        -- Invoiced orders are accounts receivable — recognized revenue
        -- even if cash hasn't arrived.
        status in ('completed', 'invoiced')
        -- CONFLICT #2: Finance uses recognized_at, not created_at.
        -- For invoiced orders this may be days or weeks after created_at.
        and recognized_at is not null
        and date_trunc('month', recognized_at) = '2026-01-01'
    group by 1, 2, 3, 4, 5

),

-- ============================================================
-- STEP 3: PRODUCT TEAM DEFINITION
-- "Monthly revenue" = completed (paid) orders, grouped by paid_at month,
-- FX-converted to USD at spot rate.
--
-- Why Product does this: The Product team built this metric to measure
-- "successful purchase events" — moments when a customer completed checkout
-- and money arrived in the bank. paid_at is the most direct timestamp for
-- this event. The analyst who built it correctly noticed that GBP and EUR
-- orders at face value USD inflates the number when GBP > 1 USD, and added
-- FX conversion. They never looped in Finance or Sales when building it.
-- ============================================================
product_revenue as (

    select
        date_trunc('month', paid_at)        as revenue_month,
        'product'                           as team,
        'completed with paid_at'            as status_filter,
        'paid_at'                           as date_field,
        'FX-converted to USD at spot rate'  as currency_method,
        count(*)                            as order_count,
        sum(amount_usd_converted)           as total_revenue_usd
    from {{ ref('fct_orders') }}
    where
        -- CONFLICT #1: Product only counts 'completed' orders where
        -- paid_at is not null. Invoiced orders are excluded because
        -- cash hasn't arrived. Pending orders are excluded.
        status = 'completed'
        and paid_at is not null
        -- CONFLICT #2: Product uses paid_at as the date basis.
        -- For most orders this is 1-3 days after created_at.
        and date_trunc('month', paid_at) = '2026-01-01'
    group by 1, 2, 3, 4, 5

),

-- ============================================================
-- STEP 4: SIDE-BY-SIDE COMPARISON
-- Put all three definitions in one result set so the discrepancy
-- is immediately visible. This is the output to show the CFO.
-- ============================================================
all_three as (

    select * from sales_revenue
    union all
    select * from finance_revenue
    union all
    select * from product_revenue

)

select
    team,
    revenue_month,
    status_filter,
    date_field,
    currency_method,
    order_count,
    round(total_revenue_usd, 2)             as total_revenue_usd

from all_three
order by team;

-- ============================================================
-- SUPPLEMENTAL: Show the three totals as a single pivot-style row
-- for a quick "which number do I tell the CFO?" view.
-- ============================================================

-- (Run this as a separate query)
/*
select
    round(sum(case when team = 'sales'   then total_revenue_usd end), 2) as sales_total,
    round(sum(case when team = 'finance' then total_revenue_usd end), 2) as finance_total,
    round(sum(case when team = 'product' then total_revenue_usd end), 2) as product_total,
    round(
        sum(case when team = 'finance' then total_revenue_usd end) -
        sum(case when team = 'sales'   then total_revenue_usd end),
        2
    )                                                                    as finance_minus_sales,
    round(
        sum(case when team = 'product' then total_revenue_usd end) -
        sum(case when team = 'sales'   then total_revenue_usd end),
        2
    )                                                                    as product_minus_sales
from (
    -- paste the all_three CTE result here
)
*/
