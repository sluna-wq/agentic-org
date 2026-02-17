-- WT-04: Blast Radius Analysis
-- Run these queries to understand the full impact of the schema migration
-- before touching a single line of dbt code.
--
-- Rule #1: understand before you fix.

-- ============================================================
-- Step 1: Confirm the old table is gone (or renamed)
-- ============================================================
-- In DuckDB after `dbt seed`, run:

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'main_raw'
ORDER BY table_name;

-- Expected: raw_accounts is there. raw_customers is GONE.
-- This confirms: the migration dropped the old table, not just added a new one.


-- ============================================================
-- Step 2: Inspect the new schema
-- ============================================================

DESCRIBE SELECT * FROM main_raw.raw_accounts LIMIT 0;

-- What changed from raw_customers?
-- - customer_id → account_id
-- - address (single string) → street, city, state_code, postal_code (4 columns)
-- - customer_segment → account_tier (AND values changed: premium→gold, standard→silver, enterprise→platinum)
-- - country → country_code
-- - first_name, last_name, email, created_at, updated_at, is_active, phone: UNCHANGED


-- ============================================================
-- Step 3: Count the damage
-- ============================================================

-- How many accounts came over?
SELECT COUNT(*) as account_count FROM main_raw.raw_accounts;

-- What tier values exist in the new schema?
SELECT account_tier, COUNT(*) as n
FROM main_raw.raw_accounts
GROUP BY account_tier
ORDER BY n DESC;
-- Expected: gold, silver, platinum
-- Old values were: premium, standard, enterprise
-- If your stg_customers hardcodes 'premium', it'll map everything to 'unknown'


-- ============================================================
-- Step 4: Understand downstream impact (do this in dbt CLI)
-- ============================================================
-- Run this in your terminal, not DuckDB:
--
--   dbt ls --select stg_customers+
--
-- This lists every model that directly or indirectly depends on stg_customers.
-- You should see: stg_customers, dim_customers, fct_orders, fct_revenue_daily
-- (and potentially more if you've added models)
--
-- The '+' suffix means "and all dependents"
-- The '+' prefix means "and all ancestors": +stg_customers
-- Both: +stg_customers+ means ancestors AND dependents


-- ============================================================
-- Step 5: Verify what's currently broken
-- ============================================================
-- After running `dbt run` and seeing the failures, inspect the error messages.
-- The errors will look like:
--   "column 'customer_id' does not exist"
-- or
--   "table 'raw_customers' does not exist"
--
-- Make a list of which models failed and why.
-- Each failure type requires a different fix:
--
--   Table not found → update source definition in src_acme.yml
--   Column not found → update column references in staging model
--   Test failures → update tests to match new column names
--
-- How many of the 8 failing models can be fixed by fixing stg_customers alone?
-- (Answer: all of them — it's the root cause. Fix the source, the rest heals.)
