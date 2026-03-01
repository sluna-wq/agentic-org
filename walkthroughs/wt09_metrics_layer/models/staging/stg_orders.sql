-- stg_orders.sql
-- Staging model for raw_orders.
-- Light cleaning only: lowercase status, cast timestamps to proper types.
-- No business logic here — that lives in marts.
-- All three date fields (created_at, paid_at, recognized_at) are preserved
-- so downstream models can choose their own date basis. That freedom is
-- precisely what caused the three-team conflict this walkthrough investigates.

with source as (

    select * from {{ ref('raw_orders') }}

),

cleaned as (

    select
        order_id,
        customer_id,

        -- Normalize status to lowercase for consistent filtering downstream.
        -- Valid values: 'completed', 'invoiced', 'pending', 'refunded'
        lower(trim(status))                             as status,

        -- Face value in the order's native currency.
        -- Do NOT use this for cross-currency revenue aggregation.
        cast(amount_usd as numeric)                     as amount_local,

        -- Original currency of the order. USD orders need no conversion.
        upper(trim(currency))                           as currency,

        -- THREE date fields, each with a different semantic meaning:
        --
        -- created_at: When the order was placed. Used by Sales because it
        --   reflects when the deal was won, regardless of payment timing.
        --
        -- paid_at: When cash was received. Used by Product because it
        --   reflects actual customer action (completing checkout). Null for
        --   orders that have not been paid (invoiced, pending, refunded).
        --
        -- recognized_at: When revenue was recognized for accounting purposes.
        --   Used by Finance because GAAP/IFRS recognition may differ from
        --   cash receipt. Null for pending orders and refunded orders.
        --   For invoiced orders recognized_at is set by Finance at invoice
        --   approval, even though cash hasn't arrived.

        cast(created_at    as timestamp)                as created_at,
        cast(paid_at       as timestamp)                as paid_at,
        cast(recognized_at as timestamp)                as recognized_at

    from source

)

select * from cleaned
