with source as (
    select * from {{ ref('carriers') }}
)

select
    cast(carrier_id as varchar) as carrier_id,
    cast(carrier_name as varchar) as carrier_name,
    cast(carrier_mode as varchar) as carrier_mode,
    cast(service_level as varchar) as service_level,
    cast(country_code as varchar) as country_code,
    coalesce(cast(is_active as boolean), true) as is_active
from source
