# WT-07 Postmortem: PII Everywhere

**Incident date**: 2024-02-07 (when auditors flagged the exposure)
**Detection method**: External security audit (not internal monitoring)
**Severity**: High — PII transmitted to third-party vendors

---

## Root Cause

`stg_customers.sql` used `SELECT *` from `raw_customers`. The raw table contains PII fields (`email`, `phone`, `ssn_last4`) that are appropriate in the source system but should never enter the analytics layer.

Because dbt staging models are consumed by multiple downstream marts — and those marts are queried by BI tools and feed automated export pipelines — the PII propagated silently through the entire lineage.

---

## Timeline

| Time | Event |
|------|-------|
| 2023-01 | `raw_customers` schema established with PII columns |
| 2023-02 | `stg_customers` written with `SELECT *` — PII leak introduced |
| 2023-11 | Marketing export pipeline connected to `fct_marketing_reach` |
| 2024-01-31 | First vendor export containing PII sent to vendor_mailchimp |
| 2024-02-07 | Second vendor export sent to vendor_salesforce |
| 2024-02-07 | Security audit flags PII in BI dashboard |
| 2024-02-07 | Incident response begins |

---

## Blast Radius

- **BI exposure**: All users with access to `fct_customer_orders` could see email, phone, ssn_last4
- **Vendor exposure**: 10 records sent to vendor_mailchimp (5 customers) and vendor_salesforce (5 customers)
- **EU residents affected**: Carol Singh (CA), Eva Rossi (IT), Isabel Dupont (FR) — GDPR notification may apply
- **Records with SSN partial**: All 10 exported records

---

## Fix Applied

1. Replaced `SELECT *` in `stg_customers` with explicit safe column list
2. Removed PII column references from `fct_customer_orders` and `fct_marketing_reach`
3. Added `assert_no_pii_in_marts` test to CI pipeline
4. Sent data deletion request to vendor_mailchimp and vendor_salesforce

---

## Prevention

| Control | Description |
|---------|-------------|
| Explicit column selection | No `SELECT *` in staging models — lint rule enforced in CI |
| PII column registry | `src_acme.yml` marks PII columns; reviewers check downstream usage |
| CI gate | `assert_no_pii_in_marts.sql` test runs on every PR; blocks merge if PII detected |
| Column-level access control | BI tool permissions restrict PII columns to data platform team only |
| Export pipeline review | All new export destinations require data classification sign-off |

---

## Key Learning

> **Detection came from outside, not inside.** A security audit caught what the data team's own tests missed. The fix is: treat PII as a first-class concern in staging — classify it at source, test for it at mart boundaries, and gate exports with explicit data classification review.
