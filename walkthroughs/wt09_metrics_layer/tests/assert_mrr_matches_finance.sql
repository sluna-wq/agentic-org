-- assert_mrr_matches_finance.sql
-- CI warning (not failure): fires if canonical MRR differs from Finance metric by more than 5%
--
-- Purpose:
--   After the December 2025 incident, Finance agreed to align fct_revenue_monthly
--   to the canonical definition. This test detects drift — if Finance's model is
--   updated independently and begins diverging from canonical again, this test warns
--   before the divergence reaches a dashboard or board report.
--
-- Severity: warn (not error)
--   A >5% divergence may reflect a legitimate Finance model update that hasn't been
--   reviewed against canonical yet. It should trigger a conversation, not a build break.
--   Configure in schema.yml:
--     tests:
--       - assert_mrr_matches_finance:
--           severity: warn
--
-- How it works:
--   Compare monthly totals between fct_mrr_canonical and fct_revenue_monthly.
--   Return any month where the absolute percentage difference exceeds 5%.
--   dbt warns if this query returns any rows.

WITH canonical_by_month AS (
    SELECT
        revenue_month,
        SUM(mrr) AS canonical_mrr
    FROM {{ ref('fct_mrr_canonical') }}
    GROUP BY 1
),

finance_by_month AS (
    SELECT
        revenue_month,
        SUM(revenue) AS finance_mrr
    FROM {{ ref('fct_revenue_monthly') }}
    GROUP BY 1
),

comparison AS (
    SELECT
        c.revenue_month,
        c.canonical_mrr,
        f.finance_mrr,
        ABS(c.canonical_mrr - f.finance_mrr) AS absolute_difference,
        ROUND(
            100.0 * ABS(c.canonical_mrr - f.finance_mrr) / NULLIF(c.canonical_mrr, 0),
            2
        ) AS pct_difference
    FROM canonical_by_month c
    JOIN finance_by_month f
        ON c.revenue_month = f.revenue_month
)

SELECT
    revenue_month,
    canonical_mrr,
    finance_mrr,
    absolute_difference,
    pct_difference,
    'Finance metric has drifted >' || pct_difference::text || '% from canonical — review fct_revenue_monthly' AS warning_message
FROM comparison
WHERE pct_difference > 5.0
ORDER BY revenue_month DESC
-- dbt warns if this query returns any rows (configure severity: warn in schema.yml)
