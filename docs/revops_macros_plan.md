# RevOps Macros Package Plan

## Document Purpose

This document defines the product scope, design principles, priorities, and phased roadmap for the `dbt_revops_macros` package.

The goal is to build a focused, reusable macro library for **B2B SaaS Revenue Operations** use cases in `dbt`, with emphasis on:

- simplifying repeated business logic
- improving consistency across models
- reducing SQL duplication
- keeping the package practical and high quality
- avoiding overengineering

---

# 1. Product Vision

## Vision
Build a reusable `dbt` macro package that standardizes the most repeated and error-prone **RevOps business logic** for B2B SaaS analytics.

## Core value
The package should help analytics engineers and RevOps teams centralize logic that is otherwise copied across many models, such as:

- CRM stage standardization
- revenue movement classification
- subscription activity logic
- lifecycle state classification
- RevOps-oriented quality checks

## Expected outcome
Instead of rewriting the same `CASE WHEN` logic in multiple models, teams should be able to call reusable macros with clear business meaning.

---

# 2. Product Positioning

## What this package is
A **semantic macro library** for B2B SaaS RevOps analytics in `dbt`.

## What this package is not
This package is not intended to be:

- a complete RevOps warehouse framework
- a full reporting layer
- a dashboard generator
- a forecasting engine
- an attribution engine
- a compensation model
- a lead scoring framework
- a generic SQL utility collection

The package should focus on **high-reuse business logic**, not on building the full analytics stack.

---

# 3. Target Users

This package is primarily for:

- analytics engineers working in B2B SaaS
- RevOps engineers building reusable business logic in `dbt`
- teams that want more consistency across CRM, billing, and customer reporting
- projects that repeatedly deal with sales pipeline, MRR movement, lifecycle, and subscription state logic

---

# 4. Design Principles

## 4.1 Solve repeated real-world pain
A macro should only be added if it solves logic that appears repeatedly in real RevOps work.

Examples of good candidates:
- stage grouping logic
- MRR movement classification
- active subscription checks

Examples of poor candidates:
- one-off report logic
- company-specific compensation rules
- full final models wrapped as macros

## 4.2 Build semantic building blocks
Each macro should return a reusable business logic component, not a complete analytics model.

Good:
- `classify_mrr_movement(...)`
- `is_open_pipeline(...)`
- `is_active_on_date(...)`

Bad:
- `build_board_metrics_report(...)`

## 4.3 Keep definitions explicit
Every macro should have:
- a clear purpose
- defined inputs
- defined output
- documented assumptions
- null handling rules
- edge-case behavior

## 4.4 Separate source-specific logic from business logic
Keep vendor/source-specific mappings separate from general RevOps semantics.

Examples:
- HubSpot stage mapping = source-specific
- "open pipeline" = business semantic

## 4.5 Avoid premature abstraction
Do not design for speculative future use cases. Build for repeated needs that already exist.

## 4.6 Quality matters as much as usefulness
A macro package is only valuable if its outputs are understandable, maintainable, and testable.

---

# 5. Scope for v1

The first version of this package should focus on five core domains:

1. CRM normalization
2. Revenue movement classification
3. Subscription activity logic
4. Customer lifecycle classification
5. RevOps quality checks

This is a focused and realistic scope for a first meaningful release.

---

# 6. Real RevOps Pain Areas and Macro Opportunities

## 6.1 CRM Stage Normalization

### Why this is important
CRM stage names often differ by team, get renamed over time, or contain historical inconsistencies. This creates repeated reporting issues.

### Common real-world problems
- funnel stage groups differ across models
- open pipeline is defined inconsistently
- conversion reporting breaks when new stages are added
- lifecycle statuses are difficult to compare over time

### Why macros help
This logic is repeated, relatively stable, and easy to centralize.

### Candidate macros
- `map_hubspot_deal_stage_to_standard_group(stage_column)`
- `is_open_pipeline(stage_column)`
- `is_closed_won(stage_column)`
- `is_closed_lost(stage_column)`
- `map_lifecycle_stage(stage_column)`

### Priority
Very high

---

## 6.2 Revenue Movement Classification

### Why this is important
One of the most common B2B SaaS reporting needs is classifying changes in recurring revenue.

### Common real-world problems
- inconsistent definitions of new vs reactivation
- duplicated movement logic across MRR models
- different teams classify the same customer differently
- null and zero values are handled inconsistently
- small rounding changes create false expansion or contraction

### Why macros help
Revenue movement classification is highly reusable and business-critical.

### Candidate macros
- `classify_mrr_movement(previous_mrr, current_mrr)`
- `classify_arr_movement(previous_arr, current_arr)`
- future: `is_reactivation(...)`
- future: `is_net_expansion(...)`

### Priority
Very high

---

## 6.3 Subscription / Contract Activity Logic

### Why this is important
Subscription date logic is one of the most repeated and error-prone parts of SaaS analytics.

### Common real-world problems
- active customer counts vary across models
- contract periods are interpreted inconsistently
- cancellation logic is unclear
- null end dates are handled differently
- overlapping subscriptions create bad downstream metrics

### Why macros help
Date-based activity logic is highly reusable and much safer when centralized.

### Candidate macros
- `is_active_on_date(start_date, end_date, as_of_date)`
- `is_active_in_period(start_date, end_date, period_start, period_end)`
- `effective_end_date(end_date, cancelled_at)`

### Priority
High

---

## 6.4 Customer Lifecycle Classification

### Why this is important
Revenue, CS, and GTM teams all need consistent lifecycle categories.

### Common real-world problems
- active vs churned definitions differ by team
- reactivated customers are not consistently classified
- customer states are duplicated across models

### Why macros help
Lifecycle logic becomes much easier to reuse when standardized.

### Candidate macros
- `classify_customer_lifecycle(...)`
- `is_new_customer(...)`
- `is_reactivated_customer(...)`
- `is_churned_customer(...)`

### Priority
Medium to high

---

## 6.5 Pipeline Hygiene / Governance

### Why this is important
Sales pipeline quality often requires repeated checks across analytics models and monitoring views.

### Common real-world problems
- stale deals
- missing close dates
- missing required fields
- overdue opportunities
- weak pipeline quality standards

### Why macros help
These checks are common and benefit from standardized boolean logic.

### Candidate macros
- `is_stale_deal(last_activity_date, threshold_days)`
- `is_past_due_close_date(close_date, as_of_date)`
- `has_required_pipeline_fields(...)`
- `is_pipeline_eligible(...)`

### Priority
Medium

---

## 6.6 RevOps Data Quality / Custom Tests

### Why this is important
The package should be trustworthy, not just convenient.

### Common real-world problems
- duplicate account-month rows
- overlapping active subscriptions
- invalid revenue transitions
- unmapped CRM stages
- missing required fields for won deals

### Why this fits the package
Data quality rules are a major part of making a semantic library production-ready.

### Candidate tests / helpers
- no duplicate account-period grain
- no overlapping active primary subscriptions
- no negative MRR unless allowed
- no unmapped stage values
- required fields for closed-won deals are populated

### Priority
High, after the first core macros are stable

---

# 7. What Not to Build Yet

The following areas should not be in the first versions of the package:

- attribution modeling
- lead scoring
- health scoring
- sales forecasting
- territory planning
- commission / compensation logic
- generic KPI marts
- broad board-report generation
- highly company-specific RevOps processes

These areas are either too custom, too broad, or too unstable for a focused macro package.

---

# 8. Recommended Folder Structure

Suggested structure:

- `macros/crm/`
- `macros/revenue/`
- `macros/subscription/`
- `macros/lifecycle/`
- `macros/quality/`
- `macros/utils/` only if necessary

## Guideline
The package should be organized by business domain, not by arbitrary technical grouping.

## Important warning
Do not let `utils/` become the center of the package. The value of this package is domain-specific RevOps logic.

---

# 9. Naming Conventions

## Naming principles
- Use `map_` for mapping / normalization macros
- Use `classify_` for categorical business outcomes
- Use `is_` for boolean conditions
- Prefer clear business terms over technical shorthand

## Good examples
- `map_hubspot_deal_stage_to_standard_group`
- `classify_mrr_movement`
- `is_open_pipeline`
- `is_active_on_date`
- `classify_customer_lifecycle`

## Avoid
- vague names
- source names without business meaning
- overloaded utility-style macro names
- generic names like `process_stage` or `handle_revenue`

---

# 10. Required Business Glossary

Before expanding the package, define these terms clearly:

- open pipeline
- closed won
- closed lost
- new revenue
- expansion
- contraction
- churn
- retained
- reactivation
- active customer
- churned customer
- active subscription

Each term should have:
- a plain-language definition
- rule logic
- known assumptions
- known limitations

This glossary should guide all macro behavior.

---

# 11. MVP Roadmap

## Phase 0 — Foundation

### Goal
Define scope, vocabulary, and package standards.

### Deliverables
- package mission statement
- scope and non-scope definition
- business glossary
- naming standards
- folder structure cleanup
- initial documentation baseline

### Why this phase matters
Without this phase, the package will become inconsistent as soon as more macros are added.

---

## Phase 1 — Core CRM and Revenue Macros

### Goal
Ship the highest-value repeated logic first.

### Deliverables

#### CRM
- `map_hubspot_deal_stage_to_standard_group(stage_column)`
- `is_open_pipeline(stage_column)`
- `is_closed_won(stage_column)`
- `is_closed_lost(stage_column)`

#### Revenue
- `classify_mrr_movement(previous_mrr, current_mrr)`

### Success criteria
- key CRM logic is centralized
- open/closed logic is reusable
- MRR movement logic is standardized
- duplicated case statements start disappearing from models

---

## Phase 2 — Subscription Activity Logic

### Goal
Standardize contract and subscription timing logic.

### Deliverables
- `is_active_on_date(start_date, end_date, as_of_date)`
- `is_active_in_period(start_date, end_date, period_start, period_end)`
- `effective_end_date(end_date, cancelled_at)`

### Success criteria
- activity logic is no longer rewritten across models
- date rules are consistent across revenue and customer models

---

## Phase 3 — Lifecycle Classification

### Goal
Introduce reusable customer state semantics.

### Deliverables
- `classify_customer_lifecycle(...)`
- optional helper macros:
  - `is_new_customer(...)`
  - `is_reactivated_customer(...)`
  - `is_churned_customer(...)`

### Success criteria
- lifecycle logic becomes standardized
- customer state metrics align more easily across teams

---

## Phase 4 — Quality and Custom Tests

### Goal
Add quality controls that make the package reliable in production.

### Deliverables
- test for unmapped stages
- test for duplicate account-period rows
- test for overlapping active subscriptions
- test for invalid revenue movement scenarios
- test for missing required fields on won deals

### Success criteria
- semantic rules are validated
- package quality improves materially
- analytics users can trust outputs more confidently

---

## Phase 5 — Secondary Enhancements

### Goal
Add only high-value enhancements after the core package is stable.

### Candidate additions
- `classify_arr_movement(...)`
- more CRM mappings
- pipeline hygiene checks
- optional tolerance support for revenue movement
- more lifecycle helper macros

### Rule
Add secondary features only when they solve repeated needs, not theoretical ones.

---

# 12. Suggested v1 Macro Set

The recommended first release should be lean and useful.

## Strong v1 set
1. `map_hubspot_deal_stage_to_standard_group(stage_column)`
2. `is_open_pipeline(stage_column)`
3. `is_closed_won(stage_column)`
4. `is_closed_lost(stage_column)`
5. `classify_mrr_movement(previous_mrr, current_mrr)`
6. `is_active_on_date(start_date, end_date, as_of_date)`

## Smaller MVP option
If needed, start with only:
1. `map_hubspot_deal_stage_to_standard_group(stage_column)`
2. `is_open_pipeline(stage_column)`
3. `classify_mrr_movement(previous_mrr, current_mrr)`
4. `is_active_on_date(start_date, end_date, as_of_date)`

Both are valid, but the 6-macro version is a stronger first package release.

---

# 13. Quality Standards for Every Macro

Every macro added to this package should include the following documentation and standards.

## Minimum required metadata
- purpose
- expected inputs
- output type
- null handling
- edge-case behavior
- business assumptions
- example usage
- known limitations

## Example validation questions
- What happens if input is null?
- What happens if a stage is unknown?
- How are zero and null treated differently?
- Are date boundaries inclusive?
- Does a return value represent business state or technical state?

---

# 14. Acceptance Criteria for the Package

The package should be considered successful if it meets the following conditions:

## Product success criteria
- solves real recurring RevOps logic problems
- reduces repeated business logic in models
- remains focused and understandable
- can be reused across multiple B2B SaaS analytics projects
- does not become bloated with unrelated features

## Technical success criteria
- macros are organized by domain
- naming is consistent
- documentation is present
- key assumptions are explicit
- core logic is testable
- custom quality checks are gradually added

---

# 15. Risks and Anti-Patterns

## Risk 1 — Becoming too broad
If the package expands into every RevOps topic, it will lose focus and maintainability.

## Risk 2 — Becoming too company-specific
If logic is too tied to one sales process or one customer setup, it will not be reusable.

## Risk 3 — Undefined business semantics
If terms like churn or open pipeline are not explicitly defined, the package will create confusion.

## Risk 4 — Utility creep
If the package fills up with generic helper macros, its domain value will weaken.

## Risk 5 — No quality layer
Without tests and validation, even good semantic logic can produce bad outcomes silently.

---

# 16. Immediate Next Steps

## Recommended next actions
1. finalize this plan as the package direction
2. define the business glossary
3. clean up macro file structure and naming
4. implement the Phase 1 macro set
5. add usage examples in documentation
6. add basic quality tests after core macros are stable

---

# 17. Final Recommendation

The strongest path for this package is:

## Focus first on
- CRM normalization
- revenue movement classification
- subscription activity logic

## Then expand into
- lifecycle classification
- quality and custom tests

## Avoid for now
- attribution
- scoring
- forecasting
- compensation
- broad reporting frameworks

This approach creates a package that is:
- practical
- reusable
- high quality
- easier to maintain
- aligned with real RevOps pain points

---

# 18. Working Principle Going Forward

For every new macro proposal, use this decision rule:

## Add it if
- it solves a repeated real problem
- it appears in multiple models or projects
- it represents stable business logic
- it improves consistency
- it is easy to explain and document

## Do not add it if
- it only supports one report
- it is too custom to one company
- it belongs in a final model, not a macro
- it adds complexity without strong reuse value

---

# 19. Proposed Next Document

After this plan, the next recommended document should be:

## `revops_macros_v1_backlog.md`
This file should define for each first-release macro:
- macro name
- business purpose
- inputs
- output
- rules
- edge cases
- priority
- implementation notes

That document should become the execution checklist for the first build phase.
