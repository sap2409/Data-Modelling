# Architecture

## Purpose

Analytical warehouse for supply chain operations: procurement, inventory, order fulfillment, and logistics. Designed as a **conformed dimensional model** (Kimball-style star schemas) with a thin staging layer for source landing.

## Layers

```text
 Operational systems          Staging                 Warehouse              Analytics
 ┌──────────────┐         ┌─────────────┐         ┌──────────────┐       ┌────────────┐
 │ ERP / WMS /  │  extract│ staging.*   │ transform│ warehouse.*  │  query │ KPI SQL /  │
 │ OMS / TMS /  │ ──────► │ source-     │ ───────► │ dims + facts │ ─────► │ BI tools   │
 │ CRM          │         │ aligned     │          │              │       │            │
 └──────────────┘         └─────────────┘         └──────────────┘       └────────────┘
```

| Layer | Schema | Role |
|-------|--------|------|
| Staging | `staging` | Truncate-load or CDC landing; mirrors source grain and keys |
| Warehouse | `warehouse` | Surrogate-keyed dimensions and additive facts |
| Analytics | `analytics` | Optional marts / views (reserved) |

## Conformed dimensions

Shared across facts so KPIs can be combined without remapping:

- `dim_date`, `dim_product`, `dim_supplier`, `dim_customer`, `dim_warehouse`, `dim_carrier`, `dim_status`

## Fact overview

| Fact | Business process | Grain |
|------|------------------|-------|
| `fact_purchase_order_line` | Procure-to-pay (order side) | PO + line |
| `fact_inventory_snapshot` | Inventory position | Product + warehouse + day |
| `fact_inventory_movement` | Stock ledger | Movement event |
| `fact_sales_order_line` | Order-to-cash (order side) | SO + line |
| `fact_shipment` | Deliver | Shipment |

## Keys & history

- Surrogate keys (`*_key`) are warehouse primary keys.
- Natural keys (`product_id`, `po_id`, …) are unique and used for upserts.
- Sample ETL uses **SCD Type 1** (overwrite) on dimensions. Extend to Type 2 with `effective_from` / `effective_to` already present on `dim_product` when supplier/product attributes must be historically accurate.

## Slowly changing & late data

- Facts upsert on business keys so late-arriving receipts / shipments can refresh measures.
- Snapshot facts are periodic; do not reconstruct history from movements in the sample load (movements support audit / flow analysis).

## Target platform

DDL is **PostgreSQL 14+**. Porting notes:

- Snowflake: replace `SERIAL`/`BIGSERIAL` with `IDENTITY`, `\copy` with `COPY INTO`
- BigQuery: use `INT64` / `NUMERIC`, partition facts by date
- Redshift: `IDENTITY`, `DISTKEY`/`SORTKEY` on date + foreign keys

## Non-goals (v1)

- Real-time streaming ingestion
- Multi-currency FX conversion tables
- Full SCD2 implementation
- Role-based security / row-level policies
