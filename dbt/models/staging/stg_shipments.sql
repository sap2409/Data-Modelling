with source as (
    select * from {{ ref('shipments') }}
)

select
    cast(shipment_id as varchar) as shipment_id,
    cast(ship_date as date) as ship_date,
    cast(promised_delivery_date as date) as promised_delivery_date,
    cast(actual_delivery_date as date) as actual_delivery_date,
    cast(customer_id as varchar) as customer_id,
    cast(warehouse_id as varchar) as warehouse_id,
    cast(carrier_id as varchar) as carrier_id,
    cast(status_code as varchar) as status_code,
    cast(so_id as varchar) as so_id,
    cast(package_count as integer) as package_count,
    cast(total_weight_kg as decimal(12, 3)) as total_weight_kg,
    cast(freight_cost as decimal(14, 2)) as freight_cost,
    coalesce(cast(currency_code as varchar), 'USD') as currency_code
from source
