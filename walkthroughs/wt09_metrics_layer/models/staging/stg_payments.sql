-- stg_payments: clean payment records, net of refunds
-- Source: raw.raw_payments
-- Refunded payments are zeroed out (amount = 0) rather than removed,
-- so row counts stay consistent with stg_invoices for join diagnostics.
-- payment_date is the cash-receipt date — NOT the accrual date.
-- Use stg_invoices.invoice_date for accrual-basis MRR.

with source as (
    select * from {{ source('raw', 'raw_payments') }}
),

staged as (
    select
        payment_id::varchar                             as payment_id,
        account_id::varchar                             as account_id,
        invoice_id::varchar                             as invoice_id,
        payment_date::date                              as payment_date,
        date_trunc('month', payment_date::date)::date   as payment_month,
        -- Net of refunds: refunded payments contribute $0 to revenue
        case
            when refunded::boolean = true then 0::numeric(12, 2)
            else amount::numeric(12, 2)
        end                                             as amount,
        refunded::boolean                               as refunded
    from source
)

select * from staged
