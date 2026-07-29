select
    {{ dbt_utils.generate_surrogate_key(['warehouse_id']) }} as warehouse_key,
    warehouse_id,
    warehouse_name,
    warehouse_type,
    country_code,
    region,
    city,
    timezone,
    capacity_units,
    is_active
from {{ ref('stg_warehouses') }}
