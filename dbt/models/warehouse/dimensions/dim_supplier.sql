select
    {{ dbt_utils.generate_surrogate_key(['supplier_id']) }} as supplier_key,
    supplier_id,
    supplier_name,
    supplier_type,
    country_code,
    region,
    city,
    payment_terms,
    lead_time_days,
    preferred_flag,
    is_active
from {{ ref('stg_suppliers') }}
