{% macro classify_mrr_movement(previous_mrr, current_mrr) %}
    case
        when coalesce({{ previous_mrr }}, 0) = 0 and coalesce({{ current_mrr }}, 0) > 0 then 'new'
        when coalesce({{ previous_mrr }}, 0) > 0 and coalesce({{ current_mrr }}, 0) > coalesce({{ previous_mrr }}, 0) then 'expansion'
        when coalesce({{ previous_mrr }}, 0) > 0
            and coalesce({{ current_mrr }}, 0) > 0
            and coalesce({{ current_mrr }}, 0) < coalesce({{ previous_mrr }}, 0) then 'contraction'
        when coalesce({{ previous_mrr }}, 0) > 0 and coalesce({{ current_mrr }}, 0) = 0 then 'churn'
        when coalesce({{ previous_mrr }}, 0) > 0 and coalesce({{ current_mrr }}, 0) = coalesce({{ previous_mrr }}, 0) then 'retained'
        else 'inactive'
    end
{% endmacro %}

{% macro classify_revenue_movement(previous_mrr, current_mrr) %}
    {{ classify_mrr_movement(previous_mrr, current_mrr) }}
{% endmacro %}
