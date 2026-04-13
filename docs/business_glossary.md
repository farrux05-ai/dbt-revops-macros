# Business Glossary

## Purpose

This glossary defines the core business terms used in the `dbt_revops_macros` package.

The goal is to ensure that macros are built on clear and consistent RevOps definitions. These definitions should guide:
- macro behavior
- naming conventions
- documentation
- test design
- future package scope decisions

This glossary is intentionally practical. It focuses on terms that are repeatedly used in B2B SaaS RevOps analytics and that are likely to be standardized in reusable `dbt` macros.

---

# 1. CRM and Pipeline Terms

## Open Pipeline

### Definition
Deals or opportunities that are still active in the sales process and have not yet reached a final closed outcome.

### Typical interpretation
A deal is usually considered part of open pipeline if it is:
- not `closed won`
- not `closed lost`

### Notes
This definition may vary slightly by company, especially when there are:
- paused stages
- duplicate cleanup stages
- legal review stages
- procurement stages

The package should make the default interpretation explicit and easy to override later if needed.

---

## Closed Won

### Definition
A deal or opportunity that has successfully converted into a won sale.

### Typical interpretation
A `closed won` deal represents pipeline that resulted in a successful commercial outcome.

### Notes
In some businesses, a won deal may still require downstream checks such as:
- signed contract
- invoice creation
- subscription activation
- payment confirmation

For this package, `closed won` should mean the CRM sales process marks the deal as won, unless otherwise documented.

---

## Closed Lost

### Definition
A deal or opportunity that has exited the pipeline without a successful sale.

### Typical interpretation
A `closed lost` deal is no longer active pipeline and did not convert to booked business.

### Notes
Some organizations distinguish between:
- truly lost deals
- disqualified deals
- duplicate opportunities
- canceled opportunities

The package should start with a simple default and allow future extension if needed.

---

## Pipeline Stage Group

### Definition
A standardized business grouping of raw CRM stages into broader reporting categories.

### Example groups
- Prospecting
- Qualification
- Proposal
- Closed Won
- Closed Lost
- Other

### Why it matters
Raw CRM stages are often too granular, inconsistent, or unstable for reporting. Stage groups provide a stable semantic layer for funnel and pipeline analysis.

---

## Lifecycle Stage

### Definition
A business-level classification representing where an entity is in its go-to-market or customer journey.

### Typical examples
- lead
- marketing qualified lead
- sales qualified lead
- opportunity
- customer
- evangelist

### Notes
Lifecycle stage names often depend on the CRM configuration. The package should separate source-specific labels from normalized business meaning.

---

# 2. Revenue Terms

## MRR

### Definition
Monthly Recurring Revenue.

### Typical interpretation
The normalized recurring revenue amount associated with a customer, account, or subscription for a monthly period.

### Notes
MRR should usually exclude:
- one-time fees
- implementation fees
- non-recurring services
- taxes

However, companies define MRR differently. Package macros should document assumptions clearly.

---

## ARR

### Definition
Annual Recurring Revenue.

### Typical interpretation
Recurring revenue annualized from a monthly or contract-based recurring value.

### Common relationship
`ARR = MRR * 12` in simple models, though some businesses calculate ARR directly from contract terms.

---

## Revenue Movement

### Definition
A categorical interpretation of the change in recurring revenue between two points in time.

### Common movement types
- new
- expansion
- contraction
- churn
- retained
- reactivation

### Why it matters
Revenue movement classification is central to SaaS growth analysis, retention analysis, and board-level reporting.

---

## New Revenue

### Definition
Recurring revenue associated with a customer or account that previously had no recurring revenue and is now generating recurring revenue.

### Typical rule
Previous recurring revenue is `0`, current recurring revenue is greater than `0`.

### Important caution
In some businesses, `new` must be distinguished from `reactivation`. If a customer had revenue in the past, churned, and later returned, that may be classified as reactivation rather than new.

---

## Expansion

### Definition
An increase in recurring revenue for an existing customer or account that was already active.

### Typical rule
Previous recurring revenue is greater than `0`, and current recurring revenue is greater than previous recurring revenue.

### Examples
- seat increase
- plan upgrade
- add-on purchase
- price increase

---

## Contraction

### Definition
A decrease in recurring revenue for an existing customer or account that remains active.

### Typical rule
Previous recurring revenue is greater than `0`, current recurring revenue is greater than `0`, and current recurring revenue is lower than previous recurring revenue.

### Examples
- seat reduction
- downgrade
- discount increase
- partial product removal

---

## Churn

### Definition
Recurring revenue that goes from active to zero.

### Typical rule
Previous recurring revenue is greater than `0`, and current recurring revenue is `0`.

### Important caution
Churn can be defined at different levels:
- account churn
- subscription churn
- product churn
- logo churn
- revenue churn

This package should document the grain at which churn logic is applied.

---

## Retained Revenue

### Definition
Recurring revenue that remains unchanged between two periods for an active customer or account.

### Typical rule
Previous recurring revenue is greater than `0`, and current recurring revenue equals previous recurring revenue.

### Notes
Some businesses may ignore very small differences caused by rounding or FX. If needed, tolerance-based logic can be added later.

---

## Reactivation

### Definition
Recurring revenue from a customer or account that was previously churned or inactive and later became active again.

### Typical interpretation
Current recurring revenue is greater than `0`, but the entity is not truly new because it had recurring revenue at an earlier point in history.

### Notes
This usually requires historical context beyond just one previous period.

---

# 3. Customer and Subscription Terms

## Active Customer

### Definition
A customer considered currently active based on one or more business rules, usually tied to recurring revenue or subscription activity.

### Common interpretations
A customer may be considered active if:
- they have active recurring revenue
- they have an active subscription or contract
- they have not churned as of the reporting date

### Important note
The exact definition depends on business policy and model grain. Package documentation should always clarify the rule used.

---

## Churned Customer

### Definition
A customer who was previously active but is no longer active under the selected business definition.

### Common interpretation
A customer whose recurring revenue or active subscription status has ended.

---

## Reactivated Customer

### Definition
A churned or inactive customer who later returns to active status.

### Why it matters
Reactivated customers should often be measured separately from brand new customers.

---

## Active Subscription

### Definition
A subscription or contract that is considered in force on a given date or during a given period.

### Typical interpretation
A subscription is active if:
- the start date has begun, and
- the end date has not passed, or no end date exists

### Important note
Boundary logic matters:
- is the end date inclusive?
- does cancellation override end date?
- what happens when there is a future cancellation date?

These rules must be explicit in package macros.

---

## Effective End Date

### Definition
The date used as the true final active date for a subscription after considering raw contract end dates and cancellation behavior.

### Why it matters
A subscription may have:
- a scheduled end date
- a cancellation date
- a termination date
- a billing end date

The package should define which date controls active status.

---

# 4. Quality and Governance Terms

## Unmapped Stage

### Definition
A raw CRM stage value that is not covered by the package's standard stage mapping logic.

### Why it matters
Unmapped stage values can silently break reporting consistency and should be monitored or tested explicitly.

---

## Duplicate Grain

### Definition
Multiple records existing for the same intended analytical grain.

### Example
More than one record for the same:
- account and month
- subscription and snapshot date
- opportunity and reporting date

### Why it matters
Duplicate grain often leads to overcounting, incorrect revenue reporting, and unreliable metrics.

---

## Overlapping Active Subscriptions

### Definition
Multiple subscriptions for the same customer or account that appear active during the same time period in a way that violates business expectations.

### Why it matters
This can inflate active customer counts, MRR, and retention metrics unless the overlap is intentional and modeled correctly.

---

## Required Pipeline Fields

### Definition
A set of fields expected to be populated for valid pipeline reporting.

### Common examples
- deal owner
- stage
- close date
- amount
- created date

### Notes
This may vary by company, but the package can support common validation patterns.

---

# 5. Modeling Concepts Used in the Package

## Grain

### Definition
The level of detail represented by one row in a model.

### Why it matters
Business logic depends heavily on grain. For example:
- account-month MRR logic
- subscription-day activity logic
- opportunity-level pipeline logic

Package macros should clearly document the grain assumptions they expect.

---

## Snapshot Date / As-Of Date

### Definition
The date at which a business state is evaluated.

### Examples
- whether a subscription is active on a date
- whether a customer is active as of month end
- whether a deal is open as of a reporting date

### Why it matters
Many RevOps metrics are state-based and need a consistent date reference.

---

## Business Semantic Layer

### Definition
The layer of analytics logic that translates raw system values into consistent business meaning.

### Examples
- raw CRM stage -> standard pipeline stage group
- recurring revenue change -> movement category
- contract dates -> active / inactive status

### Why it matters
This package is intended to provide reusable semantic building blocks for that layer.

---

# 6. Glossary Rules for Future Development

Use this glossary as a decision tool when building new macros.

## Add a macro when
- the term or logic is repeated across multiple models
- the business meaning is clear enough to document
- standardizing it improves consistency

## Do not add a macro when
- the logic is highly company-specific
- the definition is unstable or politically unclear
- the logic belongs in a final reporting model rather than a reusable semantic layer

---

# 7. Future Expansion Notes

These terms may later need more precise definitions depending on package growth:
- logo churn
- gross revenue retention
- net revenue retention
- bookings
- committed pipeline
- forecast category
- expansion source
- downgrade reason
- churn reason

They should only be formalized once there is clear repeated demand for them.

---

# 8. Final Working Principle

This glossary should remain the source of truth for package semantics.

If a proposed macro cannot be explained clearly using glossary terms, it is probably not ready to be added to the package yet.
