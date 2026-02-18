-- WT-07: PII Everywhere — Solution
-- Fix stg_customers to enumerate safe columns only.
-- Then rebuild marts so PII is fully removed from the lineage.

-- ============================================================
-- STEP 1: Fix stg_customers (apply to models/staging/stg_customers.sql)
-- ============================================================

-- Replace the SELECT * with explicit safe columns:
--
-- select
--     customer_id,
--     first_name,
--     last_name,
--     signup_date::date  as signup_date,
--     plan,
--     country
-- from {{ source('raw', 'raw_customers') }}

-- ============================================================
-- STEP 2: Fix mart models — remove explicit PII column references
-- ============================================================

-- In fct_customer_orders.sql, remove these lines from the joined CTE:
--     c.email,
--     c.phone,
--     c.ssn_last4

-- In fct_marketing_reach.sql, remove these lines from the enriched CTE:
--     c.email,
--     c.phone,
--     c.ssn_last4

-- ============================================================
-- STEP 3: Rebuild and verify
-- ============================================================

-- dbt run --select stg_customers fct_customer_orders fct_marketing_reach
-- dbt test --select stg_customers fct_customer_orders fct_marketing_reach

-- ============================================================
-- STEP 4: Add column-level tests to prevent regression
-- ============================================================

-- Add to stg_models.yml under stg_customers:
--   - meta:
--       pii_columns_forbidden: [email, phone, ssn_last4]
--
-- The assert_no_pii_in_marts.sql test captures this at the mart layer.
-- A CI gate on this test prevents future PII leaks from merging.

-- ============================================================
-- STEP 5: Incident documentation checklist
-- ============================================================

-- [ ] Which vendors received PII? (see Phase 3 above)
-- [ ] Date range of exposure (first_export to last_export)
-- [ ] Number of affected customers
-- [ ] Legal/compliance notification required? (GDPR Art. 33: 72hr if EU residents affected)
-- [ ] Vendor data deletion request sent?
-- [ ] BI tool column-level permissions reviewed?
-- [ ] dbt CI gate added to block future PII in marts?
