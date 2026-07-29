{% macro get_date_spine(start_date, end_date) %}
{# Portable date spine for DuckDB and Postgres #}
{% if target.type == 'duckdb' %}
    select cast(unnest(generate_series(
        cast('{{ start_date }}' as date),
        cast('{{ end_date }}' as date),
        interval 1 day
    )) as date) as full_date
{% else %}
    select cast(d as date) as full_date
    from generate_series(
        date '{{ start_date }}',
        date '{{ end_date }}',
        interval '1 day'
    ) as g(d)
{% endif %}
{% endmacro %}

{% macro to_date_key(date_expr) %}
{# Integer YYYYMMDD from a date expression #}
{% if target.type == 'duckdb' %}
    cast(strftime(cast({{ date_expr }} as date), '%Y%m%d') as integer)
{% else %}
    cast(to_char({{ date_expr }}, 'YYYYMMDD') as integer)
{% endif %}
{% endmacro %}

{% macro date_part_dow(date_expr) %}
{# ISO day of week: 1=Monday .. 7=Sunday #}
{% if target.type == 'duckdb' %}
    cast(extract(isodow from cast({{ date_expr }} as date)) as integer)
{% else %}
    cast(extract(isodow from {{ date_expr }}) as integer)
{% endif %}
{% endmacro %}
