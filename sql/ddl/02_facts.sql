-- Fact tables (warehouse schema)
-- Additive measures only; ratios computed in analytics layer

SET search_path TO warehouse, public;

-- ---------------------------------------------------------------------------
-- Purchase order line
-- Grain: one row per purchase order line
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_purchase_order_line (
    po_line_key             BIGSERIAL PRIMARY KEY,
    po_id                   VARCHAR(40) NOT NULL,
    po_line_number          INTEGER NOT NULL,
    order_date_key          INTEGER NOT NULL REFERENCES dim_date (date_key),
    requested_date_key      INTEGER REFERENCES dim_date (date_key),
    promised_date_key       INTEGER REFERENCES dim_date (date_key),
    received_date_key       INTEGER REFERENCES dim_date (date_key),
    supplier_key            INTEGER NOT NULL REFERENCES dim_supplier (supplier_key),
    product_key             INTEGER NOT NULL REFERENCES dim_product (product_key),
    warehouse_key           INTEGER NOT NULL REFERENCES dim_warehouse (warehouse_key),
    status_key              INTEGER NOT NULL REFERENCES dim_status (status_key),
    ordered_qty             NUMERIC(18, 4) NOT NULL,
    received_qty            NUMERIC(18, 4) NOT NULL DEFAULT 0,
    cancelled_qty           NUMERIC(18, 4) NOT NULL DEFAULT 0,
    unit_cost               NUMERIC(14, 4) NOT NULL,
    ordered_amount          NUMERIC(18, 2) NOT NULL,
    received_amount         NUMERIC(18, 2) NOT NULL DEFAULT 0,
    currency_code           CHAR(3) NOT NULL DEFAULT 'USD',
    source_system           VARCHAR(50) DEFAULT 'erp',
    loaded_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_po_line UNIQUE (po_id, po_line_number)
);

CREATE INDEX IF NOT EXISTS ix_fact_po_order_date ON fact_purchase_order_line (order_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_po_supplier ON fact_purchase_order_line (supplier_key);
CREATE INDEX IF NOT EXISTS ix_fact_po_product ON fact_purchase_order_line (product_key);

-- ---------------------------------------------------------------------------
-- Inventory snapshot (periodic)
-- Grain: product + warehouse + calendar day
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_inventory_snapshot (
    inventory_snapshot_key  BIGSERIAL PRIMARY KEY,
    snapshot_date_key       INTEGER NOT NULL REFERENCES dim_date (date_key),
    product_key             INTEGER NOT NULL REFERENCES dim_product (product_key),
    warehouse_key           INTEGER NOT NULL REFERENCES dim_warehouse (warehouse_key),
    on_hand_qty             NUMERIC(18, 4) NOT NULL DEFAULT 0,
    reserved_qty            NUMERIC(18, 4) NOT NULL DEFAULT 0,
    available_qty           NUMERIC(18, 4) NOT NULL DEFAULT 0,
    in_transit_qty          NUMERIC(18, 4) NOT NULL DEFAULT 0,
    on_order_qty            NUMERIC(18, 4) NOT NULL DEFAULT 0,
    inventory_value         NUMERIC(18, 2) NOT NULL DEFAULT 0,
    days_of_supply          NUMERIC(10, 2),
    source_system           VARCHAR(50) DEFAULT 'wms',
    loaded_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_inv_snap UNIQUE (snapshot_date_key, product_key, warehouse_key)
);

CREATE INDEX IF NOT EXISTS ix_fact_inv_snap_date ON fact_inventory_snapshot (snapshot_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_inv_snap_product ON fact_inventory_snapshot (product_key);

-- ---------------------------------------------------------------------------
-- Inventory movement (transactional)
-- Grain: one stock movement event
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_inventory_movement (
    movement_key            BIGSERIAL PRIMARY KEY,
    movement_id             VARCHAR(40) NOT NULL,
    movement_date_key       INTEGER NOT NULL REFERENCES dim_date (date_key),
    product_key             INTEGER NOT NULL REFERENCES dim_product (product_key),
    warehouse_key           INTEGER NOT NULL REFERENCES dim_warehouse (warehouse_key),
    supplier_key            INTEGER REFERENCES dim_supplier (supplier_key),
    customer_key            INTEGER REFERENCES dim_customer (customer_key),
    movement_type           VARCHAR(30) NOT NULL,    -- receipt, issue, transfer_in, transfer_out, adjust
    reference_doc           VARCHAR(40),
    quantity                NUMERIC(18, 4) NOT NULL, -- signed: + in, - out
    unit_cost               NUMERIC(14, 4),
    movement_value          NUMERIC(18, 2),
    source_system           VARCHAR(50) DEFAULT 'wms',
    loaded_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_inv_move UNIQUE (movement_id)
);

CREATE INDEX IF NOT EXISTS ix_fact_inv_move_date ON fact_inventory_movement (movement_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_inv_move_type ON fact_inventory_movement (movement_type);

-- ---------------------------------------------------------------------------
-- Sales order line
-- Grain: one row per sales order line
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_sales_order_line (
    so_line_key             BIGSERIAL PRIMARY KEY,
    so_id                   VARCHAR(40) NOT NULL,
    so_line_number          INTEGER NOT NULL,
    order_date_key          INTEGER NOT NULL REFERENCES dim_date (date_key),
    requested_date_key      INTEGER REFERENCES dim_date (date_key),
    ship_date_key           INTEGER REFERENCES dim_date (date_key),
    customer_key            INTEGER NOT NULL REFERENCES dim_customer (customer_key),
    product_key             INTEGER NOT NULL REFERENCES dim_product (product_key),
    warehouse_key           INTEGER NOT NULL REFERENCES dim_warehouse (warehouse_key),
    status_key              INTEGER NOT NULL REFERENCES dim_status (status_key),
    ordered_qty             NUMERIC(18, 4) NOT NULL,
    shipped_qty             NUMERIC(18, 4) NOT NULL DEFAULT 0,
    cancelled_qty           NUMERIC(18, 4) NOT NULL DEFAULT 0,
    unit_price              NUMERIC(14, 4) NOT NULL,
    ordered_amount          NUMERIC(18, 2) NOT NULL,
    shipped_amount          NUMERIC(18, 2) NOT NULL DEFAULT 0,
    currency_code           CHAR(3) NOT NULL DEFAULT 'USD',
    source_system           VARCHAR(50) DEFAULT 'oms',
    loaded_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_so_line UNIQUE (so_id, so_line_number)
);

CREATE INDEX IF NOT EXISTS ix_fact_so_order_date ON fact_sales_order_line (order_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_so_customer ON fact_sales_order_line (customer_key);
CREATE INDEX IF NOT EXISTS ix_fact_so_product ON fact_sales_order_line (product_key);

-- ---------------------------------------------------------------------------
-- Shipment
-- Grain: one row per shipment
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_shipment (
    shipment_key            BIGSERIAL PRIMARY KEY,
    shipment_id             VARCHAR(40) NOT NULL,
    ship_date_key           INTEGER NOT NULL REFERENCES dim_date (date_key),
    promised_delivery_date_key INTEGER REFERENCES dim_date (date_key),
    actual_delivery_date_key   INTEGER REFERENCES dim_date (date_key),
    customer_key            INTEGER NOT NULL REFERENCES dim_customer (customer_key),
    warehouse_key           INTEGER NOT NULL REFERENCES dim_warehouse (warehouse_key),
    carrier_key             INTEGER NOT NULL REFERENCES dim_carrier (carrier_key),
    status_key              INTEGER NOT NULL REFERENCES dim_status (status_key),
    so_id                   VARCHAR(40),
    package_count           INTEGER NOT NULL DEFAULT 1,
    total_weight_kg         NUMERIC(12, 3),
    freight_cost            NUMERIC(14, 2) NOT NULL DEFAULT 0,
    is_on_time              BOOLEAN,
    is_in_full              BOOLEAN,
    is_otif                 BOOLEAN,                  -- on time in full
    currency_code           CHAR(3) NOT NULL DEFAULT 'USD',
    source_system           VARCHAR(50) DEFAULT 'tms',
    loaded_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_shipment UNIQUE (shipment_id)
);

CREATE INDEX IF NOT EXISTS ix_fact_ship_date ON fact_shipment (ship_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_ship_carrier ON fact_shipment (carrier_key);
CREATE INDEX IF NOT EXISTS ix_fact_ship_customer ON fact_shipment (customer_key);
