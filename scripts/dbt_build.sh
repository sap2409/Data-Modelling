#!/usr/bin/env bash
# Run dbt build for the supply chain DWH (DuckDB by default).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/dbt"
export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v dbt >/dev/null 2>&1; then
  echo "dbt not found. Install with: pip install 'dbt-duckdb>=1.8'"
  exit 1
fi

TARGET="${1:-duckdb}"
dbt deps --profiles-dir .
dbt build --profiles-dir . --target "$TARGET"
echo "Done. DuckDB file (if target=duckdb): $ROOT/dbt/data/supply_chain_dwh.duckdb"
