with source as (
    select * from {{ ref('products') }}
)

select
    cast(product_id as varchar) as product_id,
    cast(sku as varchar) as sku,
    cast(product_name as varchar) as product_name,
    cast(category as varchar) as category,
    cast(subcategory as varchar) as subcategory,
    cast(brand as varchar) as brand,
    coalesce(cast(unit_of_measure as varchar), 'EA') as unit_of_measure,
    cast(unit_cost as decimal(14, 4)) as unit_cost,
    cast(unit_price as decimal(14, 4)) as unit_price,
    cast(is_active as boolean) as is_active
from source
