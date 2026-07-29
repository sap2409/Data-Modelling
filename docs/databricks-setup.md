# Databricks setup for the supply chain dbt project

This guide deploys the same dimensional model (staging → warehouse → marts) to **Databricks SQL + Unity Catalog**.

## Prerequisites

- Databricks workspace with **Unity Catalog** enabled
- A **SQL Warehouse** (Serverless or Pro recommended)
- Permission to create schemas/tables in a catalog
- Python 3.9–3.12 recommended (`dbt-databricks`)
- Personal access token **or** OAuth (token shown below)

## 1. Create catalog / schemas

In a Databricks SQL editor:

```sql
CREATE CATALOG IF NOT EXISTS supply_chain_dwh;
USE CATALOG supply_chain_dwh;

-- dbt will also create these via generate_schema_name, but pre-creating is fine:
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS analytics;
```

## 2. Collect connection details

| Setting | Where to find it |
|---------|------------------|
| Host | Workspace URL host only, e.g. `adb-1234567890123456.7.azuredatabricks.net` (no `https://`) |
| HTTP path | SQL Warehouse → Connection details → HTTP path, e.g. `/sql/1.0/warehouses/abc123` |
| Token | User Settings → Developer → Access tokens |
| Catalog | e.g. `supply_chain_dwh` |

## 3. Install adapter

```bash
pip install dbt-databricks
# or pin:
# pip install "dbt-databricks>=1.8,<1.11"
```

## 4. Configure environment

**Windows (cmd):**

```bat
set DATABRICKS_HOST=adb-xxxxxxxx.azuredatabricks.net
set DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/xxxxxxxxxx
set DATABRICKS_TOKEN=dapiXXXXXXXX
set DATABRICKS_CATALOG=supply_chain_dwh
set DATABRICKS_SCHEMA=warehouse
```

**PowerShell:**

```powershell
$env:DATABRICKS_HOST="adb-xxxxxxxx.azuredatabricks.net"
$env:DATABRICKS_HTTP_PATH="/sql/1.0/warehouses/xxxxxxxxxx"
$env:DATABRICKS_TOKEN="dapiXXXXXXXX"
$env:DATABRICKS_CATALOG="supply_chain_dwh"
$env:DATABRICKS_SCHEMA="warehouse"
```

**macOS / Linux:**

```bash
export DATABRICKS_HOST=adb-xxxxxxxx.azuredatabricks.net
export DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/xxxxxxxxxx
export DATABRICKS_TOKEN=dapiXXXXXXXX
export DATABRICKS_CATALOG=supply_chain_dwh
export DATABRICKS_SCHEMA=warehouse
```

Profile target is defined in `dbt/profiles.yml` (`outputs.databricks`). See also `profiles.yml.example`.

## 5. Build the project

From the `dbt/` directory:

```bash
dbt deps --profiles-dir .
dbt debug --profiles-dir . --target databricks
dbt build --profiles-dir . --target databricks
```

Windows (if `dbt` is not on PATH), same pattern as local DuckDB:

```bat
python -c "import sys; from dbt.cli.main import cli; sys.argv=['dbt','deps','--profiles-dir','.']; cli()"
python -c "import sys; from dbt.cli.main import cli; sys.argv=['dbt','debug','--profiles-dir','.','--target','databricks']; cli()"
python -c "import sys; from dbt.cli.main import cli; sys.argv=['dbt','build','--profiles-dir','.','--target','databricks']; cli()"
```

## 6. What gets created

| Layer | Unity Catalog location (default) |
|-------|----------------------------------|
| Seeds / staging views | `supply_chain_dwh.staging.*` |
| Dimensions & facts | `supply_chain_dwh.warehouse.*` |
| KPI marts | `supply_chain_dwh.analytics.*` |

Example validation queries in Databricks SQL:

```sql
SELECT * FROM supply_chain_dwh.analytics.mart_supplier_performance;
SELECT * FROM supply_chain_dwh.analytics.mart_otif_by_carrier;
SELECT * FROM supply_chain_dwh.analytics.mart_order_fill_rate;
SELECT warehouse_name, sum(inventory_value) AS inv_value
FROM supply_chain_dwh.analytics.mart_inventory_position
GROUP BY warehouse_name
ORDER BY inv_value DESC;
```

## 7. Optional: load seeds from cloud storage later

For demos, **dbt seeds** (CSV in repo) are enough. For production:

1. Land files in a Unity Catalog Volume or cloud path (`abfss://`, `s3://`, `gs://`)
2. Create external / managed bronze tables
3. Point staging models at `source()` tables instead of `ref('seed')`

## 8. Presentation talking points

- Same star schema as the DuckDB prototype — Databricks is the **scale / governance** target
- Unity Catalog for access control and lineage
- SQL Warehouse for BI tools (Power BI, Tableau, Databricks dashboards)
- dbt tests run in CI against Databricks for trustable marts

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `DATABRICKS_HOST` / token errors | Host without `https://`; token not expired; warehouse running |
| Permission denied | Grant `USE CATALOG`, `CREATE SCHEMA`, `CREATE TABLE` on the catalog |
| Schema names like `warehouse_staging` | Project uses custom `generate_schema_name` so schemas stay `staging` / `warehouse` / `analytics` |
| Python 3.13 adapter issues | Use Python 3.11 or 3.12 for `dbt-databricks` |
| `dbt debug` fails SSL/proxy | Corporate proxy / firewall must allow workspace HTTPS |

## Security

- Prefer env vars or a secret store; do **not** commit tokens
- Rotate PATs regularly; prefer OAuth / service principals for shared jobs
