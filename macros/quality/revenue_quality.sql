{#
  Domain: Revenue Quality
  File:   revenue_quality.sql

  Macros:
    - classify_mrr_sanity(mrr_value, subscription_status)
#}


{#
  classify_mrr_sanity

  Classifies an MRR record into a sanity category to surface common
  revenue data anomalies that would otherwise distort metrics silently.

  Situation:
    When revenue models are built, records can appear that are technically
    valid SQL but represent business anomalies — negative MRR from credits,
    zero MRR on an active subscription, or positive MRR on a churned account.
    Without a central classification, each model handles these differently
    and anomalies go undetected until they distort board-level metrics.

  Arguments:
    mrr_value            -- the MRR amount for the record (numeric)
    subscription_status  -- the current status of the subscription (string)
                           recognised active statuses:   'active', 'trialing'
                           recognised inactive statuses: 'churned', 'cancelled',
                                                         'canceled', 'inactive',
                                                         'expired'

  Returns:
    'Valid'             -- mrr > 0 and subscription is active
    'Zero on Active'    -- mrr = 0 but subscription is marked active
    'Negative'          -- mrr < 0 (credit, refund, or data error)
    'Active on Churned' -- mrr > 0 but subscription is churned or cancelled
    'Unknown'           -- status value is not in the recognised set
    null                -- if mrr_value or subscription_status is null

  Edge cases:
    - null mrr_value           -> null
    - null subscription_status -> null
    - mrr < 0 regardless of status -> always 'Negative'
    - unrecognised status value    -> 'Unknown'

  Example usage:
    select
        account_id,
        subscription_id,
        mrr,
        subscription_status,
        {{ revops_macros.classify_mrr_sanity('mrr', 'subscription_status') }}
            as mrr_sanity
    from {{ ref('int_account_mrr_by_month') }}

  Notes:
    Use this macro in monitoring models or dbt exposures to catch anomalies
    before they reach dashboards. Records classified as anything other than
    'Valid' should be investigated before inclusion in revenue metrics.
#}

{% macro classify_mrr_sanity(mrr_value, subscription_status) %}

case
    when {{ mrr_value }}           is null then null
    when {{ subscription_status }} is null then null
    when {{ mrr_value }} < 0
        then 'Negative'
    when {{ mrr_value }} = 0
        and lower({{ subscription_status }}) in ('active', 'trialing')
        then 'Zero on Active'
    when {{ mrr_value }} > 0
        and lower({{ subscription_status }}) in (
            'churned', 'cancelled', 'canceled', 'inactive', 'expired'
        )
        then 'Active on Churned'
    when {{ mrr_value }} >= 0
        and lower({{ subscription_status }}) in ('active', 'trialing')
        then 'Valid'
    else 'Unknown'
end

{% endmacro %}
