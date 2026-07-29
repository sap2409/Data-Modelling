select
    p.sku,
    p.product_name,
    p.category,
    c.customer_segment,
    c.channel,
    sum(f.ordered_qty) as ordered_qty,
    sum(f.shipped_qty) as shipped_qty,
    sum(f.ordered_amount) as ordered_amount,
    sum(f.shipped_amount) as shipped_amount,
    round(100.0 * sum(f.shipped_qty) / nullif(sum(f.ordered_qty), 0), 1) as fill_rate_pct
from {{ ref('fact_sales_order_line') }} f
inner join {{ ref('dim_product') }} p on p.product_key = f.product_key
inner join {{ ref('dim_customer') }} c on c.customer_key = f.customer_key
group by p.sku, p.product_name, p.category, c.customer_segment, c.channel
