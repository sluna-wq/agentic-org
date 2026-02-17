-- WT-04: Reference Solution — stg_customers.sql (backward-compatible)
--
-- ⚠️  TRY THE FIX YOURSELF FIRST. Only read this if you're stuck.
--
-- The goal: stg_customers.sql outputs the SAME columns as before
-- so that dim_customers, fct_orders, fct_revenue_daily don't need changes.
-- The staging layer absorbs the upstream change.

-- ============================================================
-- SOLUTION: stg_customers.sql (backward-compatible version)
-- ============================================================
--
-- Replace the contents of models/staging/stg_customers.sql with this:

/*
with source as (
    -- Changed: now reads from raw_accounts instead of raw_customers
    select * from {{ source('raw', 'raw_accounts') }}
),

cleaned as (
    select
        -- Changed: account_id → customer_id (output column name preserved)
        account_id                              as customer_id,

        nullif(trim(first_name), '')            as first_name,  -- unchanged
        nullif(trim(last_name), '')             as last_name,   -- unchanged
        nullif(trim(lower(email)), '')          as email,       -- unchanged

        cast(created_at as timestamp)           as created_at,  -- unchanged
        cast(updated_at as timestamp)           as updated_at,  -- unchanged
        cast(is_active as boolean)              as is_active,   -- unchanged

        -- Changed: account_tier with new values → map back to old segment names
        -- This is the sneaky one — values changed, not just column name
        case account_tier
            when 'gold'     then 'premium'
            when 'silver'   then 'standard'
            when 'platinum' then 'enterprise'
            else 'unknown'
        end                                     as customer_segment,

        -- Added: expose new tier name too (additive — doesn't break anything)
        account_tier,

        -- Changed: street/city/state_code/postal_code → reconstruct address
        -- Downstream models used address as a display field, so we rebuild it
        -- Also expose components separately (additive)
        nullif(trim(street), '')                as street,
        nullif(trim(city), '')                  as city,
        nullif(trim(state_code), '')            as state_code,
        nullif(trim(postal_code), '')           as postal_code,
        concat_ws(', ',
            nullif(trim(street), ''),
            nullif(trim(city), ''),
            nullif(trim(state_code), '')
        )                                       as address,  -- reconstructed for backward compat

        nullif(trim(phone), '')                 as phone,   -- unchanged

        -- Changed: country_code → country (output column name preserved)
        nullif(trim(upper(country_code)), '')   as country

    from source
    where
        account_id is not null
        and nullif(trim(first_name), '') is not null
        and lower(coalesce(email, '')) not like '%test%'
)

select * from cleaned
*/


-- ============================================================
-- SOLUTION: src_acme.yml update
-- ============================================================
--
-- In models/staging/src_acme.yml, add raw_accounts to the tables list:
--
/*
sources:
  - name: raw
    schema: main_raw
    database: warehouse
    description: Raw data from Acme Corp source systems
    tables:
      - name: raw_accounts          # ← ADD THIS
        description: Account records (renamed from raw_customers — migration 2026-02-17)
        columns:
          - name: account_id
            tests:
              - not_null
              - unique
          - name: email
            tests:
              - not_null
          - name: account_tier
            tests:
              - accepted_values:
                  values: ['gold', 'silver', 'platinum']
      - name: raw_customers         # ← KEEP or REMOVE depending on strategy
        description: DEPRECATED — use raw_accounts. Kept for rollback reference.
      - name: raw_orders
        ...
*/


-- ============================================================
-- KEY DECISIONS you had to make
-- ============================================================
--
-- 1. Keep old column names (customer_id, country, address) in output?
--    YES — downstream models don't need to change. Staging absorbs the diff.
--    This is the "staging as blast shield" pattern.
--
-- 2. Map tier values back to segment values?
--    YES — otherwise stg_customers would output 'unknown' for all tiers.
--    AND expose account_tier too (additive change, not breaking).
--
-- 3. Reconstruct the address field?
--    YES for backward compat, PLUS expose components separately.
--    The components are genuinely useful; the reconstructed string is legacy compat.
--
-- 4. Keep raw_customers in src_acme.yml?
--    Your call. Options:
--    a) Remove it (clean) — risk: breaks if someone else references it
--    b) Keep it deprecated (safe) — small messiness, safer rollback
--    c) Keep it, add a source freshness test that alerts if it's ever populated
--       again (best of both worlds if the backend team ever does a rollback)
