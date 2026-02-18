-- fct_daily_signups: daily new customer signups
-- Grain: one row per event_date where signups occurred
-- Upstream: stg_events
--
-- NOTE: Like fct_revenue_daily, this model is structurally correct.
-- It was also excluded from the Feb 9-11 pipeline runs due to the
-- --select staging.* selector bug. Data frozen as of Feb 8.

with events as (

    select * from {{ ref('stg_events') }}

),

signups as (

    select * from events where is_signup = true

),

daily_signups as (

    select
        event_date                              as signup_date,
        count(*)                                as signup_count,
        count(distinct customer_id)             as unique_signups

    from signups
    group by 1

),

with_running_total as (

    select
        signup_date,
        signup_count,
        unique_signups,
        sum(signup_count) over (
            order by signup_date
            rows between unbounded preceding and current row
        )                                       as cumulative_signups

    from daily_signups

)

select * from with_running_total
order by signup_date
