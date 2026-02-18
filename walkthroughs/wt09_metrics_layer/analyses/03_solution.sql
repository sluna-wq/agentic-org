-- WT-09: Building the Metrics Layer
-- Phase 4: Build fct_mrr_canonical
-- This is the implementation to put in models/marts/fct_mrr_canonical.sql

-- Canonical MRR definition (agreed with Finance, 2025-12-18):
--   1. Accrual basis: invoice_date (not payment_date, not contract start_date)
--   2. Subscription revenue only: invoice.type = 'subscription'
--   3. Active recurring contracts only: contract.type = 'recurring' AND contract.status = 'active'
--   4. Paid invoices only: invoice.status = 'paid'
--   5. Excludes: setup fees, credits, professional services, pilots, churned contracts

SELECT
    date_trunc('month', i.invoice_date)::date AS revenue_month,
    c.account_id,
    a.segment,
    a.industry,
    a.sales_rep,
    c.contract_id,
    c.type AS contract_type,
    c.status AS contract_status,
    i.amount AS mrr,
    -- Metadata for auditability
    COUNT(i.invoice_id) OVER (
        PARTITION BY c.account_id, date_trunc('month', i.invoice_date)
    ) AS invoices_in_month,
    -- Flags for downstream analysis
    TRUE AS is_recurring,
    FALSE AS includes_pilots,
    FALSE AS includes_setup_fees,
    'invoice_date' AS recognition_basis
FROM {{ ref('stg_invoices') }} i
JOIN {{ ref('stg_contracts') }} c
    ON i.contract_id = c.contract_id
JOIN {{ ref('stg_accounts') }} a
    ON c.account_id = a.account_id
WHERE i.type = 'subscription'        -- subscription invoices only
  AND i.status = 'paid'              -- paid only (accrual basis, confirmed)
  AND c.type = 'recurring'           -- no pilots, no professional_services
  AND c.status = 'active'            -- no churned contracts

-- Validation check: run this after building to confirm board number
-- SELECT revenue_month, SUM(mrr) FROM fct_mrr_canonical WHERE revenue_month = '2025-12-01' GROUP BY 1;
-- Expected: $1,260,000
