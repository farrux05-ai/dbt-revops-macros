{% macro is_active_on_date(start_date, end_date, as_of_date) %}

case
    when {{ start_date }} is null then false
    when {{ as_of_date }} is null then false
    when {{ start_date }} > {{ as_of_date }} then false
    when {{ end_date }} is null then true
    when {{ end_date }} >= {{ as_of_date }} then true
    else false
end

{% endmacro %}
