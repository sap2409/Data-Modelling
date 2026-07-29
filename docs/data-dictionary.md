# Data dictionary

## Dimensions

### dim_date
| Column | Type | Description |
|--------|------|-------------|
| date_key | INTEGER | Surrogate / smart key `YYYYMMDD` |
| full_date | DATE | Calendar date |
| day_of_week | SMALLINT | ISO day (1=Mon … 7=Sun) |
| week_of_year / month_* / quarter_* / year_number | — | Calendar attributes |
| is_weekend / is_month_end | BOOLEAN | Flags |
| fiscal_year / fiscal_quarter | SMALLINT | Defaults to calendar; adjust for fiscal calendar |

### dim_product
| Column | Description |
|--------|-------------|
| product_key | Surrogate PK |
| product_id / sku | Natural identifiers |
| category / subcategory / brand | Hierarchy & brand |
| unit_of_measure | EA, L, KG, … |
| unit_cost / unit_price | Standard cost & list price |

### dim_supplier
Supplier master: type, geography, payment terms, standard lead time, preferred flag.

### dim_customer
Customer master: segment, geography, sales channel.

### dim_warehouse
Site master: DC / plant / store / 3PL, capacity, timezone.

### dim_carrier
Transportation provider: mode (road/air/ocean/rail/parcel), service level.

### dim_status
Generic status codes scoped by `status_domain` (`purchase_order`, `sales_order`, `shipment`).

---

## Facts

### fact_purchase_order_line
| Measure | Additive | Notes |
|---------|----------|-------|
| ordered_qty / received_qty / cancelled_qty | Yes | Quantities |
| unit_cost | Semi | Prefer weighted averages |
| ordered_amount / received_amount | Yes | qty × unit_cost |

### fact_inventory_snapshot
| Measure | Notes |
|---------|-------|
| on_hand_qty / reserved_qty / available_qty | Position metrics |
| in_transit_qty / on_order_qty | Pipeline |
| inventory_value | on_hand × unit cost at snapshot |
| days_of_supply | Optional; often computed |

### fact_inventory_movement
| Measure | Notes |
|---------|-------|
| quantity | Signed (+ receipt / − issue) |
| movement_value | quantity × unit_cost |

### fact_sales_order_line
| Measure | Notes |
|---------|-------|
| ordered_qty / shipped_qty / cancelled_qty | Demand & fulfillment |
| ordered_amount / shipped_amount | Revenue-side |

### fact_shipment
| Measure / flag | Notes |
|----------------|-------|
| package_count / total_weight_kg / freight_cost | Logistics cost & volume |
| is_on_time / is_in_full / is_otif | Delivery performance flags |

---

## Staging mirrors

Staging tables (`stg_*`) hold source-aligned columns (business keys as strings/dates). See `sql/ddl/03_staging.sql`.
