{#
  assign_customer_cohort_month

  Returns the first day of the month in which a customer first became active
  or paid, providing a consistent cohort anchor for retention and revenue
  analysis.

  Cohort-based analysis (retention curves, NRR waterfalls, LTV, payback
  period) all depend on every model assigning the same cohort month for the
  same customer. Without a shared macro, analysts use different expressions
  (date_trunc, format strings, manual truncation) which produces silent
  mismatches in cohort membership across reports.

  Arguments:
    first_active_date  -- the date the customer first became active or paid
                          (date or timestamp column / expression)

  Returns:
    date  -- first day of the cohort month, e.g. 2024-03-15 -> 2024-03-01
    null  -- if first_active_date is null

  Assumptions:
    - always returns a date type, never a formatted string
    - always returns the first calendar day of the month
    - the definition of "first active" is determined by the calling model;
      this macro only standardises the truncation step

  Example usage:
    select
        account_id,
        first_paid_at,
        {{ revops_macros.assign_customer_cohort_month('first_paid_at') }}
            as cohort_month
    from {{ ref('int_accounts') }}

  Notes:
    Uses date_trunc('month', ...) which is supported in Snowflake, Redshift,
    BigQuery, DuckDB, and Postgres.
#}

{% macro assign_customer_cohort_month(first_active_date) %}

case
    when {{ first_active_date }} is null then null
    else date_trunc('month', cast({{ first_active_date }} as date))
end

{% endmacro %}
