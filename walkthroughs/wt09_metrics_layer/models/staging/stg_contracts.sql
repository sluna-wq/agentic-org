-- stg_contracts: clean contract records with derived monthly_value
-- Source: raw.raw_contracts
-- Note: monthly_value = annual_value / 12 is a contract-basis approximation.
--       It is NOT the same as invoiced MRR — use stg_invoices for accrual-basis revenue.

with source as (
    select * from {{ source('raw', 'raw_contracts') }}
),

staged as (
    select
        contract_id::varchar                          as contract_id,
        account_id::varchar                           as account_id,
        start_date::date                              as start_date,
        end_date::date                                as end_date,
        annual_value::numeric                         as annual_value,
        (annual_value::numeric / 12)::numeric(12, 2)  as monthly_value,
        lower(trim(type))::varchar                    as type,
        lower(trim(status))::varchar                  as status
    from source
)

select * from staged
