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
