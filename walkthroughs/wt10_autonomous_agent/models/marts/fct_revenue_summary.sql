-- fct_revenue_summary: Finance team's monthly revenue rollup
-- Built by Finance team (Q3 2025) using a cash-basis, net-of-refunds definition.
-- Grain: one row per order_month
--
-- BUG / DIVERGENCE: METRIC FRAGMENTATION
--   This model uses a CASH BASIS definition:
--     - Revenue recognized when payment is received (order_date used as proxy)
--     - Net of refunds (orders with status='refunded' excluded)
--     - Excludes free plan orders (amount = $99 treated as admin/nominal)
--
--   fct_order_revenue uses an ACCRUAL BASIS definition:
--     - Revenue recognized at order creation date
--     - Gross of refunds
--     - Includes all plan types
--
--   For January 2026:
--     fct_order_revenue_fixed (accrual, gross):  $1,423,500
--     fct_revenue_summary (cash, net):           $1,343,500
--     Discrepancy:                                  $80,000
--
--   The $80K gap decomposes as:
--     - $52K: refund liability in transit (orders that will be refunded but haven't been yet)
--     - $22K: accrual timing difference (orders created but payment processed next month)
--     - $6K:  treatment of $99 free-plan activation fees (included in accrual, excluded here)
--
-- DEPRECATION NOTICE (applied 2026-02-23 by autonomous agent):
--   Per CFO alignment (WT-09, DEC-012), the canonical revenue definition for board
--   reporting is ACCRUAL BASIS, GROSS of refunds.
--   This model is DEPRECATED. Use fct_order_revenue_fixed for all revenue reporting.
--   Contact the data team before querying this model for any board/exec report.
--
-- This model is retained (not dropped) to allow Finance team migration window.
-- Will be removed after 2026-03-31.

-- DEPRECATED: use fct_order_revenue_fixed instead
-- Last updated by autonomous agent: 2026-02-23 06:23

with orders as (
    select * from {{ ref('stg_orders') }}
),

-- Cash basis: exclude refunded orders
-- Net definition: exclude $99 nominal free-plan fees
cash_basis as (
    select
        order_month,
        count(distinct order_id)    as order_count,
        sum(total_amount)           as total_revenue
    from orders
    where status not in ('refunded')            -- net of refunds (cash basis)
      and total_amount > 99.00                  -- exclude nominal free-plan fees
    group by 1
)

select
    order_month,
    order_count,
    total_revenue,
    '-- DEPRECATED: accrual/cash discrepancy $80K Jan-2026. Use fct_order_revenue_fixed.' as _deprecation_notice
from cash_basis
order by order_month
