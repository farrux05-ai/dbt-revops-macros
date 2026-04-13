{#
  days_in_stage

  Returns the number of calendar days a deal has spent in a given stage.
  If the deal is still in the stage (exited_at is null), uses as_of_date
  as the effective exit point so the calculation stays current.

  Null entered_at or as_of_date returns null rather than producing a
  misleading result.  Negative values (caused by backdated data) are
  floored to 0.

  Note: uses datediff('day', ...) syntax which is compatible with
  Snowflake, Redshift, and Databricks.  BigQuery users should replace
  datediff with date_diff(end, start, DAY).

  Arguments:
    entered_at   -- date or timestamp when the deal entered the stage
    exited_at    -- date or timestamp when the deal exited the stage,
                    null if the deal is still in this stage
    as_of_date   -- evaluation date, typically current_date

  Returns:
    integer >= 0  -- calendar days spent in the stage
    null          -- if entered_at or as_of_date is null
#}
{% macro days_in_stage(entered_at, exited_at, as_of_date) %}

case
    when {{ entered_at }} is null then null
    when {{ as_of_date }} is null then null
    else greatest(
        0,
        datediff(
            'day',
            cast({{ entered_at }} as date),
            cast(coalesce({{ exited_at }}, {{ as_of_date }}) as date)
        )
    )
end

{% endmacro %}


{#
  classify_deal_age_tier

  Classifies a deal into a standardised pipeline age tier based on how
  many days it has been sitting in its current stage.  Used in pipeline
  hygiene reports, sales manager dashboards, and deal-risk monitoring.

  Default thresholds:
    Fresh     0  – 13 days   deal is moving normally
    Aging    14  – 29 days   deal is slowing, may need a nudge
    Stale    30  – 59 days   deal has stalled, requires active attention
    Critical 60+ days        deal is at high risk, escalation warranted

  Arguments:
    days_in_stage  -- integer number of days in the current stage,
                      typically the output of days_in_stage(...)

  Returns:
    'Fresh'     -- deal is progressing at a healthy pace
    'Aging'     -- deal is beginning to slow down
    'Stale'     -- deal has not advanced in a concerning amount of time
    'Critical'  -- deal is severely stalled and at risk
    null        -- if days_in_stage is null or negative
#}
{% macro classify_deal_age_tier(days_in_stage) %}

case
    when {{ days_in_stage }} is null  then null
    when {{ days_in_stage }} < 0      then null
    when {{ days_in_stage }} < 14     then 'Fresh'
    when {{ days_in_stage }} < 30     then 'Aging'
    when {{ days_in_stage }} < 60     then 'Stale'
    else 'Critical'
end

{% endmacro %}


{#
  is_pipeline_field_complete

  Returns a boolean indicating whether a deal has all the minimum required
  fields populated for reliable pipeline reporting and forecasting.

  Situation:
    Sales operations teams run pipeline hygiene reviews before forecast calls
    and board meetings. Deals missing critical fields like owner, close date,
    amount, or stage produce unreliable pipeline totals and conversion metrics.
    This check is rebuilt from scratch in every pipeline monitoring model with
    slightly different rules about what counts as empty or missing.

  Arguments:
    owner       -- deal owner field (string)
    close_date  -- expected close date (date)
    amount      -- deal value (numeric)
    stage       -- current deal stage (string)

  Returns:
    true   -- all four fields are present and non-empty
    false  -- any required field is null or owner is an empty string

  Rules:
    - all four inputs must be non-null to return true
    - owner with only whitespace is treated as missing (trim check)
    - zero is a valid amount — only null fails the check
    - future close dates are allowed, only null fails
    - stage null returns false regardless of other fields

  Edge cases:
    - owner = ''         -> false  (empty string treated as missing)
    - owner = '   '      -> false  (whitespace-only treated as missing)
    - amount = 0         -> true   (zero is a valid deal amount)
    - close_date past    -> true   (historical dates are allowed)
    - all null           -> false

  Example usage:
    select
        deal_id,
        owner,
        close_date,
        amount,
        stage,
        {{ revops_macros.is_pipeline_field_complete(
            'owner',
            'close_date',
            'amount',
            'stage'
        ) }} as is_field_complete
    from {{ ref('stg_hubspot_deals') }}
#}

{% macro is_pipeline_field_complete(owner, close_date, amount, stage) %}

case
    when {{ close_date }} is null                          then false
    when {{ amount }}     is null                          then false
    when {{ stage }}      is null                          then false
    when {{ owner }}      is null                          then false
    when trim(cast({{ owner }} as varchar)) = ''           then false
    else true
end

{% endmacro %}
