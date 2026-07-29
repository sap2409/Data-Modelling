{{
  config(
    materialized='table'
  )
}}

with spine as (
    {{ get_date_spine(var('date_spine_start'), var('date_spine_end')) }}
)

select
    {{ to_date_key('full_date') }} as date_key,
    full_date,
    {{ date_part_dow('full_date') }} as day_of_week,
    {% if target.type == 'duckdb' %}
    dayname(full_date) as day_name,
    cast(day(full_date) as integer) as day_of_month,
    cast(dayofyear(full_date) as integer) as day_of_year,
    cast(week(full_date) as integer) as week_of_year,
    cast(month(full_date) as integer) as month_number,
    monthname(full_date) as month_name,
    cast(quarter(full_date) as integer) as quarter_number,
    'Q' || cast(quarter(full_date) as varchar) as quarter_name,
    cast(year(full_date) as integer) as year_number,
    {% elif target.type in ['databricks', 'spark'] %}
    date_format(full_date, 'E') as day_name,
    cast(day(full_date) as int) as day_of_month,
    cast(dayofyear(full_date) as int) as day_of_year,
    cast(weekofyear(full_date) as int) as week_of_year,
    cast(month(full_date) as int) as month_number,
    date_format(full_date, 'MMM') as month_name,
    cast(quarter(full_date) as int) as quarter_number,
    concat('Q', cast(quarter(full_date) as string)) as quarter_name,
    cast(year(full_date) as int) as year_number,
    {% else %}
    to_char(full_date, 'Dy') as day_name,
    cast(extract(day from full_date) as integer) as day_of_month,
    cast(extract(doy from full_date) as integer) as day_of_year,
    cast(extract(week from full_date) as integer) as week_of_year,
    cast(extract(month from full_date) as integer) as month_number,
    to_char(full_date, 'Mon') as month_name,
    cast(extract(quarter from full_date) as integer) as quarter_number,
    'Q' || cast(extract(quarter from full_date) as varchar) as quarter_name,
    cast(extract(year from full_date) as integer) as year_number,
    {% endif %}
    {{ date_part_dow('full_date') }} in (6, 7) as is_weekend,
    {{ is_month_end_expr('full_date') }} as is_month_end,
    {% if target.type == 'duckdb' %}
    cast(year(full_date) as integer) as fiscal_year,
    cast(quarter(full_date) as integer) as fiscal_quarter
    {% elif target.type in ['databricks', 'spark'] %}
    cast(year(full_date) as int) as fiscal_year,
    cast(quarter(full_date) as int) as fiscal_quarter
    {% else %}
    cast(extract(year from full_date) as integer) as fiscal_year,
    cast(extract(quarter from full_date) as integer) as fiscal_quarter
    {% endif %}
from spine
