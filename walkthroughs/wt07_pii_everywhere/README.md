# WT-07: PII Everywhere

**Theme**: PII detection, lineage tracing, data classification, compliance remediation
**Time**: ~45–60 minutes
**Prior walkthroughs**: WT-01–06 recommended but not required

---

## The Scenario

It's 2:15 PM on a Thursday.

Everything looked fine this morning. Your dashboards are green, pipelines ran overnight without errors.

Then a Slack message arrives from the security team.

**Slack:**

> **@security-ops** → **#data-team** (2:12 PM)
> Hey — our quarterly audit flagged something. The Looker revenue dashboard is showing customer email addresses and phone numbers in the customer orders table. That shouldn't be there. Also looks like those fields may have gone out in the January and February marketing exports to our vendor partners.
>
> **@data-team** → (2:14 PM)
> Wait, what? Let me look.
>
> **@security-ops** → (2:15 PM)
> The exports went to vendor_mailchimp (Jan 31) and vendor_salesforce (Feb 7). We have EU customers in there — Carol, Eva, Isabel — so GDPR Article 33 may apply. 72-hour notification window starts from when you confirm a breach.
>
> **@data-team** → (2:15 PM)
> On it. Pulling the lineage now.

You need to: (1) confirm the blast radius, (2) find how PII entered the analytics layer, (3) apply the fix, (4) document the incident.

The 72-hour GDPR clock may already be ticking.

---

## Setup

1. **Navigate to this directory**: `walkthroughs/wt07_pii_everywhere/`

2. **Load the seed data**:
   ```bash
   dbt seed
   ```
   This creates three tables in the `raw` schema:
   - `raw_customers` — 20 customers with PII fields (email, phone, ssn_last4)
   - `raw_orders` — 20 orders (no PII)
   - `raw_marketing_exports` — 10 vendor export records

3. **Run the models** (they will run with the PII leak in place):
   ```bash
   dbt run
   ```

4. **Check what you get**:
   ```sql
   -- Confirm PII is present in the mart
   select order_id, customer_id, email, phone, ssn_last4
   from fct_customer_orders limit 5;

   -- Confirm PII reached the vendor export mart
   select customer_id, email, phone, destination
   from fct_marketing_reach limit 5;
   ```

5. **Open `analyses/01_investigation.sql`** and work through all 4 phases.

6. **Once you've traced the lineage**, open `analyses/02_solution.sql` for the fix and incident checklist.

7. **After applying the fix**, run `analyses/03_verification.sql` to confirm PII is fully removed.

---

## The Schema

```
raw_customers           raw_orders              raw_marketing_exports
─────────────           ──────────              ─────────────────────
customer_id (PK)        order_id (PK)           export_id (PK)
first_name              customer_id (FK)        export_date
last_name               product_id              customer_id (FK)
email         ← PII     order_date              export_type
phone         ← PII     status                  destination
ssn_last4     ← PII     amount                  row_count
signup_date             region                  status
plan
country
```

**The trap**: `stg_customers` uses `SELECT *` from `raw_customers`. This is fine in isolation — but because staging models feed every downstream mart, PII flows silently into `fct_customer_orders` (visible in Looker) and `fct_marketing_reach` (fed the vendor export pipeline). No error. No warning. Everything ran green.

---

## Learning Objectives

1. **PII lineage tracing** — follow a column from raw source through staging into marts and exports
2. **SELECT * as a blast radius multiplier** — understand why `SELECT *` in staging creates invisible data contracts
3. **Blast radius assessment** — quantify who saw what, when, from which tables
4. **Compliance awareness** — recognize when GDPR Art. 33 (72hr breach notification) is triggered
5. **Defense in depth** — staging column allowlists + CI tests + BI permissions as layered controls
6. **Incident response structure** — how to scope, fix, document, and prevent

---

## Key Concepts

### SELECT * in Staging Models

Staging models are consumed by many downstream models. When a staging model uses `SELECT *`, any new column added to the source — including PII — automatically flows downstream without any code change or review.

```sql
-- DANGEROUS: any column in raw_customers is now in every downstream mart
select * from {{ source('raw', 'raw_customers') }}

-- SAFE: only explicitly approved columns pass through
select
    customer_id,
    first_name,
    last_name,
    signup_date::date as signup_date,
    plan,
    country
from {{ source('raw', 'raw_customers') }}
```

### PII Classification at Source

The right place to document PII is in the source YAML — at the boundary between raw and staging. Every column in a source table should be classified. This makes it auditable and reviewable in PRs.

```yaml
- name: email
  description: "PII: customer email address — do not propagate past staging"
- name: ssn_last4
  description: "PII: last 4 digits of SSN — never leave raw schema"
```

### CI Gate: PII in Marts

A test that queries the mart and checks for the presence of forbidden columns acts as a regression guard. Once added to CI, it prevents future PII leaks from ever merging.

```sql
-- This test FAILS (returns rows) if PII is in the mart.
-- 0 rows = clean. Any rows = merge blocked.
select 'email' as forbidden_column, count(*) as leak_count
from fct_customer_orders
where email is not null
```

### GDPR Article 33 Trigger

If personal data of EU residents was exposed to unauthorized parties (including vendors without DPA coverage), a 72-hour notification to the supervisory authority is required. Key check: were any EU-resident customers in the vendor exports?

```sql
-- Check for EU-resident customers in vendor exports
select distinct customer_id, first_name, last_name, country
from fct_marketing_reach
where country in ('DE','FR','IT','ES','NL','SE','DK','PL','BE','AT')
  and status = 'sent';
```

---

## Step-by-Step Guide

### Phase 1: Confirm the Symptom (5 min)
- Query `fct_customer_orders` — are email/phone/ssn_last4 present?
- Query `fct_marketing_reach` — did PII reach vendor records?
- Check column list of `stg_customers` via `information_schema.columns`

### Phase 2: Trace the Lineage (10 min)
- Open `models/staging/stg_customers.sql` — find the `SELECT *`
- Confirm `raw_customers` legitimately has PII (it should — it's the source of truth)
- Walk the lineage: raw_customers → stg_customers → fct_customer_orders / fct_marketing_reach
- Use `information_schema.columns` to confirm which mart tables have the PII columns

### Phase 3: Scope the Blast Radius (10 min)
- Which vendors received exports? When? How many customers?
- Which customers are EU residents? (GDPR trigger check)
- Who has access to the BI mart with PII columns visible?

### Phase 4: Apply the Fix (10 min)
- Edit `stg_customers.sql` — replace `SELECT *` with explicit safe column list
- Edit `fct_customer_orders.sql` — remove `c.email`, `c.phone`, `c.ssn_last4` from select
- Edit `fct_marketing_reach.sql` — same removal
- Run `dbt run --select stg_customers fct_customer_orders fct_marketing_reach`

### Phase 5: Verify and Document (15 min)
- Run `analyses/03_verification.sql` — confirm 0 PII columns in marts
- Run `dbt test` — `assert_no_pii_in_marts` should pass (0 rows)
- Review `analyses/04_postmortem.md` — fill in the incident documentation
- Note: vendor data deletion requests and GDPR notification are out-of-band actions

---

## Agent Lens

*What does this walkthrough look like when an agent is the data engineer?*

### What the agent can do autonomously
- Scan `information_schema.columns` across all non-raw schemas for PII column names
- Trace lineage by parsing dbt `ref()` and `source()` chains
- Identify the `SELECT *` bug by reading model SQL
- Compute blast radius: which tables, which customers, which vendors, which dates
- Generate the fix (explicit column list in staging, remove PII refs in marts)
- Write and run the CI test
- Draft the postmortem with timeline, affected records, and remediation steps

### What needs human judgment
- **Vendor notification**: Should we ask vendor_mailchimp and vendor_salesforce to delete the data? What's the contractual relationship?
- **GDPR assessment**: Does our DPA with these vendors cover this? Do we need to notify a supervisory authority?
- **BI access review**: Should we immediately revoke query access to affected marts while the fix is applied?
- **Customer notification**: Do affected customers need to be told?

### Form factor insight
This is a high-urgency, time-bounded incident. The agent excels at the **fast, systematic** work: lineage tracing, blast radius quantification, fix generation. The human needs to be in the loop for **legal and vendor decisions** — but the agent dramatically compresses the time to reach those decision points. In a manual process, scoping the blast radius alone takes hours. An agent does it in seconds.

---

## Key Takeaways

1. **`SELECT *` in staging is a silent PII multiplier** — any PII column added to the source automatically propagates to every downstream mart and export
2. **Detection came from outside** — external audit, not internal monitoring. The fix: CI tests that catch PII at mart boundaries
3. **Lineage is the investigation tool** — once you can trace column provenance, you can quantify blast radius in minutes
4. **Staging is the right firewall** — PII should be classified and blocked at the raw→staging boundary, not patched out of dozens of marts
5. **Compliance clock is real** — GDPR Art. 33 triggers on external transmission to unauthorized parties; EU residents in vendor exports may require 72hr notification
6. **Agent shape for incidents**: fast scoping + automated fix generation, human owns legal/vendor decisions

---

## Files in This Walkthrough

```
wt07_pii_everywhere/
├── README.md                          # This file
├── dbt_project.yml                    # dbt project config
├── seeds/
│   ├── raw_customers.csv              # 20 customers with PII columns
│   ├── raw_orders.csv                 # 20 orders (no PII)
│   └── raw_marketing_exports.csv      # 10 vendor export records
├── models/
│   ├── staging/
│   │   ├── src_acme.yml               # Source definitions with PII annotations
│   │   ├── stg_customers.sql          # THE BUG: SELECT * leaks PII
│   │   ├── stg_orders.sql             # Clean model
│   │   ├── stg_marketing_exports.sql  # Clean model
│   │   └── stg_models.yml             # Schema with PII leak documentation
│   └── marts/
│       ├── fct_customer_orders.sql    # PII propagates here (BI exposure)
│       └── fct_marketing_reach.sql    # PII propagates here (vendor exposure)
├── analyses/
│   ├── 01_investigation.sql           # 4-phase investigation queries
│   ├── 02_solution.sql                # Fix steps + incident checklist
│   ├── 03_verification.sql            # Post-fix verification queries
│   └── 04_postmortem.md               # Incident postmortem template
└── tests/
    └── assert_no_pii_in_marts.sql     # CI gate: fails if PII in marts
```
