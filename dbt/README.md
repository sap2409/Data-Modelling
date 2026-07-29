# dbt — Supply Chain DWH

Transformational layer for the supply chain warehouse: **seeds → staging → dimensions/facts → marts**.

## Quick start (DuckDB — no server)

From the repo root:

```bash
cd dbt
export PATH="$HOME/.local/bin:$PATH"   # if needed
pip install 'dbt-duckdb>=1.8'
dbt deps --profiles-dir .
dbt build --profiles-dir .
```

Artifacts land in `dbt/data/supply_chain_dwh.duckdb`.

## PostgreSQL

```bash
pip install dbt-postgres
export DBT_HOST=localhost DBT_USER=postgres DBT_PASSWORD=postgres DBT_DBNAME=supply_chain_dwh
dbt build --profiles-dir . --target postgres
```

Ensure the database exists first (`createdb supply_chain_dwh`).

## Project layout

```
dbt/
  seeds/                 CSV raw inputs (same as sample_data/)
  models/
    staging/             Typed / cleaned staging views
    warehouse/
      dimensions/        Conformed dims (tables)
      facts/             Additive facts (tables)
    marts/               KPI-ready marts (analytics schema)
  macros/                Date spine + portable SQL helpers
  profiles.yml           Local DuckDB + Postgres profiles
```

## Model DAG (simplified)

```text
seeds → stg_* → dim_* ─┐
                └──────► fact_* → mart_*
```

## Useful commands

| Command | Purpose |
|---------|---------|
| `dbt seed` | Load CSVs |
| `dbt run` | Build models |
| `dbt test` | Run schema tests |
| `dbt build` | seed + run + test |
| `dbt docs generate && dbt docs serve` | Lineage docs UI |

## Relationship to `sql/`

The `sql/ddl` and `sql/etl` folders are a plain-SQL reference implementation. Prefer **this dbt project** for ongoing development, testing, and documentation.
