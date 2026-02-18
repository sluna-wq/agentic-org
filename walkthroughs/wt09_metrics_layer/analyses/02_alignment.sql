-- WT-09: Building the Metrics Layer
-- Phase 3: Align on canonical definition
-- These queries answer the questions stakeholders will ask

-- Q1: What is the canonical MRR by segment? (Board wants this breakdown)
SELECT
    a.segment,
    date_trunc('month', i.invoice_date) AS revenue_month,
    COUNT(DISTINCT i.account_id) AS paying_accounts,
    SUM(i.amount) AS mrr,
    SUM(SUM(i.amount)) OVER (PARTITION BY date_trunc('month', i.invoice_date)) AS total_mrr,
    ROUND(100.0 * SUM(i.amount) / SUM(SUM(i.amount)) OVER (PARTITION BY date_trunc('month', i.invoice_date)), 1) AS pct_of_total
FROM {{ ref('stg_invoices') }} i
JOIN {{ ref('stg_contracts') }} c ON i.contract_id = c.contract_id
JOIN {{ ref('stg_accounts') }} a ON c.account_id = a.account_id
WHERE date_trunc('month', i.invoice_date) = '2025-12-01'
  AND i.type = 'subscription'
  AND i.status = 'paid'
  AND c.type = 'recurring'
  AND c.status = 'active'
GROUP BY 1, 2
ORDER BY 4 DESC;

-- Q2: MRR trend last 6 months (board will ask about trajectory)
SELECT
    date_trunc('month', i.invoice_date) AS revenue_month,
    SUM(i.amount) AS canonical_mrr,
    LAG(SUM(i.amount)) OVER (ORDER BY date_trunc('month', i.invoice_date)) AS prev_month_mrr,
    SUM(i.amount) - LAG(SUM(i.amount)) OVER (ORDER BY date_trunc('month', i.invoice_date)) AS mom_change,
    ROUND(100.0 * (SUM(i.amount) - LAG(SUM(i.amount)) OVER (ORDER BY date_trunc('month', i.invoice_date)))
          / LAG(SUM(i.amount)) OVER (ORDER BY date_trunc('month', i.invoice_date)), 1) AS mom_pct
FROM {{ ref('stg_invoices') }} i
JOIN {{ ref('stg_contracts') }} c ON i.contract_id = c.contract_id
WHERE i.invoice_date >= '2025-07-01'
  AND i.type = 'subscription'
  AND i.status = 'paid'
  AND c.type = 'recurring'
  AND c.status = 'active'
GROUP BY 1
ORDER BY 1;

-- Q3: What would happen if we included pilots? (Sales wants to know)
SELECT
    c.type AS contract_type,
    SUM(i.amount) AS dec_revenue,
    'Include in canonical?' AS question,
    CASE c.type
        WHEN 'pilot' THEN 'NO — pilots are not committed recurring revenue'
        WHEN 'professional_services' THEN 'NO — one-time revenue is not MRR by definition'
        WHEN 'recurring' THEN 'YES — this is the canonical definition'
    END AS recommendation
FROM {{ ref('stg_invoices') }} i
JOIN {{ ref('stg_contracts') }} c ON i.contract_id = c.contract_id
WHERE date_trunc('month', i.invoice_date) = '2025-12-01'
  AND i.type = 'subscription'
  AND i.status = 'paid'
  AND c.status = 'active'
GROUP BY 1;
