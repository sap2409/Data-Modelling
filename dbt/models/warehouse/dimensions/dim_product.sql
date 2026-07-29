select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_key,
    product_id,
    sku,
    product_name,
    category,
    subcategory,
    brand,
    unit_of_measure,
    unit_cost,
    unit_price,
    is_active
from {{ ref('stg_products') }}
