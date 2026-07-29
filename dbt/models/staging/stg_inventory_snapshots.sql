with source as (
    select * from {{ ref('inventory_snapshots') }}
)

select
    cast(snapshot_date as date) as snapshot_date,
    cast(product_id as varchar) as product_id,
    cast(warehouse_id as varchar) as warehouse_id,
    cast(on_hand_qty as decimal(18, 4)) as on_hand_qty,
    cast(reserved_qty as decimal(18, 4)) as reserved_qty,
    cast(available_qty as decimal(18, 4)) as available_qty,
    cast(in_transit_qty as decimal(18, 4)) as in_transit_qty,
    cast(on_order_qty as decimal(18, 4)) as on_order_qty,
    cast(unit_cost as decimal(14, 4)) as unit_cost
from source
