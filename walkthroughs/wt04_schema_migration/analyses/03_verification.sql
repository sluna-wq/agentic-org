-- WT-04: Verification Queries
-- Run these after your fix to confirm nothing regressed.
-- You should be comparing against a known-good baseline from WT-01/WT-03.

-- ============================================================
-- Step 1: Row counts — do we have the same customers?
-- ============================================================

-- Old count (from WT-01): 20 customers (after filtering test/null records)
SELECT COUNT(*) as customer_count FROM {{ ref('stg_customers') }};
-- Expected: ~19-20 (Emma Williams has no email, filtered; same as before)


-- ============================================================
-- Step 2: Segment distribution — did the mapping work?
-- ============================================================

SELECT customer_segment, account_tier, COUNT(*) as n
FROM {{ ref('stg_customers') }}
GROUP BY customer_segment, account_tier
ORDER BY n DESC;

-- Expected: every row has a valid customer_segment (no 'unknown')
-- gold → premium, silver → standard, platinum → enterprise
-- If you see 'unknown' anywhere, the tier mapping has a gap


-- ============================================================
-- Step 3: Address reconstruction — does it look reasonable?
-- ============================================================

SELECT
    customer_id,
    first_name,
    street,
    city,
    state_code,
    postal_code,
    address  -- reconstructed
FROM {{ ref('stg_customers') }}
LIMIT 5;

-- Spot check: does the address field look like "123 Oak Street, San Francisco, CA"?


-- ============================================================
-- Step 4: Revenue totals — did fct_orders still work?
-- ============================================================

-- This is the end-to-end test: if revenue numbers match WT-01 baseline, you're good
SELECT
    COUNT(*) as order_count,
    ROUND(SUM(total_amount_usd), 2) as total_revenue
FROM {{ ref('fct_orders') }};

-- Cross-reference against your WT-01 or WT-02 notes
-- If numbers differ, there's a join problem in dim_customers → fct_orders


-- ============================================================
-- Step 5: No nulls in critical fields
-- ============================================================

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) as null_customer_ids,
    SUM(CASE WHEN customer_segment IS NULL THEN 1 ELSE 0 END) as null_segments,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) as null_countries
FROM {{ ref('stg_customers') }};

-- Expected: all zeros (or the same nulls as in raw data — Emma Williams no email = filtered)


-- ============================================================
-- Step 6: dim_customers is fully populated
-- ============================================================

SELECT
    COUNT(*) as dim_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT customer_segment) as segment_count
FROM {{ ref('dim_customers') }};

-- Expected: same customer count as stg_customers, 3 distinct segments


-- ============================================================
-- The green check
-- ============================================================
-- If all of the above look right:
--   ✅ `dbt run` passes (0 errors)
--   ✅ `dbt test` passes (0 failures)
--   ✅ Row counts match baseline
--   ✅ Revenue totals match baseline
--   ✅ No unexpected NULLs
--
-- You're done. Time to write the postmortem.
