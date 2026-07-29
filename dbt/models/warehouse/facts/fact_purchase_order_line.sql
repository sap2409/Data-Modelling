with po as (
    select * from {{ ref('stg_purchase_order_lines') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['po.po_id', 'po.po_line_number']) }} as po_line_key,
    po.po_id,
    po.po_line_number,
    {{ to_date_key('po.order_date') }} as order_date_key,
    case when po.requested_date is null then null else {{ to_date_key('po.requested_date') }} end as requested_date_key,
    case when po.promised_date is null then null else {{ to_date_key('po.promised_date') }} end as promised_date_key,
    case when po.received_date is null then null else {{ to_date_key('po.received_date') }} end as received_date_key,
    s.supplier_key,
    p.product_key,
    w.warehouse_key,
    st.status_key,
    coalesce(po.ordered_qty, 0) as ordered_qty,
    coalesce(po.received_qty, 0) as received_qty,
    coalesce(po.cancelled_qty, 0) as cancelled_qty,
    coalesce(po.unit_cost, 0) as unit_cost,
    round(coalesce(po.ordered_qty, 0) * coalesce(po.unit_cost, 0), 2) as ordered_amount,
    round(coalesce(po.received_qty, 0) * coalesce(po.unit_cost, 0), 2) as received_amount,
    po.currency_code
from po
inner join {{ ref('dim_supplier') }} s on s.supplier_id = po.supplier_id
inner join {{ ref('dim_product') }} p on p.product_id = po.product_id
inner join {{ ref('dim_warehouse') }} w on w.warehouse_id = po.warehouse_id
inner join {{ ref('dim_status') }} st
    on st.status_domain = 'purchase_order'
   and st.status_code = po.status_code
