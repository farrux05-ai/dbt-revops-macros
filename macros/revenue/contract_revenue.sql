{#
  normalize_contract_to_monthly_mrr

  Converts a total contract value into a monthly recurring revenue (MRR) amount
  by dividing the contract value by the number of calendar months in the term.

  Assumption: end_date is exclusive — the first day after the contract ends.
  Example: a 12-month contract from 2024-01-01 to 2025-01-01 produces contract_value / 12.
  If your contracts store an inclusive end date (e.g. 2024-12-31), add one day before calling.

  Inputs:
    contract_value  -- total value of the contract (numeric)
    start_date      -- first day the contract is active (date)
    end_date        -- first day after the contract ends, exclusive (date)

  Returns:
    numeric  -- monthly MRR amount rounded to 2 decimal places
    null     -- if any input is null, if end_date <= start_date,
                or if the term resolves to zero months
#}

{% macro normalize_contract_to_monthly_mrr(contract_value, start_date, end_date) %}

case
    when {{ contract_value }} is null then null
    when {{ start_date }} is null then null
    when {{ end_date }} is null then null
    when {{ end_date }} <= {{ start_date }} then null
    else round(
        (1.0 * {{ contract_value }}) / nullif(
            (
                (extract(year  from {{ end_date }}) - extract(year  from {{ start_date }})) * 12
                + (extract(month from {{ end_date }}) - extract(month from {{ start_date }}))
            ),
            0
        ),
        2
    )
end

{% endmacro %}


{#
  contract_term_months

  Returns the number of calendar months in a contract term.

  Uses the same month boundary assumption as normalize_contract_to_monthly_mrr:
  end_date is exclusive — the first day after the contract ends.

  Example:
    2024-01-01 to 2025-01-01  ->  12
    2024-01-01 to 2024-04-01  ->  3
    2024-01-01 to 2024-01-01  ->  0  (same-day, zero-length contract)

  Arguments:
    start_date  -- first day the contract is active (date)
    end_date    -- first day after the contract ends, exclusive (date)

  Returns:
    integer  -- number of full calendar months in the term (>= 0)
    null     -- if either input is null

  Notes:
    - end_date <= start_date returns 0, not null, to distinguish a
      zero-length contract from missing data
    - open-ended contracts (null end_date) return null intentionally;
      use a sentinel date if you need a fallback value
    - consistent with normalize_contract_to_monthly_mrr — both macros
      should always agree on term length for the same inputs
#}

{% macro contract_term_months(start_date, end_date) %}

case
    when {{ start_date }} is null then null
    when {{ end_date }} is null then null
    when {{ end_date }} <= {{ start_date }} then 0
    else (
        (extract(year  from {{ end_date }}) - extract(year  from {{ start_date }})) * 12
        + (extract(month from {{ end_date }}) - extract(month from {{ start_date }}))
    )
end

{% endmacro %}


{#
  prorate_monthly_amount

  Returns the pro-rated portion of a monthly recurring amount for a given
  calendar month, based on the number of days the subscription was active
  within that month.

  Situation:
    Customers do not always start on the first day of the month. A customer
    who signs on the 20th of March is active for only 12 of 31 days. Some
    businesses need to recognise only the earned portion of MRR for that
    first partial month in revenue, cohort, and billing reconciliation models.

  Problem:
    Pro-ration logic is recalculated differently everywhere — some use
    days / 30, some use days_remaining / total_days, some always credit
    the full month. This creates inconsistency in first-month MRR cohorts,
    churn rate denominators, and recognised revenue models.

  Arguments:
    monthly_amount  -- the full monthly recurring amount (numeric)
    start_date      -- the date the subscription became active (date)
    month_start     -- first day of the month being evaluated (date)
    month_end       -- last day of the month being evaluated (date)

  Returns:
    numeric          -- pro-rated amount rounded to 2 decimal places
    monthly_amount   -- in full, if start_date is on or before month_start
    0                -- if start_date is after month_end (not active this month)
    null             -- if any input is null

  Formula (partial month only):
    monthly_amount * (days_active_in_month / total_days_in_month)

    where:
      days_active_in_month  = datediff(day, start_date, month_end) + 1
      total_days_in_month   = datediff(day, month_start, month_end) + 1

  Edge cases:
    - start_date = month_start   -> full amount (no pro-ration needed)
    - start_date < month_start   -> full amount
    - start_date > month_end     -> 0 (subscription not yet started this month)
    - any null input             -> null

  Note:
    Uses datediff('day', ...) syntax. Compatible with Snowflake, Redshift,
    and Databricks. BigQuery users should use date_diff(end, start, DAY).

  Example usage:
    select
        account_id,
        subscription_start_date,
        month_start,
        month_end,
        monthly_mrr,
        {{ revops_macros.prorate_monthly_amount(
            'monthly_mrr',
            'subscription_start_date',
            'month_start',
            'month_end'
        ) }} as prorated_mrr
    from {{ ref('int_subscription_month_spine') }}
#}

{% macro prorate_monthly_amount(monthly_amount, start_date, month_start, month_end) %}

case
    when {{ monthly_amount }} is null                                             then null
    when {{ start_date }}     is null                                             then null
    when {{ month_start }}    is null                                             then null
    when {{ month_end }}      is null                                             then null
    when cast({{ start_date }} as date) <= cast({{ month_start }} as date)        then {{ monthly_amount }}
    when cast({{ start_date }} as date) >  cast({{ month_end }}   as date)        then 0
    else round(
        (1.0 * {{ monthly_amount }}) * (
            (datediff('day', cast({{ start_date }}   as date), cast({{ month_end }} as date)) + 1)
            /
            nullif(
                (datediff('day', cast({{ month_start }} as date), cast({{ month_end }} as date)) + 1),
                0
            )
        ),
        2
    )
end

{% endmacro %}
