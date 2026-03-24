-- assert_mrr_no_one_time.sql
-- CI gate: fails if fct_mrr_canonical includes any non-subscription invoice amounts
--
-- Business contract (agreed 2025-12-18):
--   MRR = Monthly Recurring Revenue.
--   Setup fees, credits, and professional services are non-recurring.
--   They must never contribute to canonical MRR regardless of contract type.
--
-- How it works:
--   Recompute what fct_mrr_canonical SHOULD be from first principles.
--   If canonical's mrr for a (account_id, contract_id, revenue_month) differs
--   from the sum of paid subscription invoices for that same group, something
--   non-subscription slipped in.
--
-- Note on test design:
--   The naive approach (join canonical back to stg_invoices and look for
--   i.type != 'subscription') produces false positives: an account can have
--   both a subscription invoice and a setup/credit invoice on the same contract
--   in the same month. That setup invoice is NOT in canonical, but the join
--   finds it anyway. This version avoids that by comparing aggregated amounts.
--
-- dbt fails this test if the query returns any rows.

WITH expected AS (
    -- What canonical MRR SHOULD be, computed from raw invoices
    SELECT
        date_trunc('month', i.invoice_date)::date  AS revenue_month,
        i.account_id,
        i.contract_id,
        SUM(i.amount)                              AS expected_mrr
    FROM {{ ref('stg_invoices') }} i
    JOIN {{ ref('stg_contracts') }} c
        ON i.contract_id = c.contract_id
    WHERE i.type    = 'subscription'
      AND i.status  = 'paid'
      AND c.type    = 'recurring'
      AND c.status  = 'active'
    GROUP BY 1, 2, 3
),

violations AS (
    SELECT
        f.revenue_month,
        f.account_id,
        f.contract_id,
        f.mrr                   AS actual_mrr,
        e.expected_mrr,
        f.mrr - e.expected_mrr  AS discrepancy
    FROM {{ ref('fct_mrr_canonical') }} f
    JOIN expected e
        ON  f.revenue_month = e.revenue_month
        AND f.account_id    = e.account_id
        AND f.contract_id   = e.contract_id
    WHERE ABS(f.mrr - e.expected_mrr) > 0.01  -- tolerance for floating point
)

SELECT
    revenue_month,
    account_id,
    contract_id,
    actual_mrr,
    expected_mrr,
    discrepancy,
    'Canonical MRR does not match sum of paid subscription invoices — non-subscription amount may have leaked in' AS violation_message
FROM violations
-- dbt test fails if this query returns any rows
