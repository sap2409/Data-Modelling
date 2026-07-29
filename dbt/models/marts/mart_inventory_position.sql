select
    w.warehouse_id,
    w.warehouse_name,
    w.region,
    d.full_date as snapshot_date,
    p.sku,
    p.product_name,
    p.category,
    f.on_hand_qty,
    f.reserved_qty,
    f.available_qty,
    f.in_transit_qty,
    f.on_order_qty,
    f.inventory_value
from {{ ref('fact_inventory_snapshot') }} f
inner join {{ ref('dim_warehouse') }} w on w.warehouse_key = f.warehouse_key
inner join {{ ref('dim_product') }} p on p.product_key = f.product_key
inner join {{ ref('dim_date') }} d on d.date_key = f.snapshot_date_key
