-- SOLUTION: Canonical MRR
-- Definition: Monthly recurring subscription revenue, accrual basis
-- Excludes: setup fees, pilots, churned contracts, pending/void invoices
-- Recognition: invoice_date (not contract date, not payment date)
-- Signed off by: Finance team (board reporting standard)

-- TODO: Build this model during the walkthrough.
-- See analyses/03_solution.sql for the implementation.

-- Hint: Start from stg_invoices JOIN stg_contracts
-- Filter: i.type = 'subscription', i.status = 'paid', c.type = 'recurring', c.status = 'active'
-- Group by: date_trunc('month', invoice_date), account_id

SELECT
    NULL::date      AS revenue_month,
    NULL::varchar   AS account_id,
    NULL::varchar   AS segment,
    NULL::numeric   AS mrr
WHERE 1=0  -- placeholder
