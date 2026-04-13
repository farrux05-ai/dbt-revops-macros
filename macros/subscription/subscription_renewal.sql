{#
  Domain: Subscription / Renewal
  File:   subscription_renewal.sql

  Macros:
    - effective_end_date(contract_end_date, cancelled_at)
    - is_renewal(previous_end_date, current_start_date, tolerance_days)
#}


{#
  effective_end_date

  Returns a single authoritative end date for a subscription by taking
  the earlier of the scheduled contract end date and the cancellation date.

  Cancellation is always treated as final. If a cancellation date exists
  and is earlier than the contract end date, it becomes the effective end.

  Arguments:
    contract_end_date  -- the scheduled end date from the contract term
    cancelled_at       -- the date a cancellation was processed, if any

  Returns:
    date  -- the earlier of the two dates when both are present
    date  -- the one non-null date when only one is present
    null  -- when both inputs are null (open-ended subscription)

  Edge cases:
    - both null           -> null (open-ended, no known end boundary)
    - only end date       -> contract_end_date is used as-is
    - only cancelled_at   -> cancelled_at is used as-is
    - cancellation after  -> contract_end_date still wins (earlier of the two)
#}

{% macro effective_end_date(contract_end_date, cancelled_at) %}

case
    when {{ contract_end_date }} is null and {{ cancelled_at }} is null then null
    when {{ contract_end_date }} is null then cast({{ cancelled_at }} as date)
    when {{ cancelled_at }} is null then cast({{ contract_end_date }} as date)
    else least(
        cast({{ contract_end_date }} as date),
        cast({{ cancelled_at }} as date)
    )
end

{% endmacro %}


{#
  is_renewal

  Returns a boolean indicating whether a subscription is a renewal of
  a previous one, based on the gap between the previous subscription's
  end date and the current subscription's start date.

  A subscription is a renewal when the gap between previous_end_date and
  current_start_date is within the allowed tolerance window.

  This handles:
    - exact date continuations   (gap = 0 days)
    - billing delay gaps         (gap = 1-5 days, common in practice)
    - grace period renewals      (gap up to tolerance_days)
    - overlapping subscriptions  (negative gap, treated as renewal)

  Arguments:
    previous_end_date    -- end date of the most recent prior subscription
                           for the same customer or account
    current_start_date   -- start date of the subscription being evaluated
    tolerance_days       -- max gap in days still considered a renewal
                           (default: 30)

  Returns:
    true   -- gap between previous end and current start is within tolerance
    false  -- gap exceeds tolerance, or no prior subscription exists
    null   -- current_start_date is null

  Edge cases:
    - previous_end_date null     -> false (no prior subscription, not a renewal)
    - current_start_date null    -> null
    - negative gap (overlap)     -> true (treated as renewal by default)
    - gap exactly at tolerance   -> true (boundary is inclusive)

  Note:
    Uses datediff('day', ...) syntax. Compatible with Snowflake, Redshift,
    and Databricks. BigQuery users should use date_diff(current, previous, DAY).
#}

{% macro is_renewal(previous_end_date, current_start_date, tolerance_days=30) %}

case
    when {{ current_start_date }} is null then null
    when {{ previous_end_date }} is null then false
    when datediff(
        'day',
        cast({{ previous_end_date }} as date),
        cast({{ current_start_date }} as date)
    ) <= {{ tolerance_days }} then true
    else false
end

{% endmacro %}


{#
  classify_renewal_proximity

  Classifies how soon an upcoming renewal is based on the number of days
  between the evaluation date and the renewal date.

  Used in CS dashboards, renewal risk queues, QBR scheduling, and
  account prioritisation workflows.

  Arguments:
    renewal_date  -- the contract renewal or end date
    as_of_date    -- the evaluation date, typically current_date

  Returns:
    'Overdue'       -- renewal_date is in the past
    'Imminent'      -- fewer than 30 days until renewal
    'Upcoming'      -- 30 to 89 days until renewal
    'Planning'      -- 90 to 179 days until renewal
    'Long Horizon'  -- 180 or more days until renewal
    null            -- if renewal_date or as_of_date is null

  Edge cases:
    - renewal exactly today         -> 'Imminent' (0 days, not overdue)
    - renewal_date null             -> null
    - as_of_date null               -> null

  Note:
    Uses datediff('day', ...) syntax. Compatible with Snowflake, Redshift,
    and Databricks. BigQuery users should use date_diff(renewal, as_of, DAY).
#}

{% macro classify_renewal_proximity(renewal_date, as_of_date) %}

case
    when {{ renewal_date }} is null                                         then null
    when {{ as_of_date }} is null                                           then null
    when cast({{ renewal_date }} as date) < cast({{ as_of_date }} as date)  then 'Overdue'
    when datediff(
        'day',
        cast({{ as_of_date }} as date),
        cast({{ renewal_date }} as date)
    ) < 30                                                                  then 'Imminent'
    when datediff(
        'day',
        cast({{ as_of_date }} as date),
        cast({{ renewal_date }} as date)
    ) < 90                                                                  then 'Upcoming'
    when datediff(
        'day',
        cast({{ as_of_date }} as date),
        cast({{ renewal_date }} as date)
    ) < 180                                                                 then 'Planning'
    else                                                                         'Long Horizon'
end

{% endmacro %}
