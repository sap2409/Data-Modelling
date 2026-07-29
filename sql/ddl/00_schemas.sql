-- Supply Chain DWH schemas
-- Layers: staging (raw/landing) → warehouse (dimensional)

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA staging IS 'Source-aligned landing tables (append / truncate-load)';
COMMENT ON SCHEMA warehouse IS 'Dimensional star-schema tables for supply chain analytics';
COMMENT ON SCHEMA analytics IS 'Optional views and marts built on warehouse facts';
