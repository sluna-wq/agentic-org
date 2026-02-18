-- Finance metric: includes all invoice types and statuses. See fct_mrr_canonical for board-reporting MRR.
--
-- BUG 1: Includes setup fee invoices (type = 'setup') — one-time fees inflate MRR by ~$80k in Dec 2025.
--         Fix: add WHERE i.type = 'subscription' (or at minimum exclude 'setup').
--
-- BUG 2: Includes pending invoices (status = 'pending') — uninvoiced bookings inflate MRR by ~$30k.
--         Fix: add WHERE i.status = 'paid'.
--
-- BUG 3: Includes credit invoices (type = 'credit') — negative amounts that partially offset bug 1.
--         Credits are legitimately part of net revenue but not of MRR by SaaS convention.
--         Fix: exclude credits from the MRR definition; track separately if needed.
--
-- Result for Dec 2025: ~$1,370,000 (canonical is $1,260,000; delta = +$110k)

with invoices as (
    select * from {{ ref('stg_invoices') }}
),

contracts as (
    select * from {{ ref('stg_contracts') }}
),

joined as (
    select
        i.invoice_month                                     as revenue_month,
        i.account_id,
        c.type                                              as contract_type,
        i.type                                              as invoice_type,
        i.status                                            as invoice_status,
        i.amount
    from invoices i
    left join contracts c
        on i.contract_id = c.contract_id
    -- BUG 1: no filter on i.type — setup fees included
    -- BUG 2: no filter on i.status — pending invoices included
    -- BUG 3: credits included (negative amounts soften but don't fix the overcount)
),

monthly as (
    select
        revenue_month,
        count(distinct account_id)  as account_count,
        sum(amount)                 as total_revenue
    from joined
    group by 1
)

select *
from monthly
order by revenue_month
