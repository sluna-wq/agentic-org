# WT-08 Postmortem: The Duplicate Problem

**Date**: 2024-01-25
**Severity**: High — $244K revenue inflation ($847K reported vs $603K actual)
**Detection**: Finance team via bank reconciliation (not monitoring, not dbt tests)

---

## Root Cause

The ETL pipeline lacked idempotency. On transient network errors (timeouts, 5xx from the payment processor API), the pipeline retried without checking whether the previous attempt had succeeded. Each retry inserted a new row with a new UUID as `payment_id`.

The existing dbt `unique` test on `payment_id` passed because each retry genuinely had a unique ID. The duplicate was **semantic**, not structural.

---

## Why It Wasn't Caught Earlier

1. **Wrong uniqueness key**: Testing `payment_id` uniqueness doesn't detect semantic duplicates. The correct business key is `(order_id, customer_id, amount)`.
2. **No reconciliation monitor**: No automated check comparing pipeline revenue to an external source.
3. **Spread across many rows**: ~120 duplicate rows across 400 orders. No single value looked anomalous.
4. **Timestamps close together**: 2–8 seconds apart — looked like valid concurrent payments to any spot check.

---

## Fix Applied

1. Added `ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, amount ORDER BY paid_at ASC)` in `stg_payments.sql`
2. Filter `WHERE row_num = 1` keeps canonical (earliest) payment only
3. Added `is_duplicate` flag for audit trail
4. Added `tests/assert_no_duplicate_payments.sql` to CI

---

## Prevention

1. **ETL idempotency**: Upsert on business key, not insert on UUID.
2. **Semantic uniqueness tests**: Test `(order_id, customer_id, amount)` uniqueness, not just `payment_id`.
3. **Reconciliation test**: Automated daily check — pipeline revenue vs. payment processor export.
4. **Duplicate rate metric**: Alert if duplicate detection rate exceeds 0.1%.

---

## Lessons

- A `unique` test on a surrogate key is a structural test, not a semantic test.
- If Finance has a reconciliation number, trust it over the dashboard.
- ETL retry logic needs to be idempotent by design — this is table stakes.
