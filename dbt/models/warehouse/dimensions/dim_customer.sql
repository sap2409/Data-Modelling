select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,
    customer_id,
    customer_name,
    customer_segment,
    country_code,
    region,
    city,
    channel,
    is_active
from {{ ref('stg_customers') }}
