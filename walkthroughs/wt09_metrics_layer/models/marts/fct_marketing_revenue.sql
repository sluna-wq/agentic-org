-- Marketing metric: cash-basis revenue including professional services. See fct_mrr_canonical for board-reporting MRR.
--
-- BUG 1: Uses payment_date (cash basis) instead of invoice_date (accrual basis).
--         Cash timing differs from accrual by days to weeks. Dec 2025 is understated
--         because some Dec invoices were paid in Jan 2026, and Nov invoices paid in Dec inflate the month.
--         Fix: join to stg_invoices and group by invoice_date, not payment_date.
--
-- BUG 2: Includes payments for professional_services contracts (no filter on contract type).
--         Professional services are project revenue, not recurring subscriptions.
--         Inflates MRR by the professional services billings in that payment month.
--         Fix: join stg_contracts and add WHERE c.type = 'recurring'.
--
-- BUG 3: Zeroes out refunded payments (net basis) — this is conceptually reasonable
--         but creates inconsistency with accrual-basis models.
--         stg_payments already handles the zero-out, so this model inherits it.
--         Fix: decide on one definition; for MRR, use invoice basis and track refunds separately.
--
-- Result for Dec 2025: ~$1,190,000 (canonical is $1,260,000; delta = -$70k, cash timing lag)

with payments as (
    select * from {{ ref('stg_payments') }}
),

invoices as (
    select * from {{ ref('stg_invoices') }}
),

contracts as (
    select * from {{ ref('stg_contracts') }}
),

joined as (
    select
        p.payment_id,
        p.account_id,
        p.invoice_id,
        p.payment_month,                                    -- BUG 1: cash basis, not invoice_date
        p.amount,                                           -- BUG 3: already zeroed for refunds
        p.refunded,
        c.type                                              as contract_type
    from payments p
    left join invoices i
        on p.invoice_id = i.invoice_id
    left join contracts c
        on i.contract_id = c.contract_id
    -- BUG 2: no filter on c.type — professional services included
    where p.amount > 0                                      -- exclude zeroed refunds from aggregation
),

monthly as (
    select
        payment_month                                       as revenue_month,
        count(distinct account_id)                          as account_count,
        sum(amount)                                         as cash_revenue
    from joined
    group by 1
)

select *
from monthly
order by revenue_month
