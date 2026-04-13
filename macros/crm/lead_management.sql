{#
  Domain: CRM / Lead Management
  File:   lead_management.sql

  Macros:
    - classify_lead_response_time(lead_created_at, first_contact_at)
#}


{#
  classify_lead_response_time

  Classifies how quickly a lead received a first response after being
  created, based on the elapsed time between lead creation and first
  documented contact.

  Situation:
    SDR and demand gen teams track lead response time as a core SLA
    metric. Research consistently shows that response speed has a
    significant impact on conversion rates. These SLA buckets appear
    in SDR performance dashboards, inbound lead routing analysis,
    marketing SLA compliance models, and pipeline health reviews.

  Problem:
    Response time buckets are rebuilt in every SDR ops or demand gen
    model with slightly different boundaries, different null handling,
    and different reference timestamps. Centralising this logic ensures
    consistent SLA reporting across all lead models.

  Arguments:
    lead_created_at   -- timestamp when the lead was created or became
                         active in the CRM
    first_contact_at  -- timestamp of the first documented outreach or
                         contact attempt by a rep

  Returns:
    'Under 5 Minutes'   -- first contact within 5 minutes of lead creation
    '5 to 60 Minutes'   -- first contact between 5 and 60 minutes
    '1 to 24 Hours'     -- first contact between 1 hour and 24 hours
    'Over 24 Hours'     -- first contact took more than 24 hours
    'No Response'       -- no first contact timestamp exists
    null                -- if lead_created_at is null, or if
                           first_contact_at is earlier than lead_created_at

  Edge cases:
    - first_contact_at is null         -> 'No Response'
    - lead_created_at is null          -> null
    - first_contact_at < lead_created  -> null (invalid sequence, likely
                                          a data quality issue)
    - contact exactly at creation time -> 'Under 5 Minutes' (0 minutes)

  Assumptions:
    - both inputs are timestamps, not dates
    - elapsed time is measured in whole minutes
    - 1440 minutes = 24 hours boundary is used for the final bucket

  Note:
    Uses datediff('minute', ...) syntax. Compatible with Snowflake,
    Redshift, and Databricks. BigQuery users should use
    timestamp_diff(first_contact_at, lead_created_at, MINUTE).

  Example usage:
    select
        lead_id,
        created_at,
        first_contact_at,
        {{ revops_macros.classify_lead_response_time(
            'created_at',
            'first_contact_at'
        ) }} as response_time_bucket
    from {{ ref('stg_crm_leads') }}
#}

{% macro classify_lead_response_time(lead_created_at, first_contact_at) %}

case
    when {{ lead_created_at }} is null                        then null
    when {{ first_contact_at }} is null                       then 'No Response'
    when {{ first_contact_at }} < {{ lead_created_at }}       then null
    when datediff(
        'minute',
        {{ lead_created_at }},
        {{ first_contact_at }}
    ) < 5                                                     then 'Under 5 Minutes'
    when datediff(
        'minute',
        {{ lead_created_at }},
        {{ first_contact_at }}
    ) < 60                                                    then '5 to 60 Minutes'
    when datediff(
        'minute',
        {{ lead_created_at }},
        {{ first_contact_at }}
    ) < 1440                                                  then '1 to 24 Hours'
    else                                                           'Over 24 Hours'
end

{% endmacro %}


{#
  classify_mql_age

  Classifies how long a lead has been sitting in MQL status without being
  worked by sales, based on the number of days since the lead reached MQL.

  Situation:
    Marketing teams track MQL age to detect sales capacity problems,
    routing failures, and SLA violations. Aging leads in MQL status
    are a direct signal that inbound demand is not being actioned.
    These classifications appear in lead management dashboards, marketing
    SLA reports, and demand gen reviews.

  Problem:
    MQL age classifications follow the same pattern as deal aging — they
    are rebuilt in every lead management model with inconsistent thresholds
    and inconsistent null handling. Teams end up with different definitions
    of "stale" across marketing, sales ops, and RevOps reports.

  Arguments:
    mql_date    -- the date the lead reached MQL status (date)
    as_of_date  -- the evaluation date, typically current_date (date)

  Returns:
    'Fresh'     -- 0 to 2 days in MQL, recently qualified
    'Aging'     -- 3 to 7 days in MQL, needs attention soon
    'Stale'     -- 8 to 14 days in MQL, SLA likely breached
    'Critical'  -- more than 14 days in MQL, escalation warranted
    null        -- if mql_date or as_of_date is null, or if the
                   calculated days is negative (data quality issue)

  Default thresholds:
    Fresh     0 – 2 days
    Aging     3 – 7 days
    Stale     8 – 14 days
    Critical  15+ days

  Edge cases:
    - mql_date null            -> null
    - as_of_date null          -> null
    - negative days (mql_date
      in the future)           -> null (signals a data quality issue)
    - mql_date = as_of_date    -> 'Fresh' (0 days)

  Note:
    Uses datediff('day', ...) syntax. Compatible with Snowflake, Redshift,
    and Databricks. BigQuery users should use date_diff(as_of, mql, DAY).

  Example usage:
    select
        lead_id,
        mql_date,
        {{ revops_macros.classify_mql_age('mql_date', 'current_date') }}
            as mql_age_tier
    from {{ ref('stg_crm_leads') }}
    where lifecycle_stage = 'marketingqualifiedlead'
#}

{% macro classify_mql_age(mql_date, as_of_date) %}

case
    when {{ mql_date }}   is null then null
    when {{ as_of_date }} is null then null
    when datediff(
        'day',
        cast({{ mql_date }} as date),
        cast({{ as_of_date }} as date)
    ) < 0                         then null
    when datediff(
        'day',
        cast({{ mql_date }} as date),
        cast({{ as_of_date }} as date)
    ) <= 2                        then 'Fresh'
    when datediff(
        'day',
        cast({{ mql_date }} as date),
        cast({{ as_of_date }} as date)
    ) <= 7                        then 'Aging'
    when datediff(
        'day',
        cast({{ mql_date }} as date),
        cast({{ as_of_date }} as date)
    ) <= 14                       then 'Stale'
    else                               'Critical'
end

{% endmacro %}
