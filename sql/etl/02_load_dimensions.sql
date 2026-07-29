-- Load / upsert dimensions from staging
-- Includes dim_date generation for the sample date range and status seeds.

SET search_path TO warehouse, staging, public;

-- ---------------------------------------------------------------------------
-- dim_date: generate calendar for 2025-01-01 .. 2027-12-31
-- ---------------------------------------------------------------------------
INSERT INTO dim_date (
    date_key, full_date, day_of_week, day_name, day_of_month, day_of_year,
    week_of_year, month_number, month_name, quarter_number, quarter_name,
    year_number, is_weekend, is_month_end, fiscal_year, fiscal_quarter
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_key,
    d AS full_date,
    EXTRACT(ISODOW FROM d)::SMALLINT AS day_of_week,
    TO_CHAR(d, 'Dy') AS day_name,
    EXTRACT(DAY FROM d)::SMALLINT AS day_of_month,
    EXTRACT(DOY FROM d)::SMALLINT AS day_of_year,
    EXTRACT(WEEK FROM d)::SMALLINT AS week_of_year,
    EXTRACT(MONTH FROM d)::SMALLINT AS month_number,
    TO_CHAR(d, 'Mon') AS month_name,
    EXTRACT(QUARTER FROM d)::SMALLINT AS quarter_number,
    'Q' || EXTRACT(QUARTER FROM d)::TEXT AS quarter_name,
    EXTRACT(YEAR FROM d)::SMALLINT AS year_number,
    EXTRACT(ISODOW FROM d) IN (6, 7) AS is_weekend,
    d = (DATE_TRUNC('month', d) + INTERVAL '1 month - 1 day')::DATE AS is_month_end,
    EXTRACT(YEAR FROM d)::SMALLINT AS fiscal_year,
    EXTRACT(QUARTER FROM d)::SMALLINT AS fiscal_quarter
FROM generate_series(DATE '2025-01-01', DATE '2027-12-31', INTERVAL '1 day') AS g(d)
ON CONFLICT (date_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Status reference values
-- ---------------------------------------------------------------------------
INSERT INTO dim_status (status_code, status_name, status_domain, is_terminal, sort_order)
VALUES
    ('open', 'Open', 'purchase_order', FALSE, 1),
    ('partial', 'Partially Received', 'purchase_order', FALSE, 2),
    ('received', 'Fully Received', 'purchase_order', TRUE, 3),
    ('cancelled', 'Cancelled', 'purchase_order', TRUE, 4),
    ('open', 'Open', 'sales_order', FALSE, 1),
    ('allocated', 'Allocated', 'sales_order', FALSE, 2),
    ('shipped', 'Shipped', 'sales_order', TRUE, 3),
    ('cancelled', 'Cancelled', 'sales_order', TRUE, 4),
    ('in_transit', 'In Transit', 'shipment', FALSE, 1),
    ('delivered', 'Delivered', 'shipment', TRUE, 2),
    ('exception', 'Exception', 'shipment', TRUE, 3)
ON CONFLICT (status_domain, status_code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Conformed dimensions (Type 1 upsert on natural key)
-- ---------------------------------------------------------------------------
INSERT INTO dim_product (
    product_id, sku, product_name, category, subcategory, brand,
    unit_of_measure, unit_cost, unit_price, is_active
)
SELECT
    product_id, sku, product_name, category, subcategory, brand,
    COALESCE(unit_of_measure, 'EA'), unit_cost, unit_price, COALESCE(is_active, TRUE)
FROM stg_product
ON CONFLICT (product_id) DO UPDATE SET
    sku = EXCLUDED.sku,
    product_name = EXCLUDED.product_name,
    category = EXCLUDED.category,
    subcategory = EXCLUDED.subcategory,
    brand = EXCLUDED.brand,
    unit_of_measure = EXCLUDED.unit_of_measure,
    unit_cost = EXCLUDED.unit_cost,
    unit_price = EXCLUDED.unit_price,
    is_active = EXCLUDED.is_active,
    loaded_at = CURRENT_TIMESTAMP;

INSERT INTO dim_supplier (
    supplier_id, supplier_name, supplier_type, country_code, region, city,
    payment_terms, lead_time_days, preferred_flag, is_active
)
SELECT
    supplier_id, supplier_name, supplier_type, country_code, region, city,
    payment_terms, lead_time_days, COALESCE(preferred_flag, FALSE), COALESCE(is_active, TRUE)
FROM stg_supplier
ON CONFLICT (supplier_id) DO UPDATE SET
    supplier_name = EXCLUDED.supplier_name,
    supplier_type = EXCLUDED.supplier_type,
    country_code = EXCLUDED.country_code,
    region = EXCLUDED.region,
    city = EXCLUDED.city,
    payment_terms = EXCLUDED.payment_terms,
    lead_time_days = EXCLUDED.lead_time_days,
    preferred_flag = EXCLUDED.preferred_flag,
    is_active = EXCLUDED.is_active,
    loaded_at = CURRENT_TIMESTAMP;

INSERT INTO dim_customer (
    customer_id, customer_name, customer_segment, country_code, region, city, channel, is_active
)
SELECT
    customer_id, customer_name, customer_segment, country_code, region, city, channel, COALESCE(is_active, TRUE)
FROM stg_customer
ON CONFLICT (customer_id) DO UPDATE SET
    customer_name = EXCLUDED.customer_name,
    customer_segment = EXCLUDED.customer_segment,
    country_code = EXCLUDED.country_code,
    region = EXCLUDED.region,
    city = EXCLUDED.city,
    channel = EXCLUDED.channel,
    is_active = EXCLUDED.is_active,
    loaded_at = CURRENT_TIMESTAMP;

INSERT INTO dim_warehouse (
    warehouse_id, warehouse_name, warehouse_type, country_code, region, city,
    timezone, capacity_units, is_active
)
SELECT
    warehouse_id, warehouse_name, warehouse_type, country_code, region, city,
    timezone, capacity_units, COALESCE(is_active, TRUE)
FROM stg_warehouse
ON CONFLICT (warehouse_id) DO UPDATE SET
    warehouse_name = EXCLUDED.warehouse_name,
    warehouse_type = EXCLUDED.warehouse_type,
    country_code = EXCLUDED.country_code,
    region = EXCLUDED.region,
    city = EXCLUDED.city,
    timezone = EXCLUDED.timezone,
    capacity_units = EXCLUDED.capacity_units,
    is_active = EXCLUDED.is_active,
    loaded_at = CURRENT_TIMESTAMP;

INSERT INTO dim_carrier (
    carrier_id, carrier_name, carrier_mode, service_level, country_code, is_active
)
SELECT
    carrier_id, carrier_name, carrier_mode, service_level, country_code, COALESCE(is_active, TRUE)
FROM stg_carrier
ON CONFLICT (carrier_id) DO UPDATE SET
    carrier_name = EXCLUDED.carrier_name,
    carrier_mode = EXCLUDED.carrier_mode,
    service_level = EXCLUDED.service_level,
    country_code = EXCLUDED.country_code,
    is_active = EXCLUDED.is_active,
    loaded_at = CURRENT_TIMESTAMP;
