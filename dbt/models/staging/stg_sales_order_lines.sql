with source as (
    select * from {{ ref('sales_order_lines') }}
)

select
    cast(so_id as varchar) as so_id,
    cast(so_line_number as integer) as so_line_number,
    cast(order_date as date) as order_date,
    cast(requested_date as date) as requested_date,
    cast(ship_date as date) as ship_date,
    cast(customer_id as varchar) as customer_id,
    cast(product_id as varchar) as product_id,
    cast(warehouse_id as varchar) as warehouse_id,
    cast(status_code as varchar) as status_code,
    cast(ordered_qty as decimal(18, 4)) as ordered_qty,
    cast(shipped_qty as decimal(18, 4)) as shipped_qty,
    cast(cancelled_qty as decimal(18, 4)) as cancelled_qty,
    cast(unit_price as decimal(14, 4)) as unit_price,
    coalesce(cast(currency_code as varchar), 'USD') as currency_code
from source
