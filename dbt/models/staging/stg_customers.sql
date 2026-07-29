with source as (
    select * from {{ ref('customers') }}
)

select
    cast(customer_id as varchar) as customer_id,
    cast(customer_name as varchar) as customer_name,
    cast(customer_segment as varchar) as customer_segment,
    cast(country_code as varchar) as country_code,
    cast(region as varchar) as region,
    cast(city as varchar) as city,
    cast(channel as varchar) as channel,
    coalesce(cast(is_active as boolean), true) as is_active
from source
