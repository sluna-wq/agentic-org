with source as (
    select * from {{ source('raw', 'raw_web_events') }}
),

cleaned as (
    select
        event_id,
        session_id,
        customer_id,
        lower(event_type) as event_type,
        page_url,
        nullif(trim(referrer), '') as referrer,
        lower(device_type) as device_type,
        lower(browser) as browser,
        cast(timestamp as timestamp) as event_at,
        cast(duration_seconds as integer) as duration_seconds
    from source
)

select * from cleaned
