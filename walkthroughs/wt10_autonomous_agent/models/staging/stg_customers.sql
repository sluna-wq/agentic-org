-- stg_customers: clean customer master records
-- Source: raw.raw_customers
-- Grain: one row per customer_id
--
-- PII CLASSIFICATION:
--   email  → PII (GDPR personal data) — SELECT into marts only as masked/hashed form
--   phone  → PII (GDPR personal data) — SELECT into marts only as masked/hashed form
--
-- email and phone are staged here for internal use (compliance audits, backfill logic)
-- but MUST NOT pass through into any mart-layer model that is customer-facing or broadly accessible.
--
-- The compliance finding in WT-10 (Finding #3) is that fct_customer_metrics
-- selects customer_email directly from this model into a customer-facing mart.

with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

staged as (
    select
        customer_id::varchar                                    as customer_id,
        trim(first_name)::varchar                               as first_name,
        trim(last_name)::varchar                                as last_name,
        lower(trim(email))::varchar                             as customer_email,      -- PII: email
        phone::varchar                                          as customer_phone,      -- PII: phone
        -- pre-masked versions for safe use in mart outputs
        left(lower(trim(email)), 2) || '***@***'::varchar       as email_masked,
        signup_date::date                                       as signup_date,
        lower(trim(plan))::varchar                              as plan,
        upper(trim(country))::varchar                           as country
    from source
)

select * from staged
