# WT-04 Postmortem Template: The Schema Migration Incident

> Use this after you've fixed the incident. Fill it in, then share with the backend team.
> The goal isn't blame — it's making sure this doesn't happen again.

---

## Incident Summary

**Date**: 2026-02-17
**Duration**: ___ minutes of dark dashboards
**Impact**: 8 dbt models failed, 15 dashboards blank, 2 customer calls at risk
**Root cause**: Upstream schema change (users→accounts rename, address field split) deployed without data team notification
**Resolution**: Backward-compatible staging layer update, ~___ minutes to fix

---

## Timeline

| Time | Event |
|------|-------|
| 14:00 (est.) | Backend deployment: `accounts` migration ships to production |
| 14:47 | dbt scheduled run fails — 8 models, 23 tests errored |
| 14:47 | Automated Slack alert fires in #data-alerts |
| 14:48 | VP Sales reports blank dashboard |
| 14:49 | Marcus (backend) posts heads-up in Slack (after the fact) |
| 14:51 | Sarah (VP Sales): customer call in 2 hours |
| 14:52 | You: "on it" |
| ___  | Fix deployed, dashboards restored |
| ___  | Verified: all models green, revenue totals match |

**Detection latency**: 47 minutes (deploy → dbt failure alert)
**Notification latency**: 49 minutes (deploy → we found out)
**Actual discovery**: simultaneous — dbt alert and Slack message arrived at the same time

---

## What Happened

The backend team migrated the `users` table to `accounts` as part of a planned refactor:
- Renamed table: `users` → `accounts`
- Renamed PK: `user_id` → `account_id`
- Split field: `address` (single string) → `street`, `city`, `state_code`, `postal_code`
- Renamed column: `customer_segment` → `account_tier` (with value rename: premium→gold, etc.)
- Renamed column: `country` → `country_code`

The backend team considered this "backwards compatible" — the application layer had been updated before deploy, and no app functionality broke.

However, the data team was not part of the blast radius analysis. The dbt models reference raw source tables directly via the `raw_customers` source definition. When the table was dropped and recreated as `raw_accounts`, 8 models that depended on `stg_customers` started failing.

---

## Why It Happened

**Root cause: No contract between app schema and data pipeline**

The backend team's mental model of "backwards compatible" was limited to the application layer. The data pipeline's dependency on raw schema was invisible to them.

Contributing factors:
1. No schema change notification process existed
2. Data team wasn't in the backend team's deployment review
3. No automated schema drift detection in staging
4. No pre-deploy validation that would catch `raw_customers` disappearing

---

## What We're Changing

### Immediate (this week)

- [ ] **Schema contract test**: Add `assert_schema_contract.sql` test that validates `raw_accounts` has expected columns. Fails loudly if columns are missing or renamed again.
- [ ] **Source documentation**: Add column-level tests in `src_acme.yml` for `raw_accounts` (not_null, unique, accepted_values for account_tier).
- [ ] **Runbook**: Document this incident pattern in the team runbook — "staging as blast shield, backward-compat migration."

### Process (this month)

- [ ] **Pre-deploy checklist**: Backend team adds "does any data pipeline depend on tables being modified?" to their PR template.
- [ ] **Slack notification**: Backend team posts in #data-team before any raw table schema change. 48-hour heads up = we can prepare a migration in advance.
- [ ] **Data team in schema review**: Add data engineer to backend team's RFC review for any DB schema changes.

### Tooling (next quarter)

- [ ] **Schema drift monitoring**: Automated job that diffs raw source schema against registered sources in `src_acme.yml`. Alerts before next run fails.
- [ ] **Staging environment parity**: Test schema migrations in staging (with dbt models) before production deploy.

---

## What Went Well

- dbt's DAG made blast radius analysis fast — one CLI command showed all affected models
- Staging layer pattern worked perfectly: fixing one file (`stg_customers.sql`) healed 8 downstream models
- Fix was clean and backward-compatible — no downstream models needed changes
- Alert fired within minutes of failure (though the failure happened 47 min after deploy)

---

## What We'd Do Differently

- **Before the incident**: schema drift monitoring would catch this before `dbt run` fails
- **During the incident**: having the fix template pre-built (backward-compat staging) would have cut fix time in half
- **After the incident**: this postmortem + process changes prevent recurrence

---

## The Agent DE Question

> If an agent had been monitoring your pipeline, what could it have done?

**Could have detected automatically:**
- Schema diff alert: `raw_accounts` appeared, `raw_customers` disappeared — flag immediately
- Column diff: `account_id` in new table vs `customer_id` in source definition — mismatch detected
- Value diff in `account_tier`: new values not in accepted_values test — would have flagged

**Could have drafted automatically:**
- New `src_acme.yml` entry for `raw_accounts`
- Backward-compatible `stg_customers.sql` with column mapping
- This postmortem template (it can recognize the pattern)

**Would still need you for:**
- Confirming the tier value mapping is semantically correct (business meaning, not just pattern)
- Deciding whether to keep/drop `raw_customers` reference
- The conversation with the backend team about process change
- Approving the fix before deploying to production

**Time savings estimate**: Detection + draft fix in ~2 minutes vs 47 minutes to detect + ___ minutes to fix manually.

---

*Template by CTO-Agent, Cycle #17. Fill in your actuals when you run WT-04.*
