# dbt RevOps Macros

A focused `dbt` macro package for **B2B SaaS Revenue Operations**.

This package is designed to centralize repeated, error-prone business logic that often gets duplicated across analytics models. The goal is to make RevOps transformations easier to maintain, easier to reuse, and more consistent across projects.

## Why this package exists

In most B2B SaaS analytics projects, the same business logic appears again and again:

- CRM stage grouping
- open vs closed pipeline logic
- recurring revenue movement classification
- subscription activity checks
- customer lifecycle classification
- RevOps-oriented data quality checks

When this logic is copied into many models, teams usually run into:

- inconsistent definitions across reports
- difficult-to-maintain `CASE WHEN` blocks
- silent logic drift over time
- broken funnel or revenue reporting after source changes

This package aims to solve that by providing reusable semantic macros.

---

# Package Scope

## What this package does

This package focuses on reusable RevOps business logic for:

1. **CRM normalization**
2. **Revenue movement classification**
3. **Subscription activity logic**
4. **Customer lifecycle semantics**
5. **RevOps quality checks**

## What this package does not do

This package is **not** intended to be:

- a full RevOps warehouse framework
- a dashboard package
- a forecasting engine
- an attribution framework
- a compensation model
- a lead scoring system
- a generic SQL helper library

The package should stay focused on **high-reuse semantic logic**.

---

# Design Principles

Every macro in this package should follow these principles:

1. **Solve repeated real-world pain**  
   Only add logic that appears repeatedly in RevOps work.

2. **Be a reusable building block**  
   Macros should provide semantic logic, not full final models.

3. **Keep business definitions explicit**  
   Inputs, outputs, assumptions, null behavior, and edge cases should be clear.

4. **Separate source-specific logic from business logic**  
   Example: HubSpot stage mapping should be distinct from general pipeline semantics.

5. **Avoid overengineering**  
   Build for current repeated needs, not hypothetical future complexity.

---

# Project Structure

## Current structure

```text
dbt_revops_macros/
├── docs/
│   └── revops_macros_plan.md
├── macros/
│   ├── crm/
│   ├── lifecycle/
│   ├── quality/
│   ├── revenue/
│   ├── subscription/
│   └── utils/
├── dbt_project.yml
└── README.md
```

## Macro domain folders

- `macros/crm/`  
  CRM normalization logic such as stage mapping and open/closed pipeline checks

- `macros/revenue/`  
  Revenue movement logic such as MRR and ARR classification

- `macros/subscription/`  
  Subscription and contract activity logic

- `macros/lifecycle/`  
  Customer lifecycle classification logic

- `macros/quality/`  
  RevOps-specific custom tests and validation helpers

- `macros/utils/`  
  Only for lightweight helpers when necessary

---

# Planned Macro Categories

## 1. CRM normalization

Examples:

- map HubSpot deal stages to standard groups
- standardize lifecycle stage logic
- identify open pipeline

## 2. Revenue movement classification

Examples:

- classify MRR movement
- classify ARR movement
- identify expansion, contraction, churn, retained, new

## 3. Subscription activity logic

Examples:

- check whether a subscription is active on a given date
- define effective end dates
- standardize active-period logic

## 4. Customer lifecycle semantics

Examples:

- classify customer lifecycle state
- identify new, churned, and reactivated customers

## 5. Quality and validation

Examples:

- detect unmapped CRM stages
- validate subscription overlaps
- check required fields for won deals
- validate account-period grain assumptions

---

# Current Direction

The strongest near-term focus for this package is:

1. CRM normalization
2. revenue movement classification
3. subscription activity logic

After those are solid, the package can expand into:

4. lifecycle classification
5. quality and custom tests

---

# Usage

## Install as a local package

In your main project's `packages.yml`:

```yaml
packages:
    - local: ../dbt_revops_macros
```

Then run:

```bash
dbt deps
```

---

# Example Usage

Example macro usage inside a model:

```sql
select
    deal_id,
    stage,
    {{ revops_macros.map_hubspot_deal_stage_to_standard_group('stage') }} as stage_group
from {{ ref('stg_hubspot_deals') }}
```

Example revenue classification usage:

```sql
select
    account_id,
    month_start,
    previous_mrr,
    current_mrr,
    {{ revops_macros.classify_mrr_movement('previous_mrr', 'current_mrr') }} as mrr_movement
from {{ ref('int_account_mrr_by_month') }}
```

---

# Macro Quality Standards

Every macro in this package should include:

- clear business purpose
- expected inputs
- defined output type
- null handling behavior
- edge-case assumptions
- example usage
- known limitations where relevant

This is important because RevOps logic often affects critical reporting across Sales, Marketing, Customer Success, and Finance.

---

# Documentation Plan

This repository should gradually include:

- package overview and scope
- business glossary
- naming conventions
- phase roadmap
- macro backlog
- usage examples
- custom test guidance

The current working plan is documented in:

- `docs/revops_macros_plan.md`

---

# Near-Term Roadmap

## Phase 0 — Foundation

- define package scope
- define business glossary
- clean up structure and naming
- document standards

## Phase 1 — Core CRM and Revenue Macros

- HubSpot stage mapping
- open / closed pipeline checks
- MRR movement classification

## Phase 2 — Subscription Activity Logic

- active-on-date logic
- effective end-date logic
- active-in-period checks

## Phase 3 — Lifecycle Semantics

- customer lifecycle classification
- reactivation logic
- churned customer logic

## Phase 4 — Quality and Custom Tests

- stage mapping validation
- duplicate grain validation
- subscription overlap checks
- RevOps-specific business tests

---

# Contribution Guideline

Before adding a new macro, ask:

- Does this solve a repeated RevOps problem?
- Will it be reused across multiple models or projects?
- Is the business definition stable enough to standardize?
- Does it belong in a macro rather than a final model?
- Can it be documented clearly?

If the answer is mostly no, it likely should not be added to this package.

---

# Summary

`dbt_revops_macros` should become a focused, high-quality semantic macro library for common B2B SaaS RevOps analytics logic.

The package should prioritize:

- consistency
- reuse
- clarity
- maintainability
- real business value

and avoid becoming a broad, unfocused collection of unrelated logic.
