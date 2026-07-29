select
    s.supplier_id,
    s.supplier_name,
    s.preferred_flag,
    count(*) as po_lines,
    sum(f.ordered_qty) as ordered_qty,
    sum(f.received_qty) as received_qty,
    sum(f.ordered_amount) as ordered_amount,
    sum(case when f.received_date_key is not null then 1 else 0 end) as received_lines,
    sum(
        case
            when f.received_date_key is not null
             and f.promised_date_key is not null
             and f.received_date_key <= f.promised_date_key then 1
            else 0
        end
    ) as on_time_receipts,
    round(
        100.0 * sum(
            case
                when f.received_date_key is not null
                 and f.promised_date_key is not null
                 and f.received_date_key <= f.promised_date_key then 1
                else 0
            end
        ) / nullif(sum(case when f.received_date_key is not null then 1 else 0 end), 0)
    , 1) as on_time_pct,
    round(
        100.0 * sum(f.received_qty) / nullif(sum(f.ordered_qty), 0)
    , 1) as receipt_fill_rate_pct
from {{ ref('fact_purchase_order_line') }} f
inner join {{ ref('dim_supplier') }} s on s.supplier_key = f.supplier_key
group by s.supplier_id, s.supplier_name, s.preferred_flag
