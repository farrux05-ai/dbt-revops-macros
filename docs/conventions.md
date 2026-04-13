# Package Conventions

## Purpose

This document defines the conventions for building and maintaining the `dbt_revops_macros` package.

The goals of these conventions are to:

- keep the package focused on real RevOps use cases
- make macro behavior easy to understand
- reduce duplication and ambiguity
- improve maintainability as the package grows
- protect the package from overengineering

These conventions should apply to all new macros, documentation, and future package changes.

---

# 1. Package Design Principles

## 1.1 Solve repeated business problems

A macro should only be added if it solves a logic problem that appears repeatedly in B2B SaaS RevOps analytics.

A good macro:

- removes repeated SQL from multiple models
- standardizes business logic used in many places
- makes semantic definitions more consistent

A bad macro:

- only supports one report
- only solves one temporary use case
- hides model-specific logic inside a macro
- adds abstraction without meaningful reuse

## 1.2 Prefer semantic building blocks

This package should provide reusable business logic components, not complete final models.

Good examples:

- stage normalization
- MRR movement classification
- active subscription checks
- customer lifecycle classification

Bad examples:

- full board reports
- complete KPI marts
- one-click forecasting frameworks
- dashboard-specific data transformations

## 1.3 Keep the package focused

The package should remain focused on the most repeated and stable RevOps logic.

Primary domains:

- CRM normalization
- revenue movement classification
- subscription activity logic
- customer lifecycle logic
- RevOps quality checks

Do not expand into broad or highly custom domains too early.

## 1.4 Prioritize clarity over cleverness

Macro logic should be easy to read, review, and explain.

Prefer:

- explicit naming
- readable conditional logic
- documented assumptions
- narrow responsibilities

Avoid:

- overly generic abstractions
- hidden side effects
- compressed logic that is difficult to audit
- unclear behavior around nulls and edge cases

---

# 2. Naming Conventions

## 2.1 General naming rules

Use descriptive names that reflect business meaning clearly.

Names should:

- be explicit
- be readable
- reflect the macro's output or purpose
- match RevOps business language

Avoid:

- vague names
- overloaded names
- abbreviations that reduce clarity
- technical names that hide business meaning

## 2.2 Prefix conventions

### Use `map_` for normalization or mapping macros

Examples:

- `map_hubspot_deal_stage_to_standard_group`
- `map_lifecycle_stage`

### Use `classify_` for categorical output macros

Examples:

- `classify_mrr_movement`
- `classify_customer_lifecycle`

### Use `is_` for boolean condition macros

Examples:

- `is_open_pipeline`
- `is_closed_won`
- `is_active_on_date`

### Use `effective_` for derived business date or state logic

Examples:

- `effective_end_date`

## 2.3 Domain naming

When useful, include the source system or business area in the name.

Examples:

- `map_hubspot_deal_stage_to_standard_group`
- `classify_mrr_movement`
- `is_active_on_date`

Do not include source names if the macro is intended to be source-agnostic.

## 2.4 Avoid weak names

Avoid names like:

- `process_stage`
- `handle_revenue`
- `check_status`
- `macro1`
- `pipeline_helper`

These names are too vague to maintain well over time.

---

# 3. Macro Design Rules

## 3.1 One macro, one clear responsibility

Each macro should have one clear purpose.

Good:

- map raw stage values to a standard stage group
- classify change between previous and current MRR
- determine if a subscription is active on a given date

Bad:

- normalize stages, score deals, and assign lifecycle states in one macro

## 3.2 Macros should return reusable logic

A macro should return logic that can be embedded cleanly inside SQL models.

Typical outputs:

- a SQL expression
- a categorical `CASE` expression
- a boolean expression
- a derived date expression

Do not use macros to hide large report-specific transformations.

## 3.3 Keep assumptions explicit

Each macro should make its assumptions clear in documentation.

Examples:

- whether null is treated like zero
- whether date boundaries are inclusive
- whether unknown stages fall into `Other`
- whether reactivation is separate from new revenue

## 3.4 Handle edge cases intentionally

Macros should not leave important behavior undefined.

Common edge cases:

- null values
- unknown CRM stages
- zero vs null revenue
- negative values
- historical source changes
- date boundary conditions

If a macro does not support an edge case, document that limitation clearly.

## 3.5 Avoid premature parameterization

Do not add many optional arguments unless there is a clear, repeated need.

Prefer:

- simpler macros with clear behavior
- additional specialized macros when justified

Avoid:

- highly configurable macros with too many optional flags
- generic frameworks designed for hypothetical future cases

## 3.6 Prefer business semantics over source-specific shortcuts

If source-specific logic is needed, separate it from broader business semantics.

Example:

- HubSpot stage mapping should remain separate from a generic `is_open_pipeline` rule if the latter is meant to become source-agnostic later.

---

# 4. Documentation Standards

## 4.1 Every macro should be documented

Each macro should include or be accompanied by documentation covering:

- purpose
- expected inputs
- output type
- null handling
- business assumptions
- edge cases
- example usage
- known limitations

## 4.2 Business language should be understandable

Documentation should be written so that both analytics engineers and RevOps stakeholders can understand the logic.

Use plain language whenever possible.

## 4.3 Define business terms centrally

The package should maintain a shared glossary for terms such as:

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
- active subscription

All macros should align to the glossary.

---

# 5. Package Organization Standards

## 5.1 Organize by business domain

Macros should be stored by domain, not by arbitrary technical grouping.

Recommended structure:

- `macros/crm/`
- `macros/revenue/`
- `macros/subscription/`
- `macros/lifecycle/`
- `macros/quality/`
- `macros/utils/` only when necessary

## 5.2 Keep `utils/` small

Generic helper logic should not become the main focus of the package.

The package should derive its value from RevOps-specific business logic, not generic SQL utilities.

Only place a macro in `utils/` if:

- it is truly reusable across multiple domains
- it is not tied to one RevOps concept
- it supports the package without replacing domain semantics

## 5.3 Keep source-specific files separate

Source-specific logic should be grouped clearly so it is easy to maintain and extend.

Example:

- HubSpot mappings should live under `macros/crm/`

## 5.4 File names should reflect the primary responsibility

File names should be explicit and aligned with the main logic they contain.

Good examples:

- `hubspot_stage_mapping.sql`
- `classify_mrr_movement.sql`
- `subscription_activity.sql`

Avoid:

- mixed-purpose files
- misleading file names
- files whose contents do not match the file name

---

# 6. Quality Standards

## 6.1 Favor consistency over local convenience

If a piece of logic is repeated in multiple models, centralize it in a macro rather than letting inconsistent variants spread.

## 6.2 Test important business logic

As the package grows, important semantic logic should be backed by custom tests or validation patterns.

Examples:

- unmapped CRM stages should be detectable
- duplicate account-period records should be preventable
- overlapping active subscriptions should be testable
- invalid revenue movements should be catchable

## 6.3 Avoid silent ambiguity

Unknown or unsupported conditions should be handled intentionally.

Examples:

- return a defined fallback category such as `Other`
- document unsupported scenarios
- avoid relying on implied assumptions that users cannot see

---

# 7. Decision Rules for Adding New Macros

A new macro should be added only if most of the following are true:

- it solves a repeated real-world problem
- it appears across multiple models or projects
- it represents stable or semi-stable business logic
- it improves consistency
- it can be explained clearly
- it belongs at the semantic building-block level

Do not add a macro if:

- it only supports one dashboard
- it is highly company-specific
- it belongs inside a final model
- it adds abstraction without meaningful reuse
- it turns the package into a generic utility toolbox

---

# 8. Anti-Patterns to Avoid

Avoid these anti-patterns as the package evolves:

## 8.1 Utility creep

Adding too many generic helper macros that dilute the RevOps focus.

## 8.2 Hidden business logic

Encoding important business assumptions without documenting them.

## 8.3 Over-parameterization

Adding too many optional arguments for hypothetical use cases.

## 8.4 Mixed responsibilities

Placing unrelated logic in one macro or one file.

## 8.5 Scope drift

Expanding into forecasting, attribution, compensation, or other complex domains too early.

---

# 9. Working Rule Going Forward

For every proposed macro, ask:

1. Is this a repeated RevOps problem?
2. Will this reduce duplicated business logic?
3. Is the business meaning clear?
4. Does this belong in a reusable macro instead of a model?
5. Can we document assumptions and edge cases clearly?

If the answer is mostly yes, the macro is a strong candidate.

If not, it should probably remain model-level logic instead of entering the package.

---

# 10. Summary

The `dbt_revops_macros` package should be built as a focused, high-quality semantic macro library for B2B SaaS RevOps.

Its strength should come from:

- clear business definitions
- practical reuse
- consistent naming
- disciplined scope
- readable logic
- gradual quality hardening

The goal is not to build the biggest package.

The goal is to build a package that solves real RevOps pain points well.
