-- stg_customers: clean and type-cast raw customer records
-- BUG: SELECT * pulls ALL columns from raw_customers, including PII:
--   email, phone, ssn_last4
-- These PII columns flow into every downstream mart and export.

-- THE BUG IS HERE:
select *
from {{ source('raw', 'raw_customers') }}

-- CORRECT VERSION (uncomment to fix):
-- select
--     customer_id,
--     first_name,
--     last_name,
--     signup_date::date  as signup_date,
--     plan,
--     country
-- from {{ source('raw', 'raw_customers') }}
