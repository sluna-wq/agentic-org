-- Sales/RevOps metric: contract-based ARR. Includes pilots. See fct_mrr_canonical for board-reporting MRR.
--
-- BUG 1: Uses contract monthly_value (annual_value / 12) instead of invoiced amounts.
--         Contract value and invoiced amounts diverge due to mid-month starts, discounts,
--         and billing schedule differences. This is a timing/recognition mismatch.
--         Fix: join to stg_invoices and sum actual invoice amounts.
--
-- BUG 2: Includes pilot contracts (no filter on c.type = 'recurring').
--         Pilot contracts inflate MRR by ~$140k in Dec 2025 — pilots are not committed revenue.
--         Fix: add WHERE c.type = 'recurring'.
--
-- BUG 3: Uses contract start_date month as the reporting period, not invoice_date.
--         A contract starting Dec 28 counts as Dec even if billing runs in Jan.
--         Fix: group by invoice_month from stg_invoices.
--
-- Result for Dec 2025: ~$1,400,000 (canonical is $1,260,000; delta = +$140k)

with contracts as (
    select * from {{ ref('stg_contracts') }}
),

accounts as (
    select * from {{ source('raw', 'raw_accounts') }}
),

active_contracts as (
    select
        c.contract_id,
        c.account_id,
        c.type                                              as contract_type,
        c.status,
        c.start_date,
        c.end_date,
        c.annual_value,
        c.monthly_value,
        date_trunc('month', c.start_date)::date             as contract_month
    from contracts c
    -- BUG 2: no filter on c.type — pilot contracts are included
    where c.status = 'active'
    -- BUG 3: using contract_month (start_date) not invoice_date
),

monthly as (
    select
        contract_month                                      as revenue_month,
        ac.account_id,
        ac.contract_type,
        sum(ac.monthly_value)                               as mrr,       -- BUG 1: contract basis
        sum(ac.annual_value)                                as arr
    from active_contracts ac
    group by 1, 2, 3
)

select
    revenue_month,
    account_id,
    contract_type,
    mrr,
    arr
from monthly
order by revenue_month, account_id
