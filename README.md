# dbt RevOps Macros

A focused `dbt` macro package for **B2B SaaS Revenue Operations**.

This package centralizes repeated, error-prone business logic across analytics models, ensuring consistency in RevOps transformations.

## Core Domains

- **CRM Normalization**: Stage mapping, pipeline velocity, and field completeness.
- **Revenue Classification**: MRR movement, ARR segmentation, and contract normalization.
- **Subscription Activity**: Active status tracking, renewal detection, and proximity.
- **Customer Lifecycle**: Cohort assignment and health tiering.
- **Finance & Quality**: Invoice aging, discount rates, and data sanity checks.

---

## Installation

In your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/farrux05-ai/dbt-revops-macros.git"
    revision: main # or a specific version tag
```

Then run:
```bash
dbt deps
```

---

## Usage Examples

### 1. CRM Stage Mapping
```sql
select
    deal_id,
    {{ dbt_revops_macros.map_hubspot_deal_stage_to_standard_group('stage_name') }} as stage_group
from {{ ref('stg_hubspot_deals') }}
```

### 2. Revenue Movement Classification
```sql
select
    account_id,
    {{ dbt_revops_macros.classify_mrr_movement('previous_mrr', 'current_mrr') }} as mrr_category
from {{ ref('int_account_mrr_by_month') }}
```

---

## Documentation & Standards

- **[Business Logic Guide](docs/BUSINESS_LOGIC_GUIDE.md)**: Detailed explanation of the "Why" behind the logic.
- **[Business Glossary](docs/business_glossary.md)**: Definitions for key RevOps terms used in this package.
- **[Package Conventions](docs/conventions.md)**: Design principles and naming standards.

Full technical documentation for each macro is available via `dbt docs generate`.

---

## Project Structure

```text
macros/
├── crm/          # CRM normalization & pipeline logic
├── revenue/      # MRR/ARR logic & classification
├── subscription/ # Subscription activity & renewals
├── lifecycle/    # Customer cohorts & health
├── finance/      # Invoice aging & pricing
├── quality/      # RevOps-specific data quality tests
└── utils/        # Shared helper macros
```
