{% macro sf_generate__surrogate_key(columns) -%}
  {{ dbt_utils.generate_surrogate_key(columns) }}
{%- endmacro %}

{% macro sf_stage_bucket(stage_column) -%}
  case
    when {{ stage_column }} in ('Prospecting', 'Qualification','Needs Analysis', 'Value Proposition', 'Id. Decision Makers') then 'Pipeline_Early'
    when {{ stage_column }} in ('Perception Analysis', 'Proposal/Price Quote', 'Negotiation/Review') then 'Pipeline_Late'
    when {{ stage_column }} in ('Closed Won') then 'Closed_Won'
    when {{ stage_column }} in ('Closed Lost') then 'Closed_Lost'
    else 'other'
  end
{%- endmacro %}

{% macro sf_clean_text(text_column) -%}
  nullif(trim({{ text_column }}), '')
{%- endmacro %}
