-- Dimension tables (warehouse schema)
-- Convention: *_key = surrogate PK; *_id / codes = natural/business keys

SET search_path TO warehouse, public;

-- ---------------------------------------------------------------------------
-- Date dimension
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_date (
    date_key            INTEGER PRIMARY KEY,          -- YYYYMMDD
    full_date           DATE NOT NULL UNIQUE,
    day_of_week         SMALLINT NOT NULL,           -- 1=Mon .. 7=Sun
    day_name            VARCHAR(10) NOT NULL,
    day_of_month        SMALLINT NOT NULL,
    day_of_year         SMALLINT NOT NULL,
    week_of_year        SMALLINT NOT NULL,
    month_number        SMALLINT NOT NULL,
    month_name          VARCHAR(10) NOT NULL,
    quarter_number      SMALLINT NOT NULL,
    quarter_name        VARCHAR(2) NOT NULL,         -- Q1..Q4
    year_number         SMALLINT NOT NULL,
    is_weekend          BOOLEAN NOT NULL,
    is_month_end        BOOLEAN NOT NULL,
    fiscal_year         SMALLINT NOT NULL,
    fiscal_quarter      SMALLINT NOT NULL
);

-- ---------------------------------------------------------------------------
-- Product
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_product (
    product_key         SERIAL PRIMARY KEY,
    product_id          VARCHAR(32) NOT NULL,
    sku                 VARCHAR(64) NOT NULL,
    product_name        VARCHAR(200) NOT NULL,
    category            VARCHAR(100),
    subcategory         VARCHAR(100),
    brand               VARCHAR(100),
    unit_of_measure     VARCHAR(20) NOT NULL DEFAULT 'EA',
    unit_cost           NUMERIC(14, 4),
    unit_price          NUMERIC(14, 4),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    effective_from      DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to        DATE,
    source_system       VARCHAR(50) DEFAULT 'erp',
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dim_product_id UNIQUE (product_id)
);

-- ---------------------------------------------------------------------------
-- Supplier
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_key        SERIAL PRIMARY KEY,
    supplier_id         VARCHAR(32) NOT NULL,
    supplier_name       VARCHAR(200) NOT NULL,
    supplier_type       VARCHAR(50),                  -- manufacturer, distributor, 3PL
    country_code        CHAR(2),
    region              VARCHAR(100),
    city                VARCHAR(100),
    payment_terms       VARCHAR(50),
    lead_time_days      INTEGER,
    preferred_flag      BOOLEAN NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    source_system       VARCHAR(50) DEFAULT 'erp',
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dim_supplier_id UNIQUE (supplier_id)
);

-- ---------------------------------------------------------------------------
-- Customer
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key        SERIAL PRIMARY KEY,
    customer_id         VARCHAR(32) NOT NULL,
    customer_name       VARCHAR(200) NOT NULL,
    customer_segment    VARCHAR(50),                  -- retail, wholesale, ecommerce
    country_code        CHAR(2),
    region              VARCHAR(100),
    city                VARCHAR(100),
    channel             VARCHAR(50),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    source_system       VARCHAR(50) DEFAULT 'crm',
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dim_customer_id UNIQUE (customer_id)
);

-- ---------------------------------------------------------------------------
-- Warehouse / distribution center
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_warehouse (
    warehouse_key       SERIAL PRIMARY KEY,
    warehouse_id        VARCHAR(32) NOT NULL,
    warehouse_name      VARCHAR(200) NOT NULL,
    warehouse_type      VARCHAR(50),                  -- DC, plant, store, 3PL
    country_code        CHAR(2),
    region              VARCHAR(100),
    city                VARCHAR(100),
    timezone            VARCHAR(50),
    capacity_units      NUMERIC(18, 2),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    source_system       VARCHAR(50) DEFAULT 'wms',
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dim_warehouse_id UNIQUE (warehouse_id)
);

-- ---------------------------------------------------------------------------
-- Carrier
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_carrier (
    carrier_key         SERIAL PRIMARY KEY,
    carrier_id          VARCHAR(32) NOT NULL,
    carrier_name        VARCHAR(200) NOT NULL,
    carrier_mode        VARCHAR(50),                  -- road, air, ocean, rail, parcel
    service_level       VARCHAR(50),                  -- standard, express, economy
    country_code        CHAR(2),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    source_system       VARCHAR(50) DEFAULT 'tms',
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dim_carrier_id UNIQUE (carrier_id)
);

-- ---------------------------------------------------------------------------
-- Status (generic degenerated status dim for orders / shipments)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_status (
    status_key          SERIAL PRIMARY KEY,
    status_code         VARCHAR(30) NOT NULL,
    status_name         VARCHAR(100) NOT NULL,
    status_domain       VARCHAR(50) NOT NULL,        -- purchase_order, sales_order, shipment, inventory
    is_terminal         BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order          SMALLINT,
    CONSTRAINT uq_dim_status UNIQUE (status_domain, status_code)
);

-- Unknown / not applicable members (key = -1 pattern via explicit insert later)
CREATE TABLE IF NOT EXISTS dim_unknown_member (
    entity_name         VARCHAR(50) PRIMARY KEY,
    surrogate_key       INTEGER NOT NULL
);
