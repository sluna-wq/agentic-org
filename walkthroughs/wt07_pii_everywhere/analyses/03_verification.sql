-- WT-07: PII Everywhere — Verification
-- Run these after applying the fix to confirm PII is fully remediated.

-- ============================================================
-- CHECK 1: stg_customers has NO PII columns
-- ============================================================
select column_name
from information_schema.columns
where table_name = 'stg_customers'
  and column_name in ('email', 'phone', 'ssn_last4');
-- Expected: 0 rows (no PII columns present)

-- ============================================================
-- CHECK 2: fct_customer_orders has NO PII columns
-- ============================================================
select column_name
from information_schema.columns
where table_name = 'fct_customer_orders'
  and column_name in ('email', 'phone', 'ssn_last4');
-- Expected: 0 rows

-- ============================================================
-- CHECK 3: fct_marketing_reach has NO PII columns
-- ============================================================
select column_name
from information_schema.columns
where table_name = 'fct_marketing_reach'
  and column_name in ('email', 'phone', 'ssn_last4');
-- Expected: 0 rows

-- ============================================================
-- CHECK 4: Mart data integrity — order counts unchanged
-- ============================================================
select count(*) as order_count from fct_customer_orders;
-- Expected: 20 rows (same as before fix — data not lost, just PII removed)

select count(*) as export_count from fct_marketing_reach;
-- Expected: 10 rows

-- ============================================================
-- CHECK 5: Safe columns still present and correct
-- ============================================================
select
    order_id,
    customer_id,
    first_name,
    last_name,
    plan,
    country,
    amount
from fct_customer_orders
order by order_id
limit 5;
-- All non-PII columns should be present and correctly populated.
