# RevOps Macros v1 Backlog

## Purpose

This document defines the **v1 implementation backlog** for the `dbt_revops_macros` package.

It translates the product plan into a practical build checklist by defining:

- which macros belong in v1
- why each macro matters
- expected inputs and outputs
- assumptions and edge cases
- implementation order
- documentation requirements
- quality expectations

This document should be used as the working execution guide for the first implementation phase.

---

# 1. v1 Release Goal

The goal of v1 is to ship a small but valuable set of reusable macros that solve high-frequency B2B SaaS RevOps problems without overengineering the package.

## v1 should achieve the following

- centralize repeated CRM stage logic
- standardize core MRR movement classification
- introduce the first reusable subscription activity macro
- establish documentation and quality standards for all future macros

## v1 should not try to achieve the following

- complete lifecycle modeling
- broad quality test coverage
- advanced subscription modeling
- ARR and NRR frameworks
- forecasting or attribution logic
- vendor-agnostic universal abstractions

---

# 2. v1 Scope Summary

## Included in v1

### CRM
- `map_hubspot_deal_stage_to_standard_group(stage_column)`
- `is_open_pipeline(stage_column)`
- `is_closed_won(stage_column)`
- `is_closed_lost(stage_column)`

### Revenue
- `classify_mrr_movement(previous_mrr, current_mrr)`

### Subscription
- `is_active_on_date(start_date, end_date, as_of_date)`

## Explicitly deferred after v1

- `classify_arr_movement(...)`
- `effective_end_date(...)`
- `is_active_in_period(...)`
- `classify_customer_lifecycle(...)`
- pipeline hygiene checks
- custom data quality tests
- reactivation-specific revenue logic
- tolerance-based movement logic

---

# 3. Prioritization Logic

The v1 backlog is prioritized using four criteria:

## 3.1 Reusability
Will this logic appear across multiple models or projects?

## 3.2 Business importance
Does this logic directly affect important RevOps reporting?

## 3.3 Stability
Is the logic stable enough to standardize now?

## 3.4 Simplicity
Can this be implemented clearly without introducing too much complexity?

---

# 4. v1 Macro Backlog

## P0 — Core Required Macros

These are the highest-priority items and should define the v1 release.

---

## 4.1 `map_hubspot_deal_stage_to_standard_group(stage_column)`

### Domain
CRM normalization

### Priority
P0

### Why it belongs in v1
HubSpot deal stages are often too granular and too inconsistent for direct reporting. Standard stage grouping is one of the most repeated pieces of logic in RevOps analytics.

### Business purpose
Translate raw HubSpot deal stages into stable reporting groups for funnel and pipeline analysis.

### Expected inputs
- `stage_column`: SQL expression or column name representing the raw HubSpot deal stage

### Expected output
A SQL `CASE` expression returning a standardized stage group such as:

- `Prospecting`
- `Qualification`
- `Proposal`
- `Closed Won`
- `Closed Lost`
- `Other`

### Initial rule assumptions
Default mapping for current v1:

- `appointmentscheduled` -> `Prospecting`
- `qualifiedtobuy` -> `Prospecting`
- `presentationscheduled` -> `Qualification`
- `decisionmakerboughtin` -> `Qualification`
- `contractsent` -> `Proposal`
- `negotiations` -> `Proposal`
- `closedwon` -> `Closed Won`
- `closedlost` -> `Closed Lost`
- everything else -> `Other`

### Edge cases to consider
- unknown stage values
- null stage values
- future new HubSpot stages
- stage spelling changes
- historical stage rename issues

### v1 handling decision
- unknown or unsupported values should return `Other`
- null values should also return `Other`

### Documentation requirements
Document:
- supported stage names
- fallback behavior
- warning that mappings are currently HubSpot-specific
- note that `Other` should be monitored in downstream reporting

### Quality notes
This macro is foundational and should be treated as the base mapping used by the other CRM macros.

---

## 4.2 `is_open_pipeline(stage_column)`

### Domain
CRM normalization

### Priority
P0

### Why it belongs in v1
Open pipeline logic is one of the most common and repeated business rules across funnel and pipeline reporting.

### Business purpose
Return a boolean expression that identifies whether a deal is still active in the sales process.

### Expected inputs
- `stage_column`: SQL expression or column name for raw HubSpot deal stage

### Expected output
Boolean SQL expression:
- `true` if stage is considered open pipeline
- `false` otherwise

### Initial rule assumptions
Open pipeline includes:
- `appointmentscheduled`
- `qualifiedtobuy`
- `presentationscheduled`
- `decisionmakerboughtin`
- `contractsent`
- `negotiations`

Closed pipeline excludes:
- `closedwon`
- `closedlost`

### Edge cases to consider
- null values
- unknown stage names
- paused stages
- admin-only stages
- duplicate cleanup stages

### v1 handling decision
- unknown stages -> `false`
- null stages -> `false`

### Documentation requirements
Document that:
- v1 logic is HubSpot-oriented
- open pipeline is defined strictly as non-won and non-lost stages listed in the macro
- unsupported stages default to `false`

### Quality notes
This macro should stay simple in v1. Avoid adding optional arguments or dynamic configuration now.

---

## 4.3 `is_closed_won(stage_column)`

### Domain
CRM normalization

### Priority
P0

### Why it belongs in v1
Closed-won logic is small but reused frequently in sales reporting, bookings logic, and pipeline conversion reporting.

### Business purpose
Return a boolean expression identifying whether a deal is marked as won.

### Expected inputs
- `stage_column`: SQL expression or column name representing raw deal stage

### Expected output
Boolean SQL expression

### Initial rule assumptions
- `closedwon` -> `true`
- all other values -> `false`

### Edge cases to consider
- null values
- nonstandard won-stage names
- historical renamed won stages

### v1 handling decision
- null -> `false`
- nonstandard values -> `false`

### Documentation requirements
Clearly state that this macro currently reflects a specific raw HubSpot stage value and may need expansion in future versions.

---

## 4.4 `is_closed_lost(stage_column)`

### Domain
CRM normalization

### Priority
P0

### Why it belongs in v1
Closed-lost logic is another frequent building block for conversion and pipeline reporting.

### Business purpose
Return a boolean expression identifying whether a deal is marked as lost.

### Expected inputs
- `stage_column`: SQL expression or column name representing raw deal stage

### Expected output
Boolean SQL expression

### Initial rule assumptions
- `closedlost` -> `true`
- all other values -> `false`

### Edge cases to consider
- null values
- disqualified stages
- duplicate or canceled deal stages
- historical stage naming differences

### v1 handling decision
- null -> `false`
- nonstandard values -> `false`

### Documentation requirements
Document that v1 only supports the direct raw stage value and does not yet distinguish lost vs disqualified vs duplicate.

---

## 4.5 `classify_mrr_movement(previous_mrr, current_mrr)`

### Domain
Revenue movement

### Priority
P0

### Why it belongs in v1
MRR movement classification is one of the highest-value semantic building blocks in SaaS analytics.

### Business purpose
Classify the change between previous and current MRR into a standard movement category.

### Expected inputs
- `previous_mrr`: SQL expression or column name for previous period MRR
- `current_mrr`: SQL expression or column name for current period MRR

### Expected output
A categorical SQL expression returning one of:

- `new`
- `expansion`
- `contraction`
- `churn`
- `retained`
- `inactive`

### Initial rule assumptions
Base v1 logic:

- previous = 0 and current > 0 -> `new`
- previous > 0 and current > previous -> `expansion`
- previous > 0 and current > 0 and current < previous -> `contraction`
- previous > 0 and current = 0 -> `churn`
- previous > 0 and current = previous -> `retained`
- otherwise -> `inactive`

### v1 null handling
For v1, treat null as zero using `coalesce`.

### Edge cases to consider
- null previous MRR
- null current MRR
- both values null
- negative values
- tiny rounding differences
- reactivation vs new
- credit/refund scenarios
- invalid grain causing false movement

### v1 handling decision
- null values are treated as zero
- reactivation is not split from new in v1
- tolerance handling is deferred
- negative values are not specially classified in v1
- unsupported scenarios fall into current rule behavior

### Documentation requirements
Must document:
- exact movement rules
- null handling behavior
- the fact that reactivation is not yet modeled separately
- the need to use this macro at a clearly defined grain
- that `inactive` is a fallback state, not necessarily a business event

### Quality notes
This macro is business-critical. It should be reviewed carefully before expanding to ARR or reactivation logic.

---

## 4.6 `is_active_on_date(start_date, end_date, as_of_date)`

### Domain
Subscription activity logic

### Priority
P0

### Why it belongs in v1
Subscription activity is one of the most repeated pieces of logic in SaaS analytics, especially when building customer state or revenue snapshot models.

### Business purpose
Return a boolean expression that determines whether a subscription or contract is active on a given date.

### Expected inputs
- `start_date`: SQL expression or column name representing subscription start
- `end_date`: SQL expression or column name representing subscription end
- `as_of_date`: SQL expression or column name representing the evaluation date

### Expected output
Boolean SQL expression:
- `true` if active on the given date
- `false` otherwise

### Initial rule assumptions
A subscription is active if:
- `start_date <= as_of_date`
- and either `end_date >= as_of_date` or `end_date is null`

### Boundary decision for v1
Use inclusive boundaries:
- starts on the start date
- remains active through the end date

### Edge cases to consider
- null `start_date`
- null `end_date`
- null `as_of_date`
- end date before start date
- cancellation logic not represented in end date
- future-dated start
- open-ended subscriptions

### v1 handling decision
- null `start_date` -> `false`
- null `as_of_date` -> `false`
- null `end_date` means open-ended
- invalid date ranges are not specially classified in v1

### Documentation requirements
Document:
- inclusive boundary behavior
- null behavior
- that cancellation logic is not yet modeled separately
- that this macro assumes `end_date` reflects the usable active end boundary

### Quality notes
This should remain a simple and explicit macro in v1. More advanced date handling can come later.

---

# 5. P1 Backlog — Next After v1

These are good candidates for the next implementation phase, but they should not block v1.

---

## 5.1 `effective_end_date(end_date, cancelled_at)`

### Reason deferred
Useful, but requires clearer business rules about contract termination vs cancellation timing.

---

## 5.2 `is_active_in_period(start_date, end_date, period_start, period_end)`

### Reason deferred
Important for period analytics, but more complexity than needed for first release.

---

## 5.3 `classify_arr_movement(previous_arr, current_arr)`

### Reason deferred
High reuse, but MRR should be stabilized first.

---

## 5.4 `classify_customer_lifecycle(...)`

### Reason deferred
Lifecycle classification needs a stronger shared definition before implementation.

---

## 5.5 Pipeline hygiene macros

Examples:
- `is_stale_deal(...)`
- `is_past_due_close_date(...)`
- `has_required_pipeline_fields(...)`

### Reason deferred
Useful but secondary compared to the core semantic layer.

---

## 5.6 Custom quality tests

Examples:
- unmapped stage detection
- duplicate account-period grain
- overlapping active subscriptions

### Reason deferred
Important for package maturity, but best added after core logic is stable.

---

# 6. Implementation Order

The recommended build order for v1 is below.

## Step 1 — CRM foundation
Implement in this order:
1. `map_hubspot_deal_stage_to_standard_group`
2. `is_open_pipeline`
3. `is_closed_won`
4. `is_closed_lost`

### Why first
These macros are tightly related and easy to validate together.

---

## Step 2 — Revenue foundation
Implement:
5. `classify_mrr_movement`

### Why second
This is high-value logic, but deserves focused review and clear documentation.

---

## Step 3 — Subscription foundation
Implement:
6. `is_active_on_date`

### Why third
This introduces the first subscription semantic building block without too much complexity.

---

## Step 4 — Documentation pass
After all v1 macros are in place:
- update README examples
- add per-macro usage examples
- align glossary references
- document assumptions and edge cases

---

## Step 5 — Basic validation pass
Before calling v1 complete:
- review macro naming consistency
- review null handling consistency
- review fallback behavior
- verify that macro outputs match documented definitions

---

# 7. Implementation Checklist by Macro

Use this checklist for every v1 macro.

## Required checklist
- [ ] macro name finalized
- [ ] business purpose defined
- [ ] inputs documented
- [ ] output documented
- [ ] null handling documented
- [ ] edge cases reviewed
- [ ] example usage written
- [ ] fallback behavior defined
- [ ] README or docs updated if needed

---

# 8. Documentation Backlog for v1

The following documentation tasks should be completed alongside implementation.

## 8.1 README alignment
Ensure README examples reflect actual macro names and usage.

## 8.2 Glossary alignment
Ensure glossary definitions match the final implemented logic.

## 8.3 Macro examples
Each v1 macro should have at least one example of expected use in a SQL model.

## 8.4 Limitations section
Document what v1 intentionally does not solve, especially:
- reactivation
- ARR classification
- period activity logic
- cancellation-specific logic
- advanced pipeline governance
- quality tests

---

# 9. Quality Expectations for v1

v1 does not need to be comprehensive, but it should be disciplined.

## Minimum quality bar
- macro naming is clear
- file organization is consistent
- logic matches documentation
- null handling is intentional
- fallback categories are explicit
- assumptions are visible
- macros solve real repeated pain

## What would count as poor v1 quality
- undocumented behavior
- inconsistent naming
- hidden edge-case assumptions
- macros that mix multiple responsibilities
- unclear source-specific vs business-specific logic

---

# 10. Open Questions to Resolve During Implementation

These questions do not block v1, but should be noted.

## CRM questions
- Should `Other` remain the default fallback?
- Should unknown stages later be testable through custom validation?

## Revenue questions
- When should reactivation be split from `new`?
- Should very small differences be ignored with a tolerance?
- Should negative MRR values be rejected or classified specially?

## Subscription questions
- Should cancellation dates override end dates in future versions?
- Should end date always be inclusive?
- How should invalid date ranges be treated in later quality checks?

---

# 11. Definition of Done for v1

v1 is considered complete when:

- all six P0 macros are implemented
- macro names match package conventions
- documentation exists for each macro
- README reflects actual available macros
- glossary terms align with implemented logic
- assumptions and limitations are written down
- the package remains focused and not overextended

---

# 12. Final Working Rule

If a proposed macro does not clearly satisfy all of the following, it should probably not enter v1:

- solves a repeated RevOps problem
- fits the package scope
- can be explained in plain business language
- has stable enough logic to standardize
- improves consistency across models

This backlog should be treated as the execution contract for the first package release.
