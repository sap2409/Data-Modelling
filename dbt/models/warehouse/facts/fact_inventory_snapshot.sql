with snap as (
    select * from {{ ref('stg_inventory_snapshots') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['snap.snapshot_date', 'snap.product_id', 'snap.warehouse_id']) }} as inventory_snapshot_key,
    {{ to_date_key('snap.snapshot_date') }} as snapshot_date_key,
    p.product_key,
    w.warehouse_key,
    coalesce(snap.on_hand_qty, 0) as on_hand_qty,
    coalesce(snap.reserved_qty, 0) as reserved_qty,
    coalesce(snap.available_qty, 0) as available_qty,
    coalesce(snap.in_transit_qty, 0) as in_transit_qty,
    coalesce(snap.on_order_qty, 0) as on_order_qty,
    round(coalesce(snap.on_hand_qty, 0) * coalesce(snap.unit_cost, 0), 2) as inventory_value
from snap
inner join {{ ref('dim_product') }} p on p.product_id = snap.product_id
inner join {{ ref('dim_warehouse') }} w on w.warehouse_id = snap.warehouse_id
