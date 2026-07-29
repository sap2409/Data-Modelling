# Overview

This dbt project builds a **supply chain data warehouse** covering procurement, inventory, order fulfillment, and logistics.

## Layers

| Layer | Location | Materialization |
|-------|----------|-----------------|
| Seeds | `seeds/` | Tables in `staging` |
| Staging | `models/staging/` | Views |
| Warehouse dims/facts | `models/warehouse/` | Tables |
| Marts | `models/marts/` | Tables in `analytics` |

## How to use docs

```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```
