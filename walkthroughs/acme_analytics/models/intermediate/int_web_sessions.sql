-- Sessionize web events and compute session-level metrics
with events as (
    select * from {{ ref('stg_web_events') }}
),

sessions as (
    select
        session_id,
        customer_id,
        min(event_at) as session_started_at,
        max(event_at) as session_ended_at,
        count(*) as event_count,
        sum(duration_seconds) as total_duration_seconds,
        max(case when event_type = 'purchase' then 1 else 0 end) as has_purchase,
        max(case when event_type = 'add_to_cart' then 1 else 0 end) as has_add_to_cart,
        min(referrer) as referrer,
        min(device_type) as device_type,
        min(browser) as browser
    from events
    group by 1, 2
)

select * from sessions
