-- Sample KPI / analytical queries for the supply chain DWH
SET search_path TO warehouse, analytics, public;

-- 1) Inventory value by warehouse (latest snapshot date in sample)
SELECT
    w.warehouse_name,
    w.region,
    SUM(f.on_hand_qty) AS on_hand_qty,
    SUM(f.available_qty) AS available_qty,
    SUM(f.inventory_value) AS inventory_value
FROM fact_inventory_snapshot f
JOIN dim_warehouse w ON w.warehouse_key = f.warehouse_key
JOIN dim_date d ON d.date_key = f.snapshot_date_key
WHERE d.full_date = (SELECT MAX(d2.full_date)
                     FROM fact_inventory_snapshot f2
                     JOIN dim_date d2 ON d2.date_key = f2.snapshot_date_key)
GROUP BY w.warehouse_name, w.region
ORDER BY inventory_value DESC;

-- 2) Supplier on-time receipt rate
SELECT
    s.supplier_name,
    COUNT(*) AS po_lines,
    SUM(CASE WHEN f.received_date_key IS NOT NULL
              AND f.received_date_key <= f.promised_date_key THEN 1 ELSE 0 END) AS on_time_receipts,
    ROUND(
        100.0 * SUM(CASE WHEN f.received_date_key IS NOT NULL
                          AND f.received_date_key <= f.promised_date_key THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.received_date_key IS NOT NULL THEN 1 ELSE 0 END), 0)
    , 1) AS on_time_pct
FROM fact_purchase_order_line f
JOIN dim_supplier s ON s.supplier_key = f.supplier_key
GROUP BY s.supplier_name
ORDER BY on_time_pct DESC NULLS LAST;

-- 3) Fill rate by product (shipped / ordered)
SELECT
    p.sku,
    p.product_name,
    SUM(f.ordered_qty) AS ordered_qty,
    SUM(f.shipped_qty) AS shipped_qty,
    ROUND(100.0 * SUM(f.shipped_qty) / NULLIF(SUM(f.ordered_qty), 0), 1) AS fill_rate_pct
FROM fact_sales_order_line f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.sku, p.product_name
ORDER BY fill_rate_pct ASC, ordered_qty DESC;

-- 4) OTIF by carrier
SELECT
    c.carrier_name,
    c.carrier_mode,
    COUNT(*) AS shipments,
    SUM(CASE WHEN f.is_otif THEN 1 ELSE 0 END) AS otif_count,
    ROUND(100.0 * SUM(CASE WHEN f.is_otif THEN 1 ELSE 0 END) / COUNT(*), 1) AS otif_pct,
    SUM(f.freight_cost) AS total_freight_cost
FROM fact_shipment f
JOIN dim_carrier c ON c.carrier_key = f.carrier_key
GROUP BY c.carrier_name, c.carrier_mode
ORDER BY otif_pct DESC;

-- 5) Open purchase orders (pipeline)
SELECT
    f.po_id,
    f.po_line_number,
    s.supplier_name,
    p.sku,
    w.warehouse_name,
    st.status_name,
    f.ordered_qty,
    f.received_qty,
    f.ordered_qty - f.received_qty - f.cancelled_qty AS open_qty,
    f.ordered_amount
FROM fact_purchase_order_line f
JOIN dim_supplier s ON s.supplier_key = f.supplier_key
JOIN dim_product p ON p.product_key = f.product_key
JOIN dim_warehouse w ON w.warehouse_key = f.warehouse_key
JOIN dim_status st ON st.status_key = f.status_key
WHERE st.is_terminal = FALSE
ORDER BY f.po_id, f.po_line_number;

-- 6) Inventory movement summary by type
SELECT
    f.movement_type,
    COUNT(*) AS movement_count,
    SUM(f.quantity) AS net_qty,
    SUM(f.movement_value) AS net_value
FROM fact_inventory_movement f
GROUP BY f.movement_type
ORDER BY f.movement_type;
