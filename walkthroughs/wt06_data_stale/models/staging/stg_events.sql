-- stg_events: one row per user event, cleaned and typed
-- Grain: one row per event_id
-- Source: raw.raw_events

with source as (

    select * from {{ ref('raw_events') }}

),

staged as (

    select
        event_id,
        customer_id,
        lower(event_type)               as event_type,
        cast(event_date as date)        as event_date,
        properties,

        -- derived flags
        event_type = 'signup'           as is_signup,
        event_type = 'purchase'         as is_purchase,
        event_type = 'pageview'         as is_pageview,

        date_trunc('month', cast(event_date as date)) as event_month

    from source

)

select * from staged
