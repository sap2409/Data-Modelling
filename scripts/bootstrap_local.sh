#!/usr/bin/env bash
# Bootstrap local PostgreSQL DWH from repo root.
# Requires: psql, createdb (or DATABASE_URL pointing at an empty DB)

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DB_NAME="${DB_NAME:-supply_chain_dwh}"

if [[ -n "${DATABASE_URL:-}" ]]; then
  PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1)
else
  createdb "$DB_NAME" 2>/dev/null || true
  PSQL=(psql -d "$DB_NAME" -v ON_ERROR_STOP=1)
fi

echo "==> DDL"
"${PSQL[@]}" -f sql/ddl/00_schemas.sql
"${PSQL[@]}" -f sql/ddl/01_dimensions.sql
"${PSQL[@]}" -f sql/ddl/02_facts.sql
"${PSQL[@]}" -f sql/ddl/03_staging.sql

echo "==> Sample data + transforms"
"${PSQL[@]}" -f sql/etl/01_load_sample_data.sql
"${PSQL[@]}" -f sql/etl/02_load_dimensions.sql
"${PSQL[@]}" -f sql/etl/03_load_facts.sql

echo "==> Done. Try: ${PSQL[*]} -f sql/analytics/kpi_queries.sql"
