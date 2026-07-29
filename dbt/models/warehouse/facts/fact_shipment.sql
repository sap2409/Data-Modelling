with sh as (
    select * from {{ ref('stg_shipments') }}
),
enriched as (
    select
        sh.*,
        case
            when sh.actual_delivery_date is null or sh.promised_delivery_date is null then null
            else sh.actual_delivery_date <= sh.promised_delivery_date
        end as is_on_time,
        case when sh.status_code = 'delivered' then true else null end as is_in_full
    from sh
)

select
    {{ dbt_utils.generate_surrogate_key(['e.shipment_id']) }} as shipment_key,
    e.shipment_id,
    {{ to_date_key('e.ship_date') }} as ship_date_key,
    case when e.promised_delivery_date is null then null else {{ to_date_key('e.promised_delivery_date') }} end as promised_delivery_date_key,
    case when e.actual_delivery_date is null then null else {{ to_date_key('e.actual_delivery_date') }} end as actual_delivery_date_key,
    c.customer_key,
    w.warehouse_key,
    car.carrier_key,
    st.status_key,
    e.so_id,
    coalesce(e.package_count, 1) as package_count,
    e.total_weight_kg,
    coalesce(e.freight_cost, 0) as freight_cost,
    e.is_on_time,
    e.is_in_full,
    case
        when e.is_on_time is null then null
        else e.is_on_time and coalesce(e.is_in_full, false)
    end as is_otif,
    e.currency_code
from enriched e
inner join {{ ref('dim_customer') }} c on c.customer_id = e.customer_id
inner join {{ ref('dim_warehouse') }} w on w.warehouse_id = e.warehouse_id
inner join {{ ref('dim_carrier') }} car on car.carrier_id = e.carrier_id
inner join {{ ref('dim_status') }} st
    on st.status_domain = 'shipment'
   and st.status_code = e.status_code
