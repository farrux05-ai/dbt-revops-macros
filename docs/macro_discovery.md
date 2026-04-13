# RevOps Macro Discovery

## Purpose

This document catalogs **real B2B SaaS RevOps pain points** and proposes macros as targeted solutions.

The structure for every entry is:

1. **Situation** — what is happening in the real business
2. **Problem** — what goes wrong in the analytics without a standard solution
3. **Macro solution** — what macro solves it and how

This document feeds directly into the backlog and implementation phases.

The guiding rule: every macro here must solve a real repeated problem, not a theoretical one.

---

# Domain 1 — Contract and Billing

---

## 1.1 Monthly MRR from Contract Value

### Situation

Most B2B SaaS billing systems store contracts as a total contract value with a start date and an end date.

Examples:
- `$24,000` for a 12-month contract
- `$60,000` for a 24-month contract
- `$6,000` for a 3-month pilot

When revenue data lands in the warehouse, it usually arrives as a lump-sum contract record, not as a monthly MRR line.

### Problem

Every analyst has to divide the contract value by the number of months to get MRR.

This seems simple but quickly becomes inconsistent because:
- some divide by calendar months, some by contract days divided by 30
- month boundaries are handled differently
- zero-month contracts cause division by zero errors
- one-day contracts or same-day start and end produce unpredictable results
- rounding behavior differs between models

Result: the same contract produces different MRR values in different models.

### Macro solution

```
normalize_contract_to_monthly_mrr(contract_value, start_date, end_date)
```

Standardizes the calculation of monthly recurring revenue from a contract record.

Inputs:
- `contract_value`: total value of the contract
- `start_date`: contract start date
- `end_date`: contract end date

Output:
- monthly MRR amount as a numeric SQL expression

Rules:
- calculate term as calendar months between start and end
- if term is zero or null, return null rather than error
- round to two decimal places
- if contract value is null, return null

---

## 1.2 Partial Month Pro-ration

### Situation

Customers do not always start on the first day of the month.

A customer who signs on the 20th of March is active for only 12 out of 31 days in that month. Some businesses want to recognize only the portion of MRR earned in that partial month for revenue reporting, billing, or cohort accuracy.

### Problem

Pro-ration logic gets recalculated differently in every model that touches it:
- some use `days_in_period / days_in_month`
- some use `days_remaining / 30`
- some always credit the full month regardless of start date
- some round up, some round down

This creates inconsistency in:
- recognized revenue models
- first-month MRR cohorts
- churn rate denominators
- billing reconciliation

### Macro solution

```
prorate_monthly_amount(monthly_amount, start_date, month_start, month_end)
```

Returns the pro-rated portion of a monthly amount for a given month based on the number of active days.

Inputs:
- `monthly_amount`: full monthly recurring amount
- `start_date`: the date the subscription or contract became active
- `month_start`: first day of the month being evaluated
- `month_end`: last day of the month being evaluated

Output:
- pro-rated amount as a numeric SQL expression

Rules:
- if start_date is on or before month_start, return full monthly_amount
- if start_date is after month_end, return 0
- otherwise return `monthly_amount * (days_active_in_month / total_days_in_month)`
- null inputs return null

---

## 1.3 Contract Term in Months

### Situation

Sales, finance, and CS teams need to know the term length of a contract.

Examples of where this is needed:
- calculating ARR from contract value
- determining whether a deal is a monthly or annual subscription
- identifying multi-year contracts
- renewal date calculations
- segmenting customers by commitment level

### Problem

Contract term calculation looks trivial but creates repeated issues:
- `datediff` behavior varies by warehouse dialect
- the question of whether the end date is inclusive is handled inconsistently
- the difference between calendar months and billing cycles is conflated
- null end dates for open-ended contracts are unhandled

Every model that needs term length recalculates it with slightly different logic.

### Macro solution

```
contract_term_months(start_date, end_date)
```

Returns the number of full calendar months in a contract term.

Inputs:
- `start_date`: contract start date
- `end_date`: contract end date

Output:
- integer or numeric SQL expression representing the number of months

Rules:
- null start_date returns null
- null end_date means open-ended, return null
- same-day start and end returns 0
- uses inclusive start, exclusive end boundary by default
- always returns a non-negative value

---

# Domain 2 — Sales Pipeline

---

## 2.1 Days a Deal Has Spent in a Stage

### Situation

Sales managers review pipeline weekly and ask questions like:

- which deals have been stuck in "Proposal" for more than 30 days?
- how long on average does a deal spend in "Qualification" before advancing?
- which reps have the healthiest pipeline velocity?

To answer these, every pipeline model needs to know how many days a deal has been in its current or previous stage.

### Problem

The calculation looks like `current_date - stage_entered_at`, but in practice:
- deals that have already exited a stage have a null `exited_at`
- some models use `coalesce(stage_exited_at, current_date)` and some do not
- null stage entry dates for migrated historical deals are handled inconsistently
- business days vs calendar days are confused
- the result can be negative for backdated data

This logic appears in pipeline monitoring models, sales velocity models, and deal aging reports everywhere and is almost never consistent.

### Macro solution

```
days_in_stage(entered_at, exited_at, as_of_date)
```

Returns the number of calendar days a deal has spent in a stage.

Inputs:
- `entered_at`: date or timestamp when the deal entered the stage
- `exited_at`: date or timestamp when the deal exited the stage, or null if still in stage
- `as_of_date`: the evaluation date, typically current date

Output:
- integer SQL expression representing days in stage

Rules:
- if `exited_at` is null, use `as_of_date` as the effective end
- if `entered_at` is null, return null
- if the result would be negative, return 0
- always returns a non-negative integer

---

## 2.2 Deal Age Tier Classification

### Situation

Sales operations teams create pipeline aging reports to flag deals that have not progressed.

Typical tiers used in pipeline reviews:
- fresh: less than 14 days
- aging: 14 to 30 days
- stale: 30 to 60 days
- critical: more than 60 days

These tiers are used in:
- sales manager dashboards
- pipeline hygiene reports
- CRM alerting models
- weekly pipeline review exports

### Problem

The age tier thresholds get hard-coded into every single model that references them.

When leadership decides to change the "stale" threshold from 30 to 45 days:
- every model needs to be updated manually
- thresholds drift across models over time
- different dashboards show different aging categories
- the classification naming is inconsistent

### Macro solution

```
classify_deal_age_tier(days_in_stage)
```

Returns a standardized age tier label based on how long a deal has been in a stage.

Inputs:
- `days_in_stage`: integer or numeric expression for stage duration

Output:
- categorical SQL expression returning one of:
  - `Fresh`
  - `Aging`
  - `Stale`
  - `Critical`

Default tier thresholds:
- Fresh: 0 to 13 days
- Aging: 14 to 29 days
- Stale: 30 to 59 days
- Critical: 60 or more days

Rules:
- null input returns null
- negative values return null
- thresholds should be clearly documented and easy to adjust in future versions

---

## 2.3 Required Pipeline Field Completeness

### Situation

Pipeline quality reviews often involve checking whether deals have all the fields required for reliable forecasting.

Common required fields in a well-qualified deal:
- deal owner assigned
- close date populated
- deal amount populated
- next step populated
- stage set to an appropriate value

Sales operations regularly needs to flag deals that are missing critical information before pipeline review meetings.

### Problem

Field completeness checks are rebuilt from scratch in every pipeline hygiene model.

Each model applies different rules about which fields are required and what counts as empty.

Result:
- different hygiene reports produce different completeness scores
- new fields added to the completeness check have to be updated everywhere
- the logic for what constitutes "missing" differs

### Macro solution

```
is_pipeline_field_complete(owner, close_date, amount, stage)
```

Returns a boolean expression indicating whether a deal meets the minimum required field completeness for pipeline reporting.

Inputs:
- `owner`: deal owner field expression
- `close_date`: expected close date expression
- `amount`: deal amount expression
- `stage`: deal stage expression

Output:
- boolean SQL expression

Rules:
- returns true only if all four inputs are non-null
- empty strings on owner are treated as null
- zero on amount is allowed, null is not
- null close_date returns false
- future close dates are allowed

---

# Domain 3 — Accounts Receivable and Finance

---

## 3.1 Invoice Aging Bucket Classification

### Situation

Finance teams track unpaid invoices using AR aging buckets.

This is a standard accounting concept that appears in:
- cash collection reports
- bad debt risk models
- CFO dashboards
- finance-to-CS escalation workflows

The standard classification is:
- current: not yet due
- 1 to 30 days overdue
- 31 to 60 days overdue
- 61 to 90 days overdue
- over 90 days overdue

### Problem

Invoice aging buckets are one of the most repeated `CASE WHEN` blocks in finance analytics.

They appear in:
- AR aging models
- overdue invoice reports
- collections dashboards
- month-end close exports

Every time the buckets appear, they are slightly different:
- some use 0-30, some use 1-30
- some include a `current` bucket, some do not
- some use days since due date, some use days since invoice date
- the naming of buckets is inconsistent across reports

### Macro solution

```
classify_invoice_aging_bucket(days_overdue)
```

Returns a standardized aging bucket label based on how many days overdue an invoice is.

Inputs:
- `days_overdue`: integer expression representing days past the due date (positive = overdue)

Output:
- categorical SQL expression returning one of:
  - `Current`
  - `1-30 Days`
  - `31-60 Days`
  - `61-90 Days`
  - `90+ Days`

Rules:
- zero or negative days_overdue returns `Current`
- null returns null
- uses the due date as the reference point, not the invoice date

---

## 3.2 Discount Rate Classification

### Situation

Sales and finance teams track how much discount is being applied to deals.

Discount analysis is used in:
- deal desk review
- price integrity reporting
- sales margin analysis
- CFO approval thresholds

### Problem

Discount percentage is often calculated differently:
- some use `1 - (actual / list_price)`
- some use `(list_price - actual) / list_price`
- null list prices cause division by zero
- zero list prices cause division by zero
- the resulting percentage is then bucketed differently in each report

### Macro solution

```
safe_discount_rate(list_price, actual_price)
```

Returns the discount rate as a decimal between 0 and 1.

Inputs:
- `list_price`: the standard or list price
- `actual_price`: the actual price charged

Output:
- numeric SQL expression

Rules:
- if list_price is null or zero, return null
- if actual_price is null, return null
- if actual_price is greater than list_price, return 0
- result is always between 0 and 1
- formula: `(list_price - actual_price) / list_price`

---

# Domain 4 — Customer Segmentation

---

## 4.1 ARR Band / Customer Tier Classification

### Situation

Almost every B2B SaaS company segments its customers by ARR size.

Common segments:
- SMB
- Mid-Market
- Enterprise

Or more granularly:
- under $5,000
- $5,000 to $25,000
- $25,000 to $100,000
- over $100,000

These segments appear in:
- retention and churn analysis
- CS capacity planning
- sales segmentation
- board-level customer count reporting
- NRR cohorts

### Problem

ARR band thresholds are hard-coded everywhere.

When the company redefines "Enterprise" from `>$100k` to `>$75k`:
- every model using the old thresholds needs to be updated
- some models are missed
- reports start showing different customer counts for the same segment
- sales, CS, and finance see different segment membership for the same accounts

### Macro solution

```
classify_arr_band(arr_value)
```

Returns a standardized customer segment label based on ARR.

Inputs:
- `arr_value`: annual recurring revenue for the customer or account

Output:
- categorical SQL expression returning one of:
  - `SMB`
  - `Mid-Market`
  - `Enterprise`

Default thresholds:
- SMB: under $10,000
- Mid-Market: $10,000 to $99,999
- Enterprise: $100,000 and above

Rules:
- null returns null
- zero returns `SMB`
- thresholds are clearly documented and easy to override in future versions

---

## 4.2 Customer Cohort Month Assignment

### Situation

Cohort-based retention and revenue analysis is one of the most standard practices in SaaS.

Teams regularly need to assign a customer to a cohort month based on when they first became a paying customer.

This cohort month then becomes the anchor for:
- monthly retention tables
- logo retention curves
- NRR cohort waterfall charts
- LTV analysis
- payback period calculations

### Problem

Cohort assignment looks trivial — just `date_trunc('month', first_paid_date)` — but in practice it creates repeated problems:

- some models use `date_trunc`, some format to `YYYY-MM` string, some keep as date
- the definition of "first paid" varies: first invoice, first subscription start, first non-zero MRR
- customers with null first paid dates silently drop out of cohort analysis
- different analysts assign different cohort months for the same customer due to grain differences

### Macro solution

```
assign_customer_cohort_month(first_active_date)
```

Returns a standardized cohort month date for a customer.

Inputs:
- `first_active_date`: the date representing when the customer first became active or paid

Output:
- date SQL expression truncated to the first day of the month

Rules:
- null input returns null
- always returns a date type, not a string
- always returns the first day of the month
- should be used consistently across all cohort models in a project

---

# Domain 5 — Subscription and Renewal

---

## 5.1 Renewal Detection

### Situation

In subscription businesses, when a new subscription record appears, it is important to know whether it represents a brand new customer relationship or a renewal of an existing one.

This distinction matters for:
- new logo vs renewal revenue reporting
- customer lifetime value
- renewal rate calculations
- bookings classification
- ARR waterfall analysis

### Problem

Renewal detection logic is rebuilt differently in every subscription analytics model.

Common inconsistencies:
- some use exact date matching between old end date and new start date
- some allow a tolerance window of a few days for billing delays
- some consider a gap of up to 30 days still a renewal
- some require the same product to match, some do not
- the handling of null dates in previous subscriptions differs

Result: renewal vs new business numbers differ across reports and the numbers never fully reconcile.

### Macro solution

```
is_renewal(previous_end_date, current_start_date, tolerance_days)
```

Returns a boolean expression indicating whether a subscription is a renewal of a previous one.

Inputs:
- `previous_end_date`: end date of the most recent prior subscription for the same customer
- `current_start_date`: start date of the current subscription
- `tolerance_days`: number of days of gap allowed while still classifying as renewal

Output:
- boolean SQL expression

Rules:
- if previous_end_date is null, return false (no prior subscription means not a renewal)
- if current_start_date is null, return null
- returns true if `current_start_date - previous_end_date <= tolerance_days`
- returns false if the gap exceeds tolerance
- negative gaps (overlap) return true by default in v1

---

## 5.2 Effective Contract End Date

### Situation

Contract and subscription records often carry multiple date fields that could represent the true end of the relationship:

- `contract_end_date`: the scheduled end based on the original term
- `cancelled_at`: the date a cancellation request was processed
- `churned_at`: the date churn was confirmed
- `terminated_at`: an early termination date

For revenue and activity logic, the system needs to determine a single authoritative end date.

### Problem

Every model that checks whether a subscription is active makes its own choice about which date to use as the end boundary.

Some use `contract_end_date`, some coalesce cancellation dates, some prefer the earlier of two dates.

This creates:
- different active customer counts across models
- different churn timing
- different MRR snapshots
- incorrect AR aging for churned accounts

### Macro solution

```
effective_end_date(contract_end_date, cancelled_at)
```

Returns a single authoritative end date by taking the earlier of the contract end date and the cancellation date.

Inputs:
- `contract_end_date`: scheduled end of the contract
- `cancelled_at`: cancellation date if one exists

Output:
- date SQL expression

Rules:
- if both are null, return null (open-ended)
- if only one is non-null, return that one
- if both are non-null, return the earlier date
- cancellation is always treated as final regardless of contract end date

---

# Domain 6 — Customer Success

---

## 6.1 Customer Health Tier Classification

### Situation

Customer success teams assign health scores to accounts and then classify those scores into tiers for prioritization, capacity planning, and escalation workflows.

Standard tiers used across most CS platforms:
- Green: healthy
- Yellow: at risk
- Red: critical

These tiers appear in:
- CS dashboards
- renewal risk models
- QBR preparation
- CS capacity allocation
- exec-level churn risk reviews

### Problem

Health tier thresholds are embedded in every CS model and BI tool configuration separately.

When CS leadership adjusts the threshold for what counts as "at risk":
- CS dashboards show different counts than the data model
- the data model in staging uses one threshold and the reporting model uses another
- historical tier assignments in the warehouse become inconsistent over time

### Macro solution

```
classify_health_tier(health_score)
```

Returns a standardized health tier label based on a numeric health score.

Inputs:
- `health_score`: numeric score typically on a 0 to 100 scale

Output:
- categorical SQL expression returning one of:
  - `Green`
  - `Yellow`
  - `Red`

Default thresholds:
- Green: 70 and above
- Yellow: 40 to 69
- Red: below 40

Rules:
- null input returns null
- score below 0 returns `Red`
- score above 100 still classified normally
- thresholds are clearly documented

---

## 6.2 Days Until Renewal

### Situation

CS teams track how close each account is to its renewal date to prioritize outreach, QBRs, and expansion conversations.

A common classification:
- renewal imminent: less than 30 days
- renewal upcoming: 30 to 90 days
- renewal planning: 90 to 180 days
- long horizon: more than 180 days

### Problem

Days until renewal is calculated differently across models:
- some calculate from the contract end date, some from a renewal processing deadline
- some include weekends, some try to approximate business days
- the classification buckets differ between CS tools and the warehouse

### Macro solution

```
classify_renewal_proximity(renewal_date, as_of_date)
```

Returns a categorical classification of how soon a renewal is approaching.

Inputs:
- `renewal_date`: the contract renewal or end date
- `as_of_date`: the evaluation date

Output:
- categorical SQL expression returning one of:
  - `Imminent`
  - `Upcoming`
  - `Planning`
  - `Long Horizon`
  - `Overdue`

Rules:
- if renewal_date < as_of_date, return `Overdue`
- if days until renewal < 30, return `Imminent`
- if 30 to 89 days, return `Upcoming`
- if 90 to 179 days, return `Planning`
- if 180 or more days, return `Long Horizon`
- null renewal_date returns null

---

# Domain 7 — Lead and Demand Generation

---

## 7.1 Lead Response Time Classification

### Situation

Sales development teams track how quickly inbound leads receive a first response after being created.

This is one of the most studied SaaS sales metrics. Research consistently shows that response time significantly impacts conversion rates.

Common SLA tiers:
- under 5 minutes
- 5 to 60 minutes
- 1 to 24 hours
- over 24 hours

These tiers appear in:
- SDR performance dashboards
- inbound lead routing analysis
- marketing SLA compliance models
- revenue operations pipeline health reviews

### Problem

Lead response time buckets are rebuilt in every SDR ops or demand gen model.

Problems:
- bucket boundaries differ by team
- some calculate from lead created, some from MQL timestamp
- weekend and off-hours handling is inconsistent
- null first contact timestamps are handled differently

### Macro solution

```
classify_lead_response_time(lead_created_at, first_contact_at)
```

Returns a bucket label based on how quickly a lead received a first response.

Inputs:
- `lead_created_at`: timestamp when the lead was created or became active
- `first_contact_at`: timestamp of first documented outreach or contact

Output:
- categorical SQL expression returning one of:
  - `Under 5 Minutes`
  - `5 to 60 Minutes`
  - `1 to 24 Hours`
  - `Over 24 Hours`
  - `No Response`

Rules:
- if `first_contact_at` is null, return `No Response`
- if `lead_created_at` is null, return null
- if `first_contact_at` is before `lead_created_at`, return null
- based on elapsed minutes between the two timestamps

---

## 7.2 MQL Age Classification

### Situation

Marketing teams track how long leads have been sitting in MQL status without being worked by sales.

Aging leads in MQL are a sign of:
- sales capacity problems
- routing failures
- poor lead quality
- SLA violations

### Problem

MQL age classifications follow the same pattern as deal aging — they are repeated in every lead management model with inconsistent thresholds and inconsistent null handling.

### Macro solution

```
classify_mql_age(mql_date, as_of_date)
```

Returns a classification of how long a lead has been in MQL status.

Inputs:
- `mql_date`: the date the lead reached MQL status
- `as_of_date`: the evaluation date

Output:
- categorical SQL expression returning one of:
  - `Fresh`
  - `Aging`
  - `Stale`
  - `Critical`

Default thresholds:
- Fresh: 0 to 2 days
- Aging: 3 to 7 days
- Stale: 8 to 14 days
- Critical: more than 14 days

Rules:
- null mql_date returns null
- negative days return null
- as_of_date null returns null

---

# Domain 8 — Revenue Quality

---

## 8.1 MRR Sanity Classification

### Situation

When revenue models are built, it is common to encounter records that produce MRR values that are technically valid SQL but represent business anomalies.

Examples:
- negative MRR from credits or refunds
- zero MRR on an active subscription
- extremely high MRR that looks like a data quality issue
- MRR on a churned account

These anomalies often go undetected until they distort metrics.

### Problem

Each model that handles MRR creates its own inline checks for these scenarios.

The result is:
- inconsistent anomaly handling
- silent anomalies that affect metrics
- no central place to extend the validation logic

### Macro solution

```
classify_mrr_sanity(mrr_value, subscription_status)
```

Returns a sanity classification that flags unusual MRR values.

Inputs:
- `mrr_value`: the MRR value for the record
- `subscription_status`: active / inactive / cancelled / churned status

Output:
- categorical SQL expression returning one of:
  - `Valid`
  - `Zero on Active`
  - `Negative`
  - `Active on Churned`

Rules:
- if mrr_value > 0 and subscription is active: `Valid`
- if mrr_value = 0 and subscription is active: `Zero on Active`
- if mrr_value < 0: `Negative`
- if mrr_value > 0 and subscription is churned or cancelled: `Active on Churned`
- null mrr_value returns null

---

# Summary Table

| Macro | Domain | Why It Matters |
|---|---|---|
| `normalize_contract_to_monthly_mrr` | Billing | Contract value to MRR is recalculated inconsistently everywhere |
| `prorate_monthly_amount` | Billing | Partial month revenue handled differently in every model |
| `contract_term_months` | Billing | Term length logic varies by warehouse and team |
| `days_in_stage` | Pipeline | Null exit date is always handled differently |
| `classify_deal_age_tier` | Pipeline | Stale deal thresholds are hard-coded in every model |
| `is_pipeline_field_complete` | Pipeline | Hygiene checks are rebuilt in every monitoring model |
| `classify_invoice_aging_bucket` | Finance | AR aging buckets are the most repeated CASE WHEN in finance |
| `safe_discount_rate` | Finance | Division by zero and null handling is always inconsistent |
| `classify_arr_band` | Segmentation | Tier thresholds drift across every model and dashboard |
| `assign_customer_cohort_month` | Retention | Cohort date assignment is inconsistent across cohort models |
| `is_renewal` | Subscription | Renewal vs new logic uses different tolerance windows everywhere |
| `effective_end_date` | Subscription | Multiple competing end date fields produce different active counts |
| `classify_health_tier` | CS | Health score thresholds live in CS tools and models separately |
| `classify_renewal_proximity` | CS | Renewal proximity buckets differ between CS tools and warehouse |
| `classify_lead_response_time` | Demand Gen | Lead SLA buckets rebuilt in every SDR ops model |
| `classify_mql_age` | Demand Gen | MQL aging thresholds are inconsistent across lead models |
| `classify_mrr_sanity` | Revenue Quality | MRR anomalies go undetected without a central classification |

---

# Prioritization for Next Build Phase

## Tier 1 — Build next
These macros have the highest reuse, solve clear pain, and are straightforward to implement.

- `normalize_contract_to_monthly_mrr`
- `classify_invoice_aging_bucket`
- `classify_arr_band`
- `classify_deal_age_tier`
- `days_in_stage`
- `classify_health_tier`
- `effective_end_date`
- `is_renewal`

## Tier 2 — Build after Tier 1 is stable
- `contract_term_months`
- `assign_customer_cohort_month`
- `classify_renewal_proximity`
- `classify_lead_response_time`
- `safe_discount_rate`
- `classify_mrr_sanity`

## Tier 3 — Revisit later
- `prorate_monthly_amount`
- `classify_mql_age`
- `is_pipeline_field_complete`

---

# Guiding Rule

A macro enters the build backlog only when the following are true:

- the same logic appears in at least two different models or teams
- the business definition is stable enough to document
- the logic produces meaningful inconsistency when duplicated
- it can be explained clearly in plain RevOps language
- it returns a semantic building block, not a final model
