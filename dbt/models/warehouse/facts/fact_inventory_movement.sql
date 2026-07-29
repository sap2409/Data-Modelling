with mv as (
    select * from {{ ref('stg_inventory_movements') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['mv.movement_id']) }} as movement_key,
    mv.movement_id,
    {{ to_date_key('mv.movement_date') }} as movement_date_key,
    p.product_key,
    w.warehouse_key,
    s.supplier_key,
    c.customer_key,
    mv.movement_type,
    mv.reference_doc,
    coalesce(mv.quantity, 0) as quantity,
    mv.unit_cost,
    round(coalesce(mv.quantity, 0) * coalesce(mv.unit_cost, 0), 2) as movement_value
from mv
inner join {{ ref('dim_product') }} p on p.product_id = mv.product_id
inner join {{ ref('dim_warehouse') }} w on w.warehouse_id = mv.warehouse_id
left join {{ ref('dim_supplier') }} s on s.supplier_id = mv.supplier_id
left join {{ ref('dim_customer') }} c on c.customer_id = mv.customer_id
