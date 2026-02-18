-- WT-08 Verification: Confirm fix produces correct revenue

-- After applying the fix to stg_payments.sql, re-run:
--   dbt run --select stg_payments fct_revenue_monthly fct_customer_ltv
-- Then validate:

-- 1. Revenue should match reconciled figure
select
    payment_month,
    payment_count,
    order_count,
    gross_revenue
from {{ ref('fct_revenue_monthly') }}
order by payment_month;
-- Expected: gross_revenue matches bank reconciliation ($603K total, not $847K)

-- 2. payment_count should equal order_count (1:1 after dedup)
select
    sum(case when payment_count != order_count then 1 else 0 end) as mismatched_months
from {{ ref('fct_revenue_monthly') }};
-- Expected: 0

-- 3. Customer LTV should be clean
select customer_id, lifetime_value
from {{ ref('fct_customer_ltv') }}
order by lifetime_value desc
limit 5;
-- Compare to pre-fix values — should be lower and correct

-- 4. Run the new CI test
-- dbt test --select assert_no_duplicate_payments
-- Expected: 0 failures
