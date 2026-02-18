-- WT-09: Building the Metrics Layer
-- Phase 5: Verification
-- Run these after building fct_mrr_canonical to confirm everything is correct

-- Check 1: Board number matches ($1,260,000)
SELECT
    revenue_month,
    SUM(mrr) AS canonical_mrr,
    CASE
        WHEN ABS(SUM(mrr) - 1260000) < 1000 THEN 'PASS — Board number confirmed'
        ELSE 'FAIL — Unexpected value: ' || SUM(mrr)::text
    END AS board_check
FROM {{ ref('fct_mrr_canonical') }}
WHERE revenue_month = '2025-12-01'
GROUP BY 1;

-- Check 2: No pilots in canonical MRR
SELECT
    c.type AS contract_type,
    COUNT(DISTINCT f.account_id) AS accounts,
    SUM(f.mrr) AS revenue
FROM {{ ref('fct_mrr_canonical') }} f
JOIN {{ ref('stg_contracts') }} c ON f.contract_id = c.contract_id
WHERE f.revenue_month = '2025-12-01'
GROUP BY 1;
-- Expected: only 'recurring' rows

-- Check 3: No setup fees (invoice type check)
SELECT
    COUNT(*) AS setup_fee_invoices_in_canonical
FROM {{ ref('fct_mrr_canonical') }} f
JOIN {{ ref('stg_invoices') }} i ON f.contract_id = i.contract_id
    AND date_trunc('month', i.invoice_date) = f.revenue_month
WHERE i.type != 'subscription'
  AND f.revenue_month = '2025-12-01';
-- Expected: 0

-- Check 4: Finance metric now agrees with canonical (after Finance cleanup)
-- (This check is aspirational — Finance model still has bugs until they clean it up)
-- But we can check the delta is understood and documented
SELECT
    'canonical' AS metric, SUM(mrr) AS dec_2025_revenue
FROM {{ ref('fct_mrr_canonical') }} WHERE revenue_month = '2025-12-01'
UNION ALL
SELECT
    'finance_current', SUM(revenue)
FROM {{ ref('fct_revenue_monthly') }} WHERE revenue_month = '2025-12-01'
UNION ALL
SELECT
    'delta',
    (SELECT SUM(revenue) FROM {{ ref('fct_revenue_monthly') }} WHERE revenue_month = '2025-12-01')
    - (SELECT SUM(mrr) FROM {{ ref('fct_mrr_canonical') }} WHERE revenue_month = '2025-12-01');

-- Check 5: MRR trend looks reasonable (no sudden jumps)
SELECT
    revenue_month,
    SUM(mrr) AS canonical_mrr,
    ROUND(100.0 * (SUM(mrr) - LAG(SUM(mrr)) OVER (ORDER BY revenue_month))
          / LAG(SUM(mrr)) OVER (ORDER BY revenue_month), 1) AS mom_growth_pct
FROM {{ ref('fct_mrr_canonical') }}
GROUP BY 1
ORDER BY 1;
-- Expected: smooth growth, no anomalies
