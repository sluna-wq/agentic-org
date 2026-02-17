-- WT-04: Schema Contract Test
-- This test passes when raw_accounts has all expected columns.
-- It FAILS (returns rows) if any expected column is missing.
--
-- Add this to your tests/ directory after fixing the incident.
-- Run with: dbt test --select assert_schema_contract
--
-- This is the test that would have PREVENTED this incident if it had existed
-- on raw_customers before the migration. If raw_customers had this test,
-- the backend team would have seen it fail in staging before deploying.

with expected_columns as (
    -- These are the columns we require in raw_accounts
    select column_name from (values
        ('account_id'),
        ('first_name'),
        ('last_name'),
        ('email'),
        ('street'),
        ('city'),
        ('state_code'),
        ('postal_code'),
        ('created_at'),
        ('updated_at'),
        ('is_active'),
        ('account_tier'),
        ('phone'),
        ('country_code')
    ) as t(column_name)
),

actual_columns as (
    select lower(column_name) as column_name
    from information_schema.columns
    where lower(table_name) = 'raw_accounts'
      and lower(table_schema) = 'main_raw'
),

missing_columns as (
    select expected_columns.column_name as missing_column
    from expected_columns
    left join actual_columns using (column_name)
    where actual_columns.column_name is null
)

-- Returns rows if the contract is violated (columns are missing)
-- dbt expects 0 rows for a passing test
select missing_column from missing_columns
