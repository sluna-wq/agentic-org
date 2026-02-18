-- fct_revenue_daily: daily revenue summary from completed orders
-- Grain: one row per order_date
-- Upstream: stg_orders
--
-- NOTE: This model is structurally correct. The bug is NOT here.
-- This model was never refreshed after Feb 8 because the orchestrator ran
-- `dbt run --select staging.*` on Feb 9-11, which excluded all mart models.
-- The SQL is fine. The data is frozen.

with orders as (

    select * from {{ ref('stg_orders') }}

),

daily_revenue as (

    select
        order_date,
        count(*)                                as order_count,
        count(distinct customer_id)             as unique_customers,
        sum(amount)                             as total_revenue,
        avg(amount)                             as avg_order_value,
        sum(case when status = 'completed'
                 then amount else 0 end)        as completed_revenue,
        sum(case when order_size_tier = 'high'
                 then amount else 0 end)        as high_value_revenue,
        sum(case when order_size_tier = 'medium'
                 then amount else 0 end)        as medium_value_revenue,
        sum(case when order_size_tier = 'low'
                 then amount else 0 end)        as low_value_revenue

    from orders
    group by 1

)

select
    order_date,
    order_count,
    unique_customers,
    total_revenue,
    round(avg_order_value, 2)               as avg_order_value,
    completed_revenue,
    high_value_revenue,
    medium_value_revenue,
    low_value_revenue,
    -- running total for trend charts
    sum(total_revenue) over (
        order by order_date
        rows between unbounded preceding and current row
    )                                       as cumulative_revenue

from daily_revenue
order by order_date
