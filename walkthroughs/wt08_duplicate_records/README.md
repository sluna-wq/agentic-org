# WT-08: The Duplicate Problem

**Scenario**: Revenue is inflated by ~40%. Bank reconciliation caught it — the dashboard didn't.

**The Bug**: The ETL pipeline retries on transient failures without idempotency. Each retry inserts a new row with a new UUID as `payment_id`. Standard dbt `unique` test on `payment_id` passes — every UUID is unique. But the same transaction (order_id + customer_id + amount) appears 2–3 times with timestamps seconds apart.

**The Symptom**: Finance opens a ticket: *"Dashboard shows $847K monthly revenue. Bank reconciliation shows $603K. $244K discrepancy."*

**What Makes This Hard**:
- dbt `unique` test passes (payment_id is unique)
- dbt `not_null` test passes
- Row counts look plausible — no obvious spike
- The duplicates are spread across thousands of orders, so no single row looks suspicious
- Only visible when you join to orders and look for fan-out

**Estimated Time**: ~45 min

---

## Setup

```bash
cd walkthroughs/wt08_duplicate_records
dbt seed
dbt run
dbt test
```

Note: `dbt test` will pass. That's the point — the existing tests miss this entirely.

---

## The Investigation Path

### Phase 1 — Confirm the discrepancy (5 min)
Run `analyses/01_investigation.sql` Step 1.
You'll see dashboard revenue vs. deduplicated revenue side by side.
The gap is real and consistent.

### Phase 2 — Rule out mart logic (10 min)
Run Step 2 from `01_investigation.sql`.
Check `fct_revenue_monthly` — is the inflation in the mart or upstream?
Trace back to `stg_payments`. Count rows vs. distinct (order_id, amount) pairs.

### Phase 3 — Find the duplicate signature (10 min)
Run Step 3. Look for payments with the same order_id, customer_id, and amount within a short time window.
You'll find clusters: same order, same amount, timestamps 2–8 seconds apart, different payment_ids.

### Phase 4 — Scope the blast radius (5 min)
Run Step 4. How many orders are affected? What % of revenue is duplicated?
Check `fct_customer_ltv` — customer LTV is also inflated.

### Phase 5 — Fix and verify (15 min)
Run `analyses/02_solution.sql` — deduplicate by keeping earliest payment per (order_id, customer_id, amount).
Run `analyses/03_verification.sql` — confirm revenue matches bank figure.
Add `tests/assert_no_duplicate_payments.sql` to CI.

---

## Agent Lens

*What does this walkthrough look like when an agent is the data engineer?*

### What the agent can do autonomously
- Query `stg_payments` for semantic duplicates: same `(order_id, customer_id, amount)` within a short time window, different `payment_id`
- Compare dashboard revenue vs. deduplicated revenue in a single query — confirm the gap is real and consistent
- Trace which mart models depend on `stg_payments` and quantify inflation in each (revenue, LTV, cohort metrics)
- Scope blast radius: how many orders affected, what % of total revenue is duplicated, which time periods
- Generate the dedup fix: `ROW_NUMBER()` or `DISTINCT ON` keeping earliest payment per `(order_id, customer_id, amount)`
- Write the CI gate (`assert_no_duplicate_payments.sql`) and confirm it catches the bug before the fix, passes after
- Draft the postmortem: timeline, affected records, root cause, prevention

### What needs human judgment
- **ETL remediation**: The dbt dedup fix suppresses symptoms — the root cause is the ETL retry logic. Fixing idempotency at ingestion (upsert on `order_id + amount`, not INSERT) requires eng team coordination and a deployment decision.
- **Financial restatement**: $244K in phantom revenue. Were board reports, investor updates, or commissions calculated on inflated figures? Who needs to know, and when?
- **Retroactive correction timing**: Applying the fix mid-month changes historical figures. Finance needs to control when the corrected numbers land — month-end close timing is a business call.
- **Vendor/external exposure**: If revenue figures were shared externally (auditors, lenders, partners), corrected data needs to go to them. That's a relationship-level decision.

### Form factor insight
Detection is the highest-leverage agent capability here — not the fix. A human running monthly bank reconciliation catches this after the fact. An agent running **continuous reconciliation** (pipeline revenue vs. payment processor totals daily) would catch it within 24 hours of the first retry duplication. The investigation path is fully automatable — pattern detection, blast radius, fix generation, CI test. What requires humans is the consequence management: restatement, ETL coordination, and external communication. The agent compresses the time from "Finance opens a ticket" to "root cause and blast radius confirmed" from hours to minutes.

This connects directly to **WT-02's insight**: continuous reconciliation against an external source of truth (the bank) is the highest-value agent capability. Not pipeline building — detection latency elimination.

---

## Key Learning

> Standard uniqueness tests guard against ID collisions — not semantic duplicates. Idempotency must be enforced at ingestion, not assumed. When a reconciliation number and a dashboard number disagree, trust the reconciliation.

---

## Files

| File | Purpose |
|------|---------|
| `seeds/raw_payments.csv` | 500 payment rows, ~120 duplicates from ETL retries |
| `seeds/raw_orders.csv` | 400 orders |
| `seeds/raw_customers.csv` | 150 customers |
| `models/staging/stg_payments.sql` | Naive staging — no dedup |
| `models/marts/fct_revenue_monthly.sql` | Monthly revenue (inflated) |
| `models/marts/fct_customer_ltv.sql` | Customer LTV (inflated) |
| `analyses/01_investigation.sql` | 4-step investigation queries |
| `analyses/02_solution.sql` | Dedup fix |
| `analyses/03_verification.sql` | Confirm fix works |
| `analyses/04_postmortem.md` | Root cause + prevention |
| `tests/assert_no_duplicate_payments.sql` | CI gate |
