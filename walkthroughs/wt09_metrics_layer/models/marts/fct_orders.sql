-- fct_orders.sql
-- Core fact table for order-level revenue analysis.
-- Joins stg_orders with raw_fx_rates to produce a USD-converted amount
-- at each order's transaction date (paid_at, falling back to created_at
-- for orders without a payment date).
--
-- This model does NOT make a revenue definition choice — it provides all
-- the ingredients (three date fields, both local and converted amounts,
-- status flags) so that metrics models and analyses can apply whichever
-- definition the business has agreed upon.
--
-- The canonical metric definition lives in:
--   models/marts/metrics_canonical.yml   (after CFO decision)
--   analyses/03_canonical_metrics.sql    (verification query)

with orders as (

    select * from {{ ref('stg_orders') }}

),

-- Pull FX rates keyed on the date we want for conversion.
-- We use the date of recognized_at when available (Finance basis),
-- then paid_at (Product basis), then created_at (Sales basis).
-- The conversion date matters: a GBP order placed Jan 1 and paid Jan 15
-- has a meaningfully different USD value depending on which date you use.
fx_rates as (

    select
        date,
        from_currency,
        to_currency,
        rate
    from {{ ref('raw_fx_rates') }}

),

orders_with_conversion_date as (

    select
        o.*,
        -- Determine the conversion date using the priority: recognized > paid > created
        coalesce(
            date(o.recognized_at),
            date(o.paid_at),
            date(o.created_at)
        )                                               as fx_conversion_date

    from orders o

),

orders_with_fx as (

    select
        o.order_id,
        o.customer_id,
        o.status,
        o.currency,
        o.amount_local,

        -- Three date fields preserved for downstream metric flexibility.
        o.created_at,
        o.paid_at,
        o.recognized_at,

        -- Convenience date truncations for monthly reporting.
        date_trunc('month', o.created_at)               as created_month,
        date_trunc('month', o.paid_at)                  as paid_month,
        date_trunc('month', o.recognized_at)            as recognized_month,

        -- USD-converted amount using spot rate at fx_conversion_date.
        -- For USD orders rate is 1.0 (self-join not needed; handled via coalesce).
        -- For non-USD orders we join to fx_rates. If a rate is missing for that
        -- exact date, the converted amount will be NULL — surfaced by the test
        -- tests/assert_no_revenue_without_date.sql.
        case
            when o.currency = 'USD'
                then o.amount_local
            else
                o.amount_local * coalesce(fx.rate, null)
        end                                             as amount_usd_converted,

        -- The face-value USD amount (ignoring currency conversion).
        -- Sales and Finance use this; Product uses amount_usd_converted.
        -- This is Conflict #3's SQL root cause.
        o.amount_local                                  as amount_usd_face,

        -- Boolean flags that encode the business rules each team applies.
        -- These make the metric filter logic transparent and testable.

        -- True for orders that Sales counts as revenue.
        (o.status = 'completed')                        as is_sales_revenue,

        -- True for orders that Finance counts as revenue.
        (o.status in ('completed', 'invoiced'))         as is_finance_revenue,

        -- True for orders that Product counts as revenue.
        (o.status = 'completed' and o.paid_at is not null)
                                                        as is_product_revenue,

        -- True for orders recognized under accrual accounting.
        -- Finance and the canonical definition use this as the primary filter.
        (
            o.status in ('completed', 'invoiced')
            and o.recognized_at is not null
        )                                               as is_revenue_recognized,

        o.fx_conversion_date

    from orders_with_conversion_date o
    left join fx_rates fx
        on  fx.from_currency = o.currency
        and fx.to_currency   = 'USD'
        and fx.date          = o.fx_conversion_date

)

select * from orders_with_fx
