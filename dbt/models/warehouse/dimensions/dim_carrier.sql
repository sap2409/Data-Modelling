select
    {{ dbt_utils.generate_surrogate_key(['carrier_id']) }} as carrier_key,
    carrier_id,
    carrier_name,
    carrier_mode,
    service_level,
    country_code,
    is_active
from {{ ref('stg_carriers') }}
