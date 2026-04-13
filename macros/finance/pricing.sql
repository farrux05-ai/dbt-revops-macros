{#
  safe_discount_rate

  Computes the discount rate applied to a deal or line item as a decimal
  between 0 and 1.

  Formula: (list_price - actual_price) / list_price

  Situation:
    Sales and finance teams track discount depth for deal desk reviews,
    price integrity reporting, and margin analysis. The raw calculation
    looks trivial but fails silently in practice when list prices are
    null or zero, or when actual prices exceed list due to manual data
    entry errors.

  Arguments:
    list_price    -- the standard or catalogue price before any discount (numeric)
    actual_price  -- the price actually charged to the customer (numeric)

  Returns:
    numeric  -- discount rate as a decimal, e.g. 0.25 means 25% discount
                rounded to 4 decimal places
    0        -- if actual_price is greater than or equal to list_price
                (no discount applied, negative discounts are not meaningful)
    null     -- if list_price is null or zero (cannot compute a rate)
    null     -- if actual_price is null

  Edge cases:
    - list_price null or zero  -> null  (division would error or be meaningless)
    - actual_price null        -> null
    - actual >= list           -> 0     (treat as no discount, not a negative rate)
    - both zero                -> null  (list_price zero guard fires first)

  Example usage:
    select
        opportunity_id,
        list_price,
        actual_price,
        {{ revops_macros.safe_discount_rate('list_price', 'actual_price') }}
            as discount_rate
    from {{ ref('stg_opportunities') }}
#}

{% macro safe_discount_rate(list_price, actual_price) %}

case
    when {{ list_price }}   is null then null
    when {{ actual_price }} is null then null
    when {{ list_price }}   = 0     then null
    when {{ actual_price }} >= {{ list_price }} then 0
    else round(
        (1.0 * ({{ list_price }} - {{ actual_price }})) / {{ list_price }},
        4
    )
end

{% endmacro %}
