-- Load sample CSVs into staging
-- Run from repo root after DDL. Requires psql \copy (client-side).
-- Usage: psql -d supply_chain_dwh -v ON_ERROR_STOP=1 -f sql/etl/01_load_sample_data.sql

SET search_path TO staging, public;

TRUNCATE TABLE
    stg_product,
    stg_supplier,
    stg_customer,
    stg_warehouse,
    stg_carrier,
    stg_purchase_order_line,
    stg_inventory_snapshot,
    stg_inventory_movement,
    stg_sales_order_line,
    stg_shipment;

\copy stg_product (product_id, sku, product_name, category, subcategory, brand, unit_of_measure, unit_cost, unit_price, is_active) FROM 'sample_data/products.csv' CSV HEADER
\copy stg_supplier (supplier_id, supplier_name, supplier_type, country_code, region, city, payment_terms, lead_time_days, preferred_flag, is_active) FROM 'sample_data/suppliers.csv' CSV HEADER
\copy stg_customer (customer_id, customer_name, customer_segment, country_code, region, city, channel, is_active) FROM 'sample_data/customers.csv' CSV HEADER
\copy stg_warehouse (warehouse_id, warehouse_name, warehouse_type, country_code, region, city, timezone, capacity_units, is_active) FROM 'sample_data/warehouses.csv' CSV HEADER
\copy stg_carrier (carrier_id, carrier_name, carrier_mode, service_level, country_code, is_active) FROM 'sample_data/carriers.csv' CSV HEADER
\copy stg_purchase_order_line (po_id, po_line_number, order_date, requested_date, promised_date, received_date, supplier_id, product_id, warehouse_id, status_code, ordered_qty, received_qty, cancelled_qty, unit_cost, currency_code) FROM 'sample_data/purchase_order_lines.csv' CSV HEADER
\copy stg_inventory_snapshot (snapshot_date, product_id, warehouse_id, on_hand_qty, reserved_qty, available_qty, in_transit_qty, on_order_qty, unit_cost) FROM 'sample_data/inventory_snapshots.csv' CSV HEADER
\copy stg_inventory_movement (movement_id, movement_date, product_id, warehouse_id, supplier_id, customer_id, movement_type, reference_doc, quantity, unit_cost) FROM 'sample_data/inventory_movements.csv' CSV HEADER
\copy stg_sales_order_line (so_id, so_line_number, order_date, requested_date, ship_date, customer_id, product_id, warehouse_id, status_code, ordered_qty, shipped_qty, cancelled_qty, unit_price, currency_code) FROM 'sample_data/sales_order_lines.csv' CSV HEADER
\copy stg_shipment (shipment_id, ship_date, promised_delivery_date, actual_delivery_date, customer_id, warehouse_id, carrier_id, status_code, so_id, package_count, total_weight_kg, freight_cost, currency_code) FROM 'sample_data/shipments.csv' CSV HEADER
