-- Assert that mart tables do NOT contain PII columns.
-- This test FAILS (returns rows) if PII columns are present in fct_customer_orders.
-- A passing test returns 0 rows.

-- Strategy: check information_schema for forbidden column names in mart tables.
-- In a real warehouse this would query the catalog; here we use a known-bad query
-- that returns data only when PII columns exist.

select
    'fct_customer_orders' as model_name,
    'email'               as forbidden_column,
    count(*)              as row_count_with_pii
from {{ ref('fct_customer_orders') }}
where email is not null

union all

select
    'fct_customer_orders' as model_name,
    'phone'               as forbidden_column,
    count(*)              as row_count_with_pii
from {{ ref('fct_customer_orders') }}
where phone is not null

union all

select
    'fct_marketing_reach' as model_name,
    'email'               as forbidden_column,
    count(*)              as row_count_with_pii
from {{ ref('fct_marketing_reach') }}
where email is not null
