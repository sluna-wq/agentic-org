-- WT-09: Building the Metrics Layer
-- Phase 1 & 2: Map the three metrics and find where they diverge
-- Run these in order. Each query reveals one part of the puzzle.

-- Step 1: Pull all three metrics for December 2025 side by side
-- (In practice you'd run these separately and compare)

-- Finance metric (fct_revenue_monthly)
SELECT
    'Finance' AS source,
    revenue_month,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT account_id) AS account_count
FROM {{ ref('fct_revenue_monthly') }}
WHERE revenue_month = '2025-12-01'
GROUP BY 1, 2

UNION ALL

-- Sales metric (fct_arr_by_account)
SELECT
    'Sales' AS source,
    arr_month AS revenue_month,
    SUM(mrr) AS total_revenue,
    COUNT(DISTINCT account_id) AS account_count
FROM {{ ref('fct_arr_by_account') }}
WHERE arr_month = '2025-12-01'
GROUP BY 1, 2

UNION ALL

-- Marketing metric (fct_marketing_revenue)
SELECT
    'Marketing' AS source,
    revenue_month,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT account_id) AS account_count
FROM {{ ref('fct_marketing_revenue') }}
WHERE revenue_month = '2025-12-01'
GROUP BY 1, 2;

-- Step 2: Find divergence point #1 — Date basis
-- Does the account appear in all three? What are the timing differences?
SELECT
    i.account_id,
    date_trunc('month', i.invoice_date) AS invoice_month,
    date_trunc('month', p.payment_date) AS payment_month,
    date_trunc('month', c.start_date) AS contract_month,
    i.amount
FROM {{ ref('stg_invoices') }} i
JOIN {{ ref('stg_contracts') }} c ON i.contract_id = c.contract_id
LEFT JOIN {{ ref('stg_payments') }} p ON p.invoice_id = i.invoice_id
WHERE i.type = 'subscription'
  AND i.invoice_date BETWEEN '2025-11-01' AND '2025-12-31'
  AND date_trunc('month', i.invoice_date) != date_trunc('month', p.payment_date)
ORDER BY i.account_id, i.invoice_date;

-- Step 3: Find divergence point #2 — Revenue type
-- What is Finance including that shouldn't be in MRR?
SELECT
    i.type,
    COUNT(*) AS invoice_count,
    SUM(i.amount) AS total_amount,
    'included in Finance, excluded from canonical' AS note
FROM {{ ref('stg_invoices') }} i
WHERE date_trunc('month', i.invoice_date) = '2025-12-01'
  AND i.type != 'subscription'
  AND i.status = 'paid'
GROUP BY 1
ORDER BY 3 DESC;

-- Step 4: Find divergence point #3 — Contract type (pilots)
-- What is Sales including that inflates their number?
SELECT
    c.type AS contract_type,
    c.status AS contract_status,
    COUNT(DISTINCT c.account_id) AS account_count,
    SUM(c.monthly_value) AS monthly_value,
    CASE
        WHEN c.type = 'pilot' THEN 'INFLATES Sales metric — excluded from canonical'
        WHEN c.status = 'churned' THEN 'should be excluded'
        ELSE 'included in canonical'
    END AS canonical_treatment
FROM {{ ref('stg_contracts') }} c
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Step 5: Quantify the dollar impact of each divergence
-- This is the reconciliation table you'll present to stakeholders
WITH canonical_base AS (
    SELECT SUM(i.amount) AS canonical_mrr
    FROM {{ ref('stg_invoices') }} i
    JOIN {{ ref('stg_contracts') }} c ON i.contract_id = c.contract_id
    WHERE date_trunc('month', i.invoice_date) = '2025-12-01'
      AND i.type = 'subscription'
      AND i.status = 'paid'
      AND c.type = 'recurring'
      AND c.status = 'active'
),
setup_fees AS (
    SELECT SUM(amount) AS amount FROM {{ ref('stg_invoices') }}
    WHERE date_trunc('month', invoice_date) = '2025-12-01'
      AND type = 'setup' AND status = 'paid'
),
pilot_contracts AS (
    SELECT SUM(monthly_value) AS amount FROM {{ ref('stg_contracts') }}
    WHERE type = 'pilot' AND status = 'active'
),
pending_invoices AS (
    SELECT SUM(amount) AS amount FROM {{ ref('stg_invoices') }}
    WHERE date_trunc('month', invoice_date) = '2025-12-01'
      AND type = 'subscription' AND status = 'pending'
)
SELECT
    'Canonical MRR' AS item, canonical_mrr AS amount, 'baseline' AS affects
FROM canonical_base
UNION ALL
SELECT '+ Setup fees', amount, 'Finance only' FROM setup_fees
UNION ALL
SELECT '+ Pilot contracts', amount, 'Sales only' FROM pilot_contracts
UNION ALL
SELECT '+ Pending invoices', amount, 'Finance only' FROM pending_invoices;
