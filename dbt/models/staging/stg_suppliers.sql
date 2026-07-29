with source as (
    select * from {{ ref('suppliers') }}
)

select
    cast(supplier_id as varchar) as supplier_id,
    cast(supplier_name as varchar) as supplier_name,
    cast(supplier_type as varchar) as supplier_type,
    cast(country_code as varchar) as country_code,
    cast(region as varchar) as region,
    cast(city as varchar) as city,
    cast(payment_terms as varchar) as payment_terms,
    cast(lead_time_days as integer) as lead_time_days,
    coalesce(cast(preferred_flag as boolean), false) as preferred_flag,
    coalesce(cast(is_active as boolean), true) as is_active
from source
