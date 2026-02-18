-- WT-07: PII Everywhere — Investigation Queries
-- Work through these phases to understand the blast radius of the PII leak.

-- ============================================================
-- PHASE 1: Confirm the symptom — does PII exist in the marts?
-- ============================================================

-- 1a. Check column list of stg_customers
--     If email/phone/ssn_last4 appear, the staging model is leaking PII.
select column_name, data_type
from information_schema.columns
where table_name = 'stg_customers'
order by ordinal_position;
-- Expected (safe):  customer_id, first_name, last_name, signup_date, plan, country
-- Actual (buggy):   ...also email, phone, ssn_last4

-- 1b. Spot-check the mart directly
select order_id, customer_id, email, phone, ssn_last4
from fct_customer_orders
limit 5;
-- If these return values, PII is in the mart.

-- ============================================================
-- PHASE 2: Trace the lineage — where did PII enter?
-- ============================================================

-- 2a. Check the raw source — PII legitimately exists here
select customer_id, email, phone, ssn_last4
from raw.raw_customers
limit 3;

-- 2b. Check the staging model definition (look at stg_customers.sql)
--     The bug: SELECT * from raw_customers passes all columns through.

-- 2c. Confirm which mart tables inherited the PII columns
select column_name, table_name
from information_schema.columns
where column_name in ('email', 'phone', 'ssn_last4')
  and table_schema not in ('raw', 'information_schema')
order by table_name, column_name;

-- ============================================================
-- PHASE 3: Assess external exposure — what went to vendors?
-- ============================================================

-- 3a. Which customers had data exported to third-party vendors?
select
    me.export_id,
    me.export_date,
    me.destination,
    mr.customer_id,
    mr.email,      -- confirm PII was present at export time
    mr.phone
from raw.raw_marketing_exports me
join fct_marketing_reach mr on me.export_id = mr.export_id
order by me.export_date;

-- 3b. Count affected customers per vendor
select
    destination,
    count(distinct customer_id) as affected_customers,
    min(export_date)            as first_export,
    max(export_date)            as last_export
from fct_marketing_reach
group by destination
order by affected_customers desc;

-- 3c. List the specific customers whose PII was externally exposed
select distinct
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    ssn_last4
from fct_marketing_reach
where status = 'sent'
order by customer_id;

-- ============================================================
-- PHASE 4: Scope the BI exposure — what could analysts see?
-- ============================================================

-- 4a. Full column scan of fct_customer_orders
select *
from fct_customer_orders
limit 3;
-- Note all PII columns visible to any BI user with table access.

-- 4b. How many rows contain each PII field?
select
    count(*)                           as total_rows,
    count(email)                       as rows_with_email,
    count(phone)                       as rows_with_phone,
    count(ssn_last4)                   as rows_with_ssn_last4
from fct_customer_orders;
