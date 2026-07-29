-- Staging / landing tables (source-aligned)
-- Truncate-and-load or CDC into these before transforming to warehouse.*

SET search_path TO staging, public;

CREATE TABLE IF NOT EXISTS stg_product (
    product_id          VARCHAR(32) NOT NULL,
    sku                 VARCHAR(64),
    product_name        VARCHAR(200),
    category            VARCHAR(100),
    subcategory         VARCHAR(100),
    brand               VARCHAR(100),
    unit_of_measure     VARCHAR(20),
    unit_cost           NUMERIC(14, 4),
    unit_price          NUMERIC(14, 4),
    is_active           BOOLEAN,
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_supplier (
    supplier_id         VARCHAR(32) NOT NULL,
    supplier_name       VARCHAR(200),
    supplier_type       VARCHAR(50),
    country_code        CHAR(2),
    region              VARCHAR(100),
    city                VARCHAR(100),
    payment_terms       VARCHAR(50),
    lead_time_days      INTEGER,
    preferred_flag      BOOLEAN,
    is_active           BOOLEAN,
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_customer (
    customer_id         VARCHAR(32) NOT NULL,
    customer_name       VARCHAR(200),
    customer_segment    VARCHAR(50),
    country_code        CHAR(2),
    region              VARCHAR(100),
    city                VARCHAR(100),
    channel             VARCHAR(50),
    is_active           BOOLEAN,
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_warehouse (
    warehouse_id        VARCHAR(32) NOT NULL,
    warehouse_name      VARCHAR(200),
    warehouse_type      VARCHAR(50),
    country_code        CHAR(2),
    region              VARCHAR(100),
    city                VARCHAR(100),
    timezone            VARCHAR(50),
    capacity_units      NUMERIC(18, 2),
    is_active           BOOLEAN,
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_carrier (
    carrier_id          VARCHAR(32) NOT NULL,
    carrier_name        VARCHAR(200),
    carrier_mode        VARCHAR(50),
    service_level       VARCHAR(50),
    country_code        CHAR(2),
    is_active           BOOLEAN,
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_purchase_order_line (
    po_id               VARCHAR(40) NOT NULL,
    po_line_number      INTEGER NOT NULL,
    order_date          DATE,
    requested_date      DATE,
    promised_date       DATE,
    received_date       DATE,
    supplier_id         VARCHAR(32),
    product_id          VARCHAR(32),
    warehouse_id        VARCHAR(32),
    status_code         VARCHAR(30),
    ordered_qty         NUMERIC(18, 4),
    received_qty        NUMERIC(18, 4),
    cancelled_qty       NUMERIC(18, 4),
    unit_cost           NUMERIC(14, 4),
    currency_code       CHAR(3),
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_inventory_snapshot (
    snapshot_date       DATE NOT NULL,
    product_id          VARCHAR(32) NOT NULL,
    warehouse_id        VARCHAR(32) NOT NULL,
    on_hand_qty         NUMERIC(18, 4),
    reserved_qty        NUMERIC(18, 4),
    available_qty       NUMERIC(18, 4),
    in_transit_qty      NUMERIC(18, 4),
    on_order_qty        NUMERIC(18, 4),
    unit_cost           NUMERIC(14, 4),
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_inventory_movement (
    movement_id         VARCHAR(40) NOT NULL,
    movement_date       DATE,
    product_id          VARCHAR(32),
    warehouse_id        VARCHAR(32),
    supplier_id         VARCHAR(32),
    customer_id         VARCHAR(32),
    movement_type       VARCHAR(30),
    reference_doc       VARCHAR(40),
    quantity            NUMERIC(18, 4),
    unit_cost           NUMERIC(14, 4),
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_sales_order_line (
    so_id               VARCHAR(40) NOT NULL,
    so_line_number      INTEGER NOT NULL,
    order_date          DATE,
    requested_date      DATE,
    ship_date           DATE,
    customer_id         VARCHAR(32),
    product_id          VARCHAR(32),
    warehouse_id        VARCHAR(32),
    status_code         VARCHAR(30),
    ordered_qty         NUMERIC(18, 4),
    shipped_qty         NUMERIC(18, 4),
    cancelled_qty       NUMERIC(18, 4),
    unit_price          NUMERIC(14, 4),
    currency_code       CHAR(3),
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg_shipment (
    shipment_id         VARCHAR(40) NOT NULL,
    ship_date           DATE,
    promised_delivery_date DATE,
    actual_delivery_date   DATE,
    customer_id         VARCHAR(32),
    warehouse_id        VARCHAR(32),
    carrier_id          VARCHAR(32),
    status_code         VARCHAR(30),
    so_id               VARCHAR(40),
    package_count       INTEGER,
    total_weight_kg     NUMERIC(12, 3),
    freight_cost        NUMERIC(14, 2),
    currency_code       CHAR(3),
    extracted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
