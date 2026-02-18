# WT-05: Why Is This Query So Slow?

**Theme**: Performance investigation, query profiling, grain discipline, materialization decisions
**Time**: ~45–60 minutes
**Prior walkthroughs**: WT-01–04 recommended but not required

---

## The Scenario

It's 10:23 AM on a Thursday.

Your revenue dashboard loaded fine yesterday. Today it's showing **$187,246.50** in monthly revenue. Your finance team says the actual number is closer to **$62,000**. That's a 3x discrepancy.

And the dashboard is slow — the query that powers it used to return in 2 seconds. Now it's taking 11 seconds.

**Slack:**

> **@finance-ops** → **#data-team** (10:21 AM)
> Hey team — something weird is happening with the revenue dashboard. Numbers look ~3x what we'd expect. Is this a display issue or a real data problem? Also it's super slow to load today.
>
> **@data-team** → (10:22 AM)
> Looking into it now. Can you share the exact number you're seeing vs what you'd expect?
>
> **@finance-ops** → (10:23 AM)
> Dashboard: $187,246.50. Our books: ~$62,000. January through February orders.
>
> **@data-team** → (10:23 AM)
> On it.

You have 45 minutes before the 11 AM exec review.

---

## Setup

1. **Navigate to this directory**: `walkthroughs/wt05_slow_query/`

2. **Load the seed data**:
   ```bash
   dbt seed
   ```
   This creates four tables in the `raw` schema:
   - `raw_orders` — 50 orders, Jan–Feb 2024
   - `raw_order_items` — 50 line items (one per order in this dataset)
   - `raw_customers` — 20 customers
   - `raw_products` — 5 products

3. **Run the models** (they will run with the bug in place):
   ```bash
   dbt run
   ```

4. **Check what you get**:
   ```sql
   select sum(total_revenue) from fct_revenue_daily;
   -- Will return ~3x the actual revenue
   select count(*) from stg_orders;
   -- Will return ~50 * avg_items_per_order rows, not 50
   ```

5. **Open `analyses/01_investigation.sql`** and work through the queries step by step.

6. **Once you've found the bug**, open `analyses/02_solution.sql` for the fix and materialization guidance.

7. **After applying the fix**, run `analyses/03_verification.sql` to confirm all checks pass.

---

## The Schema

```
raw_orders          raw_order_items     raw_customers     raw_products
----------          ---------------     -------------     ------------
order_id (PK)       item_id (PK)        customer_id (PK)  product_id (PK)
customer_id         order_id (FK)       first_name        product_name
product_id          product_id          last_name         category
order_date          quantity            email             unit_price
status              unit_price          created_date      cost
amount              discount_pct        region            margin_pct
region                                  customer_segment  is_active
sales_rep_id                            lifetime_orders
```

**Known bug**: `stg_orders` currently joins `raw_order_items` inside the staging model. This changes the grain from 1-row-per-order to 1-row-per-line-item. Everything downstream is inflated.

---

## Learning Objectives

By the end of this walkthrough you should be able to:

1. **Diagnose a fan-out bug** using row count ratios (total rows vs distinct keys)
2. **Identify grain violations** in staging models — when a model's row count doesn't match its intended grain
3. **Trace root cause through the DAG** — find where in the lineage the bug was introduced
4. **Apply the fix correctly** — restructure staging models to enforce correct grain
5. **Choose the right materialization** — view vs table vs incremental, and when each applies
6. **Write a grain test** — prevent the same bug from shipping again

---

## Key Concepts

### Grain discipline
Every model has a *grain*: the level of detail it represents. `stg_orders` should be 1 row per order. If it's 1 row per order line item, it's wrong — and anything that aggregates it will be wrong too.

**Rule**: Establish the correct grain as early as possible in the DAG. Don't join across different grains without explicitly aggregating first.

### The fan-out pattern
When you join a "one" table (orders) to a "many" table (order_items) without aggregating the "many" side first, every row in the "one" table fans out to N rows. Downstream SUM() operations then over-count.

```
order_id  amount    order_id  item_id    →  order_id  amount  item_id
--------  ------    --------  -------       --------  ------  -------
1         $100  ×   1         A          =  1         $100    A
                    1         B             1         $100    B   ← duplicate!
                    1         C             1         $100    C   ← duplicate!
```

`SUM(amount)` on the right side gives $300, not $100.

### Staging model convention
Staging models should be thin wrappers:
- One source table → one staging model
- Rename, cast, clean — but don't join, don't aggregate
- Grain is always inherited from the source table's primary key

### Materialization ladder
| Type | When to use | Trade-off |
|------|-------------|-----------|
| `view` | Small data, infrequently queried | Re-runs every time, no storage cost |
| `table` | Mart layer, dashboards, slow queries | Pre-computed, takes storage, full refresh |
| `incremental` | Large tables, append-only data | Fastest refresh, but complex to maintain |

---

## Step-by-Step Guide

### Phase 1: Reproduce and quantify (10 min)
- Run `analyses/01_investigation.sql` Steps 1–2
- Goal: confirm the fan-out ratio (how many rows per order?)
- Goal: identify which specific orders are duplicated

### Phase 2: Find the root cause (10 min)
- Run Steps 3–4 of the investigation queries
- Trace: which model introduced the join?
- Open `stg_orders.sql` and find the bug line
- Ask: what *should* this model contain vs what it actually contains?

### Phase 3: Assess blast radius (5 min)
- Run Step 5 of investigation queries
- How many downstream models are affected?
- Which dashboards are reading wrong data right now?

### Phase 4: Apply the fix (15 min)
- Follow `analyses/02_solution.sql`
- Fix 1: Clean up `stg_orders` — remove the join
- Fix 2: Create `stg_order_items` — new model for line-item grain
- Fix 3: Update `fct_orders` — join with aggregated item totals
- Fix 4: Confirm `fct_revenue_daily` self-heals (no changes needed)

### Phase 5: Verify and protect (10 min)
- Run `analyses/03_verification.sql` — all checks should pass
- Review the grain test in `tests/assert_stg_orders_grain.sql`
- Discuss: what other tests would you add?

---

## Agent Lens

*This section is for the second pass: run the walkthrough as an agent.*

**What could an agent do automatically?**
- Detect the grain violation immediately: `count(*) != count(distinct order_id)` in stg_orders → automatic alert
- Quantify the revenue inflation before a human even notices
- Identify the join in stg_orders source code as the structural cause
- Run blast radius analysis: list all downstream models + dashboards affected
- Generate the fix (restructured SQL) and the grain test
- Propose the correct materialization for each model given data volume

**What needs human judgment?**
- Is the line-item detail in fct_orders actually wanted? (Business data model question)
- How do we communicate the historical discrepancy to finance?
- Do we revert the PR or patch forward?
- What's the rollback plan if the fix has unintended side effects?
- Are there other places in the codebase with similar fan-out patterns?

**Form factor insight:**
The agent can compress the investigation from 2 hours to 5 minutes. It runs all the diagnostic queries instantly, surfaces the root cause with evidence, and drafts the fix. The human's job becomes: review the evidence, decide on data model direction, approve the fix. This is the copilot model — agent drives the investigation, human steers the decisions.

**Key agent tool needed**: `db_query(sql, warehouse)` — the ability to run arbitrary SQL against the data warehouse. Everything in this walkthrough flows from that single capability.

---

## Key Takeaways

1. **Slow queries often mean more rows, not bad SQL** — diagnose volume before optimizing syntax
2. **Staging models enforce grain** — one source table, one staging model, no joins
3. **Fan-out is silent** — no error is thrown, the query succeeds, the numbers are just wrong
4. **Aggregate before you join** — always resolve the "many" side to a single row before joining to the "one" side
5. **Tests encode grain** — `count(*) != count(distinct pk)` is the fastest grain test you can write
6. **Upstream fixes are worth more** — fixing stg_orders healed fct_orders and fct_revenue_daily automatically

---

## Files in This Walkthrough

```
wt05_slow_query/
├── README.md                           ← You are here
├── dbt_project.yml
├── seeds/
│   ├── raw_orders.csv                  ← 50 orders (Jan–Feb 2024)
│   ├── raw_order_items.csv             ← 50 line items
│   ├── raw_customers.csv               ← 20 customers
│   └── raw_products.csv                ← 5 products
├── models/
│   ├── staging/
│   │   ├── src_acme.yml
│   │   ├── stg_models.yml
│   │   ├── stg_orders.sql              ← BROKEN (fan-out bug)
│   │   ├── stg_customers.sql           ← Clean
│   │   └── stg_products.sql            ← Clean
│   └── marts/
│       ├── fct_orders.sql              ← Downstream victim
│       └── fct_revenue_daily.sql       ← Downstream victim (inflated revenue)
├── analyses/
│   ├── 01_investigation.sql            ← Work through this first
│   ├── 02_solution.sql                 ← Reference fix + materialization guidance
│   ├── 03_verification.sql             ← Run after fixing
│   └── 04_postmortem.md               ← Retrospective template
└── tests/
    └── assert_stg_orders_grain.sql     ← Prevents recurrence
```
