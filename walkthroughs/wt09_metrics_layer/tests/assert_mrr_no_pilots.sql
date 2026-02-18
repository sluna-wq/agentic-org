-- assert_mrr_no_pilots.sql
-- CI gate: fails if any pilot contract revenue appears in fct_mrr_canonical
--
-- Business contract (agreed 2025-12-18):
--   Pilot contracts represent conditional, non-committed revenue.
--   They must never appear in canonical MRR reported to the board.
--
-- How it works:
--   Join fct_mrr_canonical back to stg_contracts on contract_id.
--   Any row where contract.type = 'pilot' is a violation.
--   dbt fails this test if the query returns any rows.

WITH pilot_violations AS (
    SELECT
        f.revenue_month,
        f.account_id,
        f.contract_id,
        c.type AS contract_type,
        f.mrr AS violation_amount
    FROM {{ ref('fct_mrr_canonical') }} f
    JOIN {{ ref('stg_contracts') }} c
        ON f.contract_id = c.contract_id
    WHERE c.type = 'pilot'
)

SELECT
    revenue_month,
    account_id,
    contract_id,
    contract_type,
    violation_amount
FROM pilot_violations
-- dbt test fails if this query returns any rows
