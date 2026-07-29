with source as (
    select * from {{ ref('purchase_order_lines') }}
)

select
    cast(po_id as varchar) as po_id,
    cast(po_line_number as integer) as po_line_number,
    cast(order_date as date) as order_date,
    cast(requested_date as date) as requested_date,
    cast(promised_date as date) as promised_date,
    cast(received_date as date) as received_date,
    cast(supplier_id as varchar) as supplier_id,
    cast(product_id as varchar) as product_id,
    cast(warehouse_id as varchar) as warehouse_id,
    cast(status_code as varchar) as status_code,
    cast(ordered_qty as decimal(18, 4)) as ordered_qty,
    cast(received_qty as decimal(18, 4)) as received_qty,
    cast(cancelled_qty as decimal(18, 4)) as cancelled_qty,
    cast(unit_cost as decimal(14, 4)) as unit_cost,
    coalesce(cast(currency_code as varchar), 'USD') as currency_code
from source
