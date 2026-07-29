with source as (
    select * from {{ ref('inventory_movements') }}
)

select
    cast(movement_id as varchar) as movement_id,
    cast(movement_date as date) as movement_date,
    cast(product_id as varchar) as product_id,
    cast(warehouse_id as varchar) as warehouse_id,
    nullif(trim(cast(supplier_id as varchar)), '') as supplier_id,
    nullif(trim(cast(customer_id as varchar)), '') as customer_id,
    cast(movement_type as varchar) as movement_type,
    cast(reference_doc as varchar) as reference_doc,
    cast(quantity as decimal(18, 4)) as quantity,
    cast(unit_cost as decimal(14, 4)) as unit_cost
from source
