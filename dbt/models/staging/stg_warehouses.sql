with source as (
    select * from {{ ref('warehouses') }}
)

select
    cast(warehouse_id as varchar) as warehouse_id,
    cast(warehouse_name as varchar) as warehouse_name,
    cast(warehouse_type as varchar) as warehouse_type,
    cast(country_code as varchar) as country_code,
    cast(region as varchar) as region,
    cast(city as varchar) as city,
    cast(timezone as varchar) as timezone,
    cast(capacity_units as decimal(18, 2)) as capacity_units,
    coalesce(cast(is_active as boolean), true) as is_active
from source
