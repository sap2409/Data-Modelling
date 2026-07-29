{# Use custom schema names as-is (staging / warehouse / analytics).
   Avoids target_schema_custom_schema concatenation on Databricks Unity Catalog. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
