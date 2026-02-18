-- WT-08 Investigation: The Duplicate Problem
-- Run each step in sequence. Follow the trail.

-- ============================================================
-- STEP 1: Confirm the discrepancy
-- Dashboard shows gross_revenue. What does deduplication give?
-- ============================================================

with raw_revenue as (
    select sum(amount) as dashboard_revenue
    from {{ ref('stg_payments') }}
),

deduped_revenue as (
    select sum(amount) as reconciled_revenue
    from (
        select distinct on (order_id, customer_id, amount)
            order_id, customer_id, amount
        from {{ ref('stg_payments') }}
        order by order_id, customer_id, amount, paid_at asc
    ) deduped
)

select
    r.dashboard_revenue,
    d.reconciled_revenue,
    r.dashboard_revenue - d.reconciled_revenue as inflation,
    round((r.dashboard_revenue - d.reconciled_revenue) / r.dashboard_revenue * 100, 1) as inflation_pct
from raw_revenue r, deduped_revenue d;

-- ============================================================
-- STEP 2: Is the inflation in the mart or in staging?
-- ============================================================

-- Check row counts: payments vs distinct transactions
select
    count(*)                                         as total_payment_rows,
    count(distinct payment_id)                       as unique_payment_ids,
    count(distinct (order_id || customer_id || amount::text)) as unique_transactions,
    count(*) - count(distinct (order_id || customer_id || amount::text)) as duplicate_rows
from {{ ref('stg_payments') }};

-- ============================================================
-- STEP 3: Find the duplicate signature
-- Same order, same amount, timestamps seconds apart
-- ============================================================

with ranked as (
    select
        payment_id,
        order_id,
        customer_id,
        amount,
        paid_at,
        row_number() over (
            partition by order_id, customer_id, amount
            order by paid_at asc
        ) as occurrence_num,
        count(*) over (
            partition by order_id, customer_id, amount
        ) as occurrence_count
    from {{ ref('stg_payments') }}
)

select
    order_id,
    customer_id,
    amount,
    occurrence_count,
    min(paid_at) as first_seen,
    max(paid_at) as last_seen,
    extract(epoch from max(paid_at) - min(paid_at)) as seconds_between
from ranked
where occurrence_count > 1
group by 1, 2, 3, 4
order by seconds_between asc;
-- Note: all duplicates are 2–8 seconds apart — classic ETL retry window

-- ============================================================
-- STEP 4: Scope the blast radius
-- ============================================================

with dupes as (
    select
        order_id,
        customer_id,
        amount,
        count(*) as occurrence_count
    from {{ ref('stg_payments') }}
    group by 1, 2, 3
    having count(*) > 1
)

select
    count(*) as affected_orders,
    sum(amount * (occurrence_count - 1)) as duplicated_revenue,
    round(
        sum(amount * (occurrence_count - 1)) /
        (select sum(amount) from {{ ref('stg_payments') }}) * 100, 1
    ) as pct_of_total_revenue
from dupes;
