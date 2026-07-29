with so as (
    select * from {{ ref('stg_sales_order_lines') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['so.so_id', 'so.so_line_number']) }} as so_line_key,
    so.so_id,
    so.so_line_number,
    {{ to_date_key('so.order_date') }} as order_date_key,
    case when so.requested_date is null then null else {{ to_date_key('so.requested_date') }} end as requested_date_key,
    case when so.ship_date is null then null else {{ to_date_key('so.ship_date') }} end as ship_date_key,
    c.customer_key,
    p.product_key,
    w.warehouse_key,
    st.status_key,
    coalesce(so.ordered_qty, 0) as ordered_qty,
    coalesce(so.shipped_qty, 0) as shipped_qty,
    coalesce(so.cancelled_qty, 0) as cancelled_qty,
    coalesce(so.unit_price, 0) as unit_price,
    round(coalesce(so.ordered_qty, 0) * coalesce(so.unit_price, 0), 2) as ordered_amount,
    round(coalesce(so.shipped_qty, 0) * coalesce(so.unit_price, 0), 2) as shipped_amount,
    so.currency_code
from so
inner join {{ ref('dim_customer') }} c on c.customer_id = so.customer_id
inner join {{ ref('dim_product') }} p on p.product_id = so.product_id
inner join {{ ref('dim_warehouse') }} w on w.warehouse_id = so.warehouse_id
inner join {{ ref('dim_status') }} st
    on st.status_domain = 'sales_order'
   and st.status_code = so.status_code
