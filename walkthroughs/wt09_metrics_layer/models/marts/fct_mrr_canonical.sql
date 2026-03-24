-- fct_mrr_canonical: Canonical Board MRR
--
-- Business definition (agreed Finance sign-off, 2025-12-18):
--   Monthly Recurring Revenue = subscription invoice amounts for active recurring
--   contracts, recognized on invoice date (accrual basis), for the calendar month
--   in which the invoice is dated.
--
-- Canonical rules:
--   1. Recognition basis : invoice_date — NOT payment_date, NOT contract start_date
--   2. Invoice type      : 'subscription' only — excludes 'setup', 'credit', all others
--   3. Invoice status    : 'paid' only — excludes 'pending' and 'void'
--   4. Contract type     : 'recurring' only — excludes 'pilot', 'professional_services'
--   5. Contract status   : 'active' only — excludes 'churned', 'pending'
--
-- What this excludes and why:
--   setup fees           → one-time, not recurring by definition
--   credits              → contra-revenue, track separately; not MRR by SaaS convention
--   pending invoices     → not yet earned; including would overstate recognized revenue
--   pilot contracts      → conditional revenue; not committed, not board-reportable
--   professional_services→ project revenue, not subscription MRR
--   churned contracts    → no active service; including would be fictitious revenue
--
-- Board number for December 2025: $1,260,000
-- Deprecates: fct_revenue_monthly, fct_arr_by_account, fct_marketing_revenue

with invoices as (
    select * from {{ ref('stg_invoices') }}
),

contracts as (
    select * from {{ ref('stg_contracts') }}
),

accounts as (
    select * from {{ source('raw', 'raw_accounts') }}
),

canonical as (
    select
        i.invoice_month                                   as revenue_month,
        i.account_id,
        i.contract_id,
        a.segment,
        sum(i.amount)                                     as mrr,
        -- Explicit definition flags (make the business rules visible in the model)
        true                                              as is_recurring,
        true                                              as is_active,
        true                                              as is_paid_invoice,
        false                                             as is_pilot
    from invoices i
    join contracts c
        on i.contract_id = c.contract_id
    join accounts a
        on c.account_id = a.account_id
    where i.type    = 'subscription'    -- RULE 2: no setup fees, no credits
      and i.status  = 'paid'            -- RULE 3: no pending, no void
      and c.type    = 'recurring'       -- RULE 4: no pilots, no professional_services
      and c.status  = 'active'          -- RULE 5: no churned
    group by 1, 2, 3, 4
)

select
    revenue_month,
    account_id,
    contract_id,
    segment,
    mrr,
    is_recurring,
    is_active,
    is_paid_invoice,
    is_pilot
from canonical
order by revenue_month, account_id
