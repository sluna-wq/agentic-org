-- Customer dimension: one row per customer with all their attributes + order history
with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select * from {{ ref('int_customer_orders') }}
),

web_sessions as (
    select
        customer_id,
        count(*) as total_sessions,
        sum(has_purchase) as purchase_sessions,
        sum(case when device_type = 'mobile' then 1 else 0 end) as mobile_sessions,
        min(session_started_at) as first_seen_at
    from {{ ref('int_web_sessions') }}
    where customer_id is not null
    group by 1
),

final as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.first_name || ' ' || c.last_name as full_name,
        c.email,
        c.phone,
        c.country,
        c.customer_segment,
        c.is_active,
        c.created_at as customer_since,

        -- Order metrics
        coalesce(co.total_orders, 0) as total_orders,
        coalesce(co.completed_orders, 0) as completed_orders,
        coalesce(co.returned_orders, 0) as returned_orders,
        coalesce(co.cancelled_orders, 0) as cancelled_orders,
        coalesce(co.lifetime_revenue, 0) as lifetime_revenue,
        coalesce(co.lifetime_refunds, 0) as lifetime_refunds,
        co.avg_order_value,
        co.first_order_at,
        co.last_order_at,
        co.customer_tenure_days,

        -- Web metrics
        coalesce(ws.total_sessions, 0) as total_web_sessions,
        coalesce(ws.purchase_sessions, 0) as purchase_sessions,
        coalesce(ws.mobile_sessions, 0) as mobile_sessions,
        ws.first_seen_at,

        -- Derived
        case
            when co.lifetime_revenue >= 5000 then 'whale'
            when co.lifetime_revenue >= 1000 then 'high_value'
            when co.lifetime_revenue >= 200 then 'mid_value'
            when co.lifetime_revenue > 0 then 'low_value'
            else 'no_purchases'
        end as value_tier,

        case
            when co.last_order_at >= current_date - interval '90 days' then 'active'
            when co.last_order_at >= current_date - interval '180 days' then 'cooling'
            when co.last_order_at is not null then 'churned'
            else 'never_ordered'
        end as activity_status

    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
    left join web_sessions ws on c.customer_id = ws.customer_id
)

select * from final
