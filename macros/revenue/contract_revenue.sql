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
