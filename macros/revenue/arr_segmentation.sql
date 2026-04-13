{#
  classify_arr_band

  Classifies a customer or account into a standard ARR segment based on
  their annual recurring revenue value.

  Situation:
    Almost every B2B SaaS company segments customers by ARR for retention,
    CS capacity planning, sales segmentation, and board reporting. These
    thresholds get hard-coded into every model and drift over time when
    leadership redefines what counts as Enterprise or Mid-Market.

  Default thresholds:
    SMB:         arr < 10,000
    Mid-Market:  arr >= 10,000 and < 100,000
    Enterprise:  arr >= 100,000

  Arguments:
    arr_value  -- annual recurring revenue for the account (numeric)

  Returns:
    'SMB'         -- small and medium business tier
    'Mid-Market'  -- mid-market tier
    'Enterprise'  -- enterprise tier
    null          -- if arr_value is null

  Example usage:
    select
        account_id,
        arr,
        {{ revops_macros.classify_arr_band('arr') }} as arr_band
    from {{ ref('int_account_arr') }}

  Notes:
    Thresholds reflect commonly used defaults in B2B SaaS.
    If your company uses different segment definitions, update this macro
    once and the change will propagate to all models using it.
    Zero ARR is classified as SMB rather than returning null.
#}

{% macro classify_arr_band(arr_value) %}

case
    when {{ arr_value }} is null then null
    when {{ arr_value }} < 10000 then 'SMB'
    when {{ arr_value }} < 100000 then 'Mid-Market'
    else 'Enterprise'
end

{% endmacro %}
