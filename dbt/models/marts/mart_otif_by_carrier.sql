select
    car.carrier_id,
    car.carrier_name,
    car.carrier_mode,
    car.service_level,
    w.region as origin_region,
    c.region as customer_region,
    count(*) as shipments,
    sum(case when f.is_on_time then 1 else 0 end) as on_time_count,
    sum(case when f.is_otif then 1 else 0 end) as otif_count,
    round(100.0 * sum(case when f.is_on_time then 1 else 0 end) / count(*), 1) as on_time_pct,
    round(100.0 * sum(case when f.is_otif then 1 else 0 end) / count(*), 1) as otif_pct,
    sum(f.freight_cost) as total_freight_cost,
    sum(f.total_weight_kg) as total_weight_kg
from {{ ref('fact_shipment') }} f
inner join {{ ref('dim_carrier') }} car on car.carrier_key = f.carrier_key
inner join {{ ref('dim_warehouse') }} w on w.warehouse_key = f.warehouse_key
inner join {{ ref('dim_customer') }} c on c.customer_key = f.customer_key
group by
    car.carrier_id,
    car.carrier_name,
    car.carrier_mode,
    car.service_level,
    w.region,
    c.region
