-- stg_marketing_exports: pipeline of customer data sent to third-party vendors
select
    export_id,
    export_date::date  as export_date,
    customer_id,
    export_type,
    destination,
    row_count,
    status
from {{ source('raw', 'raw_marketing_exports') }}
