-- assert_mrr_no_one_time.sql
-- CI gate: fails if any one-time or setup invoice type appears in fct_mrr_canonical
--
-- Business contract (agreed 2025-12-18):
--   MRR = Monthly Recurring Revenue.
--   Setup fees, credits, and professional services invoices are non-recurring.
--   They must never appear in canonical MRR regardless of the underlying contract type.
--
-- How it works:
--   Join fct_mrr_canonical back to stg_invoices on (contract_id, revenue_month).
--   Any invoice where type != 'subscription' linked to a canonical MRR row is a violation.
--   dbt fails this test if the query returns any rows.

WITH invoice_violations AS (
    SELECT
        f.revenue_month,
        f.account_id,
        f.contract_id,
        i.invoice_id,
        i.type AS invoice_type,
        i.amount AS violation_amount
    FROM {{ ref('fct_mrr_canonical') }} f
    JOIN {{ ref('stg_invoices') }} i
        ON  f.contract_id = i.contract_id
        AND date_trunc('month', i.invoice_date)::date = f.revenue_month
    WHERE i.type != 'subscription'
      AND i.status = 'paid'
)

SELECT
    revenue_month,
    account_id,
    contract_id,
    invoice_id,
    invoice_type,
    violation_amount
FROM invoice_violations
-- dbt test fails if this query returns any rows
