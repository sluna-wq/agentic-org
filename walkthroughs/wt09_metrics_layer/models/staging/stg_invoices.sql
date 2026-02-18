-- stg_invoices: clean invoice records with dates cast and columns typed
-- Source: raw.raw_invoices
-- invoice_date is the accrual recognition date for MRR purposes.
-- type: 'subscription' | 'setup' | 'credit'
-- status: 'paid' | 'pending' | 'void'

with source as (
    select * from {{ source('raw', 'raw_invoices') }}
),

staged as (
    select
        invoice_id::varchar                           as invoice_id,
        account_id::varchar                           as account_id,
        contract_id::varchar                          as contract_id,
        invoice_date::date                            as invoice_date,
        date_trunc('month', invoice_date::date)::date as invoice_month,
        amount::numeric(12, 2)                        as amount,
        lower(trim(type))::varchar                    as type,
        lower(trim(status))::varchar                  as status
    from source
)

select * from staged
