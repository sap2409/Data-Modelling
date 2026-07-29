{% macro get_date_spine(start_date, end_date) %}
{# Portable date spine: DuckDB, Postgres, Databricks/Spark #}
{% if target.type == 'duckdb' %}
    select cast(unnest(generate_series(
        cast('{{ start_date }}' as date),
        cast('{{ end_date }}' as date),
        interval 1 day
    )) as date) as full_date
{% elif target.type in ['databricks', 'spark'] %}
    select explode(
        sequence(
            to_date('{{ start_date }}'),
            to_date('{{ end_date }}'),
            interval 1 day
        )
    ) as full_date
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
{% elif target.type in ['databricks', 'spark'] %}
    cast(date_format(cast({{ date_expr }} as date), 'yyyyMMdd') as int)
{% else %}
    cast(to_char({{ date_expr }}, 'YYYYMMDD') as integer)
{% endif %}
{% endmacro %}

{% macro date_part_dow(date_expr) %}
{# ISO day of week: 1=Monday .. 7=Sunday #}
{% if target.type == 'duckdb' %}
    cast(extract(isodow from cast({{ date_expr }} as date)) as integer)
{% elif target.type in ['databricks', 'spark'] %}
    {# Spark weekday(): Mon=0 .. Sun=6 #}
    cast(weekday(cast({{ date_expr }} as date)) + 1 as int)
{% else %}
    cast(extract(isodow from {{ date_expr }}) as integer)
{% endif %}
{% endmacro %}

{% macro is_month_end_expr(date_expr) %}
{% if target.type in ['databricks', 'spark'] %}
    cast({{ date_expr }} as date) = last_day(cast({{ date_expr }} as date))
{% elif target.type == 'duckdb' %}
    cast({{ date_expr }} as date) = cast(date_trunc('month', {{ date_expr }}) + interval '1 month' - interval '1 day' as date)
{% else %}
    cast({{ date_expr }} as date) = cast(date_trunc('month', {{ date_expr }}) + interval '1 month' - interval '1 day' as date)
{% endif %}
{% endmacro %}
