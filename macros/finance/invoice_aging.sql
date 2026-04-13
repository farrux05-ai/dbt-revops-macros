{#
  classify_invoice_aging_bucket

  Classifies an invoice into a standard accounts receivable aging bucket
  based on how many days past due it is.

  This is one of the most repeated CASE WHEN patterns in B2B SaaS finance
  analytics. Centralizing it ensures consistent bucket definitions across
  AR aging models, collections dashboards, and month-end close exports.

  Arguments:
    days_overdue  integer number of days past the invoice due date
                  positive = overdue, zero or negative = current / not yet due

  Returns:
    'Current'     not yet overdue (0 or fewer days past due date)
    '1-30 Days'   1 to 30 days overdue
    '31-60 Days'  31 to 60 days overdue
    '61-90 Days'  61 to 90 days overdue
    '90+ Days'    more than 90 days overdue
    null          if days_overdue is null

  Assumptions:
    - days_overdue is calculated as: current_date - invoice_due_date
    - the due date is the reference point, not the invoice created date
    - zero or negative values mean the invoice is not yet overdue

  Example usage:
    select
        invoice_id,
        due_date,
        datediff('day', due_date, current_date) as days_overdue,
        {{ revops_macros.classify_invoice_aging_bucket(
            'datediff(\'day\', due_date, current_date)'
        ) }} as aging_bucket
    from {{ ref('stg_invoices') }}
    where payment_status != 'paid'
#}

{% macro classify_invoice_aging_bucket(days_overdue) %}

case
    when {{ days_overdue }} is null then null
    when {{ days_overdue }} <= 0   then 'Current'
    when {{ days_overdue }} <= 30  then '1-30 Days'
    when {{ days_overdue }} <= 60  then '31-60 Days'
    when {{ days_overdue }} <= 90  then '61-90 Days'
    else                                '90+ Days'
end

{% endmacro %}
