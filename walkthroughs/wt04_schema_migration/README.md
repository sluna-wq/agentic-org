# WT-04: "The Schema Migration"

> **You are**: Data engineer. The backend team just deployed to production.
>
> **It's 2:47 PM on a Tuesday.** Your Slack blows up.

---

## The Alert

```
[2:47 PM] #data-alerts (automated)
  ❌ dbt run FAILED — 8 models errored
  ❌ dbt test FAILED — 23 tests errored
  Run ID: run_20260217_1447

[2:48 PM] Sarah (VP Sales)
  hey the sales dashboard is totally blank??

[2:49 PM] Marcus (Backend Lead)
  @data-team heads up we deployed the accounts migration today
  users table is now accounts, split the address field into components
  should be backwards compatible lol

[2:51 PM] Sarah (VP Sales)
  @you this is bad, we have a customer call in 2 hours

[2:52 PM] You
  on it
```

The backend team renamed `users` to `accounts` and split the `address` field. Your 8 staging and mart models just broke. 15 downstream dashboards are dark. You have 2 hours.

---

## Setup: The Broken State

This walkthrough starts in a broken state — **by design**.

The `seeds/` directory contains the *new* schema that the backend team deployed:
- `raw_accounts.csv` — replaces `raw_customers` (renamed + restructured)
- All other seeds unchanged from WT-01

Your dbt models still reference the old `raw_customers` source with the old column names. They will fail immediately. That's the scenario.

### Step 1: Set Up Your Environment

```bash
# From ~/Desktop/claude/de-playground/
cp -r acme_analytics/ wt04_schema_migration/
cd wt04_schema_migration/

# Overlay the new broken-state files from this walkthrough
cp ~/Desktop/claude/de-playground/../[path-to-walkthroughs]/wt04_schema_migration/seeds/* seeds/
cp ~/Desktop/claude/de-playground/../[path-to-walkthroughs]/wt04_schema_migration/analyses/* analyses/

# Load seeds and run — watch it fail
dbt seed
dbt run
```

> **Expected output**: 8 errors. Read them carefully — they're your map.

### Step 2: Reproduce the Blast Radius

Before fixing anything, understand the scope.

```bash
# List all models that depend on stg_customers
dbt ls --select stg_customers+

# What does the new source look like?
dbt run-operation print_schema --args '{"relation": "raw.raw_accounts"}'
# (or just query it directly)
```

Open the analysis file for a guided investigation:
```bash
# In your DuckDB session or dbt run-operation:
-- See analyses/01_blast_radius.sql
```

### Step 3: Understand the New Schema

The backend team's migration:

| Old (`raw_customers`) | New (`raw_accounts`) |
|----------------------|---------------------|
| `customer_id` | `account_id` |
| `first_name` | `first_name` |
| `last_name` | `last_name` |
| `email` | `email` |
| `address` (single field) | `street`, `city`, `state_code`, `postal_code` |
| `created_at` | `created_at` |
| `updated_at` | `updated_at` |
| `is_active` | `is_active` |
| `customer_segment` | `account_tier` *(renamed!* |
| `phone` | `phone` |
| `country` | `country_code` *(renamed!)* |

Two gotchas beyond the obvious rename:
1. `customer_segment` → `account_tier` (values also changed: `premium`→`gold`, `standard`→`silver`, `enterprise`→`platinum`)
2. `country` → `country_code` (data itself unchanged, just column name)

### Step 4: Fix It — Backward-Compatible Staging

Your job is to fix `stg_customers.sql` so:
1. It reads from the new `raw_accounts` source
2. It outputs the **same column names as before** (so downstream models don't break)
3. It maps the new tier values back to the old segment values (or adds both)

This is the backward-compatibility pattern. Downstream models should not need to change.

Try it yourself first. Reference solution in `analyses/02_solution_staging.sql`.

### Step 5: Update the Source Definition

`src_acme.yml` still declares `raw_customers`. You need to:
1. Add `raw_accounts` as a new source
2. Decide: do you keep `raw_customers` (for backward compat) or replace it?
3. Add a schema contract test so this never surprises you again

### Step 6: Verify the Fix

```bash
dbt seed && dbt run && dbt test
```

All 8 models should pass. Run a sanity check:
```bash
-- See analyses/03_verification.sql
-- Confirm: same customer count, same revenue totals as before migration
```

### Step 7: The Conversation You Need to Have

The fix works. But the real work is preventing this from happening again.

Open `analyses/04_postmortem.md` — a template for the retrospective with the backend team.

Key questions to work through:
- Who owns the "contract" between app schema and data team?
- How do we get notified before a schema change ships?
- What tests would have caught this in staging?

---

## What You're Learning

### The Technical Skills
- **Blast radius analysis**: `dbt ls --select model+` and `+model` to traverse the DAG
- **Backward-compatible staging**: absorb upstream changes, protect downstream consumers
- **Source contracts**: column-level tests that catch schema drift
- **Value mapping**: when upstream renames enum values, stage the translation
- **Schema change detection**: `dbt source freshness` + schema snapshot patterns

### The Organizational Skill
The app team said this was "backwards compatible." It wasn't — not for your layer. This gap (app team doesn't know data team exists in their blast radius) is extremely common.

**The data team needs a seat at the backend team's migration review.**

---

## Agent DE Lens

After you've worked through this manually, think about:

**What could an agent have done automatically?**
- Detected the schema change before `dbt run` failed (schema diff monitoring)
- Identified all affected downstream models instantly
- Generated a draft `stg_customers.sql` fix with the column mapping
- Drafted the backward-compat migration

**What requires human judgment?**
- The `customer_segment` → `account_tier` value mapping (business meaning changed)
- Whether to keep old column names or migrate downstream too
- The organizational conversation with the backend team
- Deciding if this is "fix forward" or "escalate first"

**The pattern**: Agents can automate the mechanical blast-radius + draft-fix work in minutes. The judgment calls (business meaning, org dynamics) still need a human. But with the agent handling the investigation, you walk into that backend team conversation already knowing the full impact.

---

## Key Takeaways

1. **Schema changes are never just a rename** — value semantics often change too
2. **Backward compatibility is your responsibility** — the staging layer is your blast shield
3. **`dbt ls` is your first tool in any incident** — understand impact before touching anything
4. **The contract problem is organizational, not technical** — fix the process, not just the SQL
5. **Detection latency is the real cost** — 2:47 PM discovery for a 2:00 PM deploy is 47 minutes of dark dashboards

---

## Files in This Walkthrough

```
wt04_schema_migration/
├── README.md                    ← You are here
├── dbt_project.yml
├── profiles.yml
├── seeds/
│   └── raw_accounts.csv         ← New schema (replaces raw_customers)
├── models/
│   ├── staging/
│   │   ├── src_acme.yml         ← Needs updating (still points to raw_customers)
│   │   ├── stg_customers.sql    ← BROKEN — references old schema
│   │   ├── stg_orders.sql
│   │   ├── stg_payments.sql
│   │   ├── stg_products.sql
│   │   ├── stg_order_items.sql
│   │   └── stg_web_events.sql
│   └── marts/
│       ├── dim_customers.sql    ← Downstream, will fail if stg_customers fails
│       ├── dim_products.sql
│       ├── fct_orders.sql
│       └── fct_revenue_daily.sql
├── analyses/
│   ├── 01_blast_radius.sql      ← Investigation queries
│   ├── 02_solution_staging.sql  ← Reference fix (try yourself first!)
│   ├── 03_verification.sql      ← Sanity checks post-fix
│   └── 04_postmortem.md         ← Retrospective template
└── tests/
    └── assert_schema_contract.sql  ← New test: catch this next time
```
