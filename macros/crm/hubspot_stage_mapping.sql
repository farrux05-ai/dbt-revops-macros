{% macro map_hubspot_deal_stage_to_standard_group(stage_column) %}

case
    when {{ stage_column }} in ('appointmentscheduled', 'qualifiedtobuy') then 'Prospecting'
    when {{ stage_column }} in ('presentationscheduled', 'decisionmakerboughtin') then 'Qualification'
    when {{ stage_column }} in ('contractsent', 'negotiations') then 'Proposal'
    when {{ stage_column }} in ('closedwon') then 'Closed Won'
    when {{ stage_column }} in ('closedlost') then 'Closed Lost'
    else 'Other'
end

{% endmacro %}

{% macro is_open_pipeline(stage_column) %}

case
    when {{ stage_column }} in (
        'appointmentscheduled',
        'qualifiedtobuy',
        'presentationscheduled',
        'decisionmakerboughtin',
        'contractsent',
        'negotiations'
    ) then true
    else false
end

{% endmacro %}

{% macro is_closed_won(stage_column) %}

case
    when {{ stage_column }} = 'closedwon' then true
    else false
end

{% endmacro %}

{% macro is_closed_lost(stage_column) %}

case
    when {{ stage_column }} = 'closedlost' then true
    else false
end

{% endmacro %}

{% macro get_deal_stages(stage_column) %}

{{ map_hubspot_deal_stage_to_standard_group(stage_column) }}

{% endmacro %}
