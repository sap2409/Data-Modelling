-- Transform staging transactions into warehouse facts
-- Assumes dimensions already loaded.

SET search_path TO warehouse, staging, public;

-- ---------------------------------------------------------------------------
-- Purchase order lines
-- ---------------------------------------------------------------------------
INSERT INTO fact_purchase_order_line (
    po_id, po_line_number,
    order_date_key, requested_date_key, promised_date_key, received_date_key,
    supplier_key, product_key, warehouse_key, status_key,
    ordered_qty, received_qty, cancelled_qty, unit_cost,
    ordered_amount, received_amount, currency_code
)
SELECT
    s.po_id,
    s.po_line_number,
    TO_CHAR(s.order_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.requested_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.promised_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.received_date, 'YYYYMMDD')::INTEGER,
    sup.supplier_key,
    p.product_key,
    w.warehouse_key,
    st.status_key,
    COALESCE(s.ordered_qty, 0),
    COALESCE(s.received_qty, 0),
    COALESCE(s.cancelled_qty, 0),
    COALESCE(s.unit_cost, 0),
    ROUND(COALESCE(s.ordered_qty, 0) * COALESCE(s.unit_cost, 0), 2),
    ROUND(COALESCE(s.received_qty, 0) * COALESCE(s.unit_cost, 0), 2),
    COALESCE(s.currency_code, 'USD')
FROM stg_purchase_order_line s
JOIN dim_supplier  sup ON sup.supplier_id = s.supplier_id
JOIN dim_product   p   ON p.product_id = s.product_id
JOIN dim_warehouse w   ON w.warehouse_id = s.warehouse_id
JOIN dim_status    st  ON st.status_domain = 'purchase_order' AND st.status_code = s.status_code
ON CONFLICT (po_id, po_line_number) DO UPDATE SET
    order_date_key = EXCLUDED.order_date_key,
    requested_date_key = EXCLUDED.requested_date_key,
    promised_date_key = EXCLUDED.promised_date_key,
    received_date_key = EXCLUDED.received_date_key,
    supplier_key = EXCLUDED.supplier_key,
    product_key = EXCLUDED.product_key,
    warehouse_key = EXCLUDED.warehouse_key,
    status_key = EXCLUDED.status_key,
    ordered_qty = EXCLUDED.ordered_qty,
    received_qty = EXCLUDED.received_qty,
    cancelled_qty = EXCLUDED.cancelled_qty,
    unit_cost = EXCLUDED.unit_cost,
    ordered_amount = EXCLUDED.ordered_amount,
    received_amount = EXCLUDED.received_amount,
    currency_code = EXCLUDED.currency_code,
    loaded_at = CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------------
-- Inventory snapshots
-- ---------------------------------------------------------------------------
INSERT INTO fact_inventory_snapshot (
    snapshot_date_key, product_key, warehouse_key,
    on_hand_qty, reserved_qty, available_qty, in_transit_qty, on_order_qty,
    inventory_value
)
SELECT
    TO_CHAR(s.snapshot_date, 'YYYYMMDD')::INTEGER,
    p.product_key,
    w.warehouse_key,
    COALESCE(s.on_hand_qty, 0),
    COALESCE(s.reserved_qty, 0),
    COALESCE(s.available_qty, 0),
    COALESCE(s.in_transit_qty, 0),
    COALESCE(s.on_order_qty, 0),
    ROUND(COALESCE(s.on_hand_qty, 0) * COALESCE(s.unit_cost, 0), 2)
FROM stg_inventory_snapshot s
JOIN dim_product   p ON p.product_id = s.product_id
JOIN dim_warehouse w ON w.warehouse_id = s.warehouse_id
ON CONFLICT (snapshot_date_key, product_key, warehouse_key) DO UPDATE SET
    on_hand_qty = EXCLUDED.on_hand_qty,
    reserved_qty = EXCLUDED.reserved_qty,
    available_qty = EXCLUDED.available_qty,
    in_transit_qty = EXCLUDED.in_transit_qty,
    on_order_qty = EXCLUDED.on_order_qty,
    inventory_value = EXCLUDED.inventory_value,
    loaded_at = CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------------
-- Inventory movements
-- ---------------------------------------------------------------------------
INSERT INTO fact_inventory_movement (
    movement_id, movement_date_key, product_key, warehouse_key,
    supplier_key, customer_key, movement_type, reference_doc,
    quantity, unit_cost, movement_value
)
SELECT
    s.movement_id,
    TO_CHAR(s.movement_date, 'YYYYMMDD')::INTEGER,
    p.product_key,
    w.warehouse_key,
    sup.supplier_key,
    c.customer_key,
    s.movement_type,
    s.reference_doc,
    COALESCE(s.quantity, 0),
    s.unit_cost,
    ROUND(COALESCE(s.quantity, 0) * COALESCE(s.unit_cost, 0), 2)
FROM stg_inventory_movement s
JOIN dim_product   p ON p.product_id = s.product_id
JOIN dim_warehouse w ON w.warehouse_id = s.warehouse_id
LEFT JOIN dim_supplier  sup ON sup.supplier_id = NULLIF(s.supplier_id, '')
LEFT JOIN dim_customer  c   ON c.customer_id = NULLIF(s.customer_id, '')
ON CONFLICT (movement_id) DO UPDATE SET
    movement_date_key = EXCLUDED.movement_date_key,
    product_key = EXCLUDED.product_key,
    warehouse_key = EXCLUDED.warehouse_key,
    supplier_key = EXCLUDED.supplier_key,
    customer_key = EXCLUDED.customer_key,
    movement_type = EXCLUDED.movement_type,
    reference_doc = EXCLUDED.reference_doc,
    quantity = EXCLUDED.quantity,
    unit_cost = EXCLUDED.unit_cost,
    movement_value = EXCLUDED.movement_value,
    loaded_at = CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------------
-- Sales order lines
-- ---------------------------------------------------------------------------
INSERT INTO fact_sales_order_line (
    so_id, so_line_number,
    order_date_key, requested_date_key, ship_date_key,
    customer_key, product_key, warehouse_key, status_key,
    ordered_qty, shipped_qty, cancelled_qty, unit_price,
    ordered_amount, shipped_amount, currency_code
)
SELECT
    s.so_id,
    s.so_line_number,
    TO_CHAR(s.order_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.requested_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.ship_date, 'YYYYMMDD')::INTEGER,
    c.customer_key,
    p.product_key,
    w.warehouse_key,
    st.status_key,
    COALESCE(s.ordered_qty, 0),
    COALESCE(s.shipped_qty, 0),
    COALESCE(s.cancelled_qty, 0),
    COALESCE(s.unit_price, 0),
    ROUND(COALESCE(s.ordered_qty, 0) * COALESCE(s.unit_price, 0), 2),
    ROUND(COALESCE(s.shipped_qty, 0) * COALESCE(s.unit_price, 0), 2),
    COALESCE(s.currency_code, 'USD')
FROM stg_sales_order_line s
JOIN dim_customer  c  ON c.customer_id = s.customer_id
JOIN dim_product   p  ON p.product_id = s.product_id
JOIN dim_warehouse w  ON w.warehouse_id = s.warehouse_id
JOIN dim_status    st ON st.status_domain = 'sales_order' AND st.status_code = s.status_code
ON CONFLICT (so_id, so_line_number) DO UPDATE SET
    order_date_key = EXCLUDED.order_date_key,
    requested_date_key = EXCLUDED.requested_date_key,
    ship_date_key = EXCLUDED.ship_date_key,
    customer_key = EXCLUDED.customer_key,
    product_key = EXCLUDED.product_key,
    warehouse_key = EXCLUDED.warehouse_key,
    status_key = EXCLUDED.status_key,
    ordered_qty = EXCLUDED.ordered_qty,
    shipped_qty = EXCLUDED.shipped_qty,
    cancelled_qty = EXCLUDED.cancelled_qty,
    unit_price = EXCLUDED.unit_price,
    ordered_amount = EXCLUDED.ordered_amount,
    shipped_amount = EXCLUDED.shipped_amount,
    currency_code = EXCLUDED.currency_code,
    loaded_at = CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------------
-- Shipments (+ derived OTIF flags)
-- ---------------------------------------------------------------------------
INSERT INTO fact_shipment (
    shipment_id, ship_date_key, promised_delivery_date_key, actual_delivery_date_key,
    customer_key, warehouse_key, carrier_key, status_key,
    so_id, package_count, total_weight_kg, freight_cost,
    is_on_time, is_in_full, is_otif, currency_code
)
SELECT
    s.shipment_id,
    TO_CHAR(s.ship_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.promised_delivery_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(s.actual_delivery_date, 'YYYYMMDD')::INTEGER,
    c.customer_key,
    w.warehouse_key,
    car.carrier_key,
    st.status_key,
    s.so_id,
    COALESCE(s.package_count, 1),
    s.total_weight_kg,
    COALESCE(s.freight_cost, 0),
    CASE
        WHEN s.actual_delivery_date IS NULL OR s.promised_delivery_date IS NULL THEN NULL
        ELSE s.actual_delivery_date <= s.promised_delivery_date
    END AS is_on_time,
    -- Sample: treat delivered status as in-full unless freight exception (extend with line-level later)
    CASE WHEN s.status_code = 'delivered' THEN TRUE ELSE NULL END AS is_in_full,
    CASE
        WHEN s.actual_delivery_date IS NULL OR s.promised_delivery_date IS NULL THEN NULL
        ELSE (s.actual_delivery_date <= s.promised_delivery_date) AND (s.status_code = 'delivered')
    END AS is_otif,
    COALESCE(s.currency_code, 'USD')
FROM stg_shipment s
JOIN dim_customer  c   ON c.customer_id = s.customer_id
JOIN dim_warehouse w   ON w.warehouse_id = s.warehouse_id
JOIN dim_carrier   car ON car.carrier_id = s.carrier_id
JOIN dim_status    st  ON st.status_domain = 'shipment' AND st.status_code = s.status_code
ON CONFLICT (shipment_id) DO UPDATE SET
    ship_date_key = EXCLUDED.ship_date_key,
    promised_delivery_date_key = EXCLUDED.promised_delivery_date_key,
    actual_delivery_date_key = EXCLUDED.actual_delivery_date_key,
    customer_key = EXCLUDED.customer_key,
    warehouse_key = EXCLUDED.warehouse_key,
    carrier_key = EXCLUDED.carrier_key,
    status_key = EXCLUDED.status_key,
    so_id = EXCLUDED.so_id,
    package_count = EXCLUDED.package_count,
    total_weight_kg = EXCLUDED.total_weight_kg,
    freight_cost = EXCLUDED.freight_cost,
    is_on_time = EXCLUDED.is_on_time,
    is_in_full = EXCLUDED.is_in_full,
    is_otif = EXCLUDED.is_otif,
    currency_code = EXCLUDED.currency_code,
    loaded_at = CURRENT_TIMESTAMP;
