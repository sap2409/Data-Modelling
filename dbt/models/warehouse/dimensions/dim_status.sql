select
    {{ dbt_utils.generate_surrogate_key(['status_domain', 'status_code']) }} as status_key,
    status_code,
    status_name,
    status_domain,
    is_terminal,
    sort_order
from {{ ref('stg_status') }}
