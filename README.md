# Supply Chain Data Warehouse

Dimensional data model and SQL assets for a supply chain analytics warehouse covering **procurement**, **inventory**, **order fulfillment**, and **logistics**.

## What's included

| Area | Contents |
|------|----------|
| Architecture | Medallion layers (staging → warehouse), star schemas, grain definitions |
| DDL | Dimension and fact table definitions (PostgreSQL-compatible) |
| Staging | Source-aligned landing tables for operational systems |
| Sample data | CSV seeds for local exploration |
| ETL sketches | Load / transform patterns from staging into the warehouse |
| Analytics | Example business questions as SQL |

## Subject areas

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ Procurement │   │  Inventory  │   │ Fulfillment │   │  Logistics  │
│  PO lines   │   │ snapshots & │   │ sales order │   │  shipments  │
│  receipts   │   │  movements  │   │    lines    │   │             │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │                 │
       └─────────────────┴────────┬────────┴─────────────────┘
                                  │
                    Shared dimensions: Date, Product,
                    Supplier, Customer, Warehouse,
                    Carrier, Status
```

## Project layout

```
docs/                 Architecture, data dictionary, business questions
sql/ddl/              CREATE SCHEMA / TABLE scripts
sql/etl/              Staging → warehouse load patterns
sql/analytics/        Reporting / KPI queries
sample_data/          CSV seed files
diagrams/             Mermaid ER / lineage sketches
```

## Quick start (PostgreSQL)

```bash
# 1. Create database
createdb supply_chain_dwh

# 2. Apply DDL
psql -d supply_chain_dwh -f sql/ddl/00_schemas.sql
psql -d supply_chain_dwh -f sql/ddl/01_dimensions.sql
psql -d supply_chain_dwh -f sql/ddl/02_facts.sql
psql -d supply_chain_dwh -f sql/ddl/03_staging.sql

# 3. Load sample CSVs into staging (adjust paths as needed)
psql -d supply_chain_dwh -f sql/etl/01_load_sample_data.sql

# 4. Transform into warehouse tables
psql -d supply_chain_dwh -f sql/etl/02_load_dimensions.sql
psql -d supply_chain_dwh -f sql/etl/03_load_facts.sql

# 5. Run sample analytics
psql -d supply_chain_dwh -f sql/analytics/kpi_queries.sql
```

## Core facts (grain)

| Fact | Grain |
|------|--------|
| `fact_purchase_order_line` | One row per PO line |
| `fact_inventory_snapshot` | One row per product + warehouse + day |
| `fact_inventory_movement` | One row per stock movement event |
| `fact_sales_order_line` | One row per sales order line |
| `fact_shipment` | One row per shipment |

## Docs

- [Architecture](docs/architecture.md)
- [Data dictionary](docs/data-dictionary.md)
- [Business questions](docs/business-questions.md)

## Design notes

- Surrogate keys on all dimensions; natural/business keys retained for SCD and lineage.
- `dim_date` is generated; other dims support Type 1 overwrite in the sample ETL (extend to SCD2 as needed).
- Facts store additive measures; ratios (fill rate, OTIF) are computed in analytics SQL.
- SQL targets PostgreSQL 14+; adjust types for Snowflake / BigQuery / Redshift if you port the model.
