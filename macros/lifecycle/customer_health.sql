{#
  classify_health_tier

  Classifies a customer account into a standard health tier based on
  a numeric health score, typically on a 0 to 100 scale.

  Used in CS dashboards, renewal risk models, churn forecasting,
  and executive health reviews.

  Default thresholds:
    Green:   70 and above  -- healthy, low churn risk
    Yellow:  40 to 69      -- at risk, needs active attention
    Red:     below 40      -- critical, high churn risk

  Arguments:
    health_score -- numeric score on a 0 to 100 scale

  Returns:
    'Green'  -- healthy account
    'Yellow' -- at-risk account
    'Red'    -- critical account
    null     -- if health_score is null

  Example:
    select
        account_id,
        health_score,
        {{ revops_macros.classify_health_tier('health_score') }} as health_tier
    from {{ ref('int_account_health_scores') }}
#}

{% macro classify_health_tier(health_score) %}

case
    when {{ health_score }} is null then null
    when {{ health_score }} >= 70 then 'Green'
    when {{ health_score }} >= 40 then 'Yellow'
    else 'Red'
end

{% endmacro %}
