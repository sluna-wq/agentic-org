# WT-05 Postmortem: The Fan-Out Bug

## Incident Summary

| Field | Detail |
|-------|--------|
| **Symptom** | Revenue dashboard showing ~3x actual revenue; query running slowly |
| **Root cause** | `stg_orders` joined `raw_order_items` inside staging, creating a fan-out |
| **Impact** | `fct_revenue_daily` and `fct_orders` both serving inflated numbers |
| **Time to detect** | ~2 hours (reported by finance asking why revenue tripled) |
| **Time to fix** | ~30 min once root cause identified |
| **Prevented recurrence?** | Yes — grain test added to stg_orders |

---

## Timeline

| Time | Event |
|------|-------|
| T+0 | Finance analyst notices revenue dashboard shows $X, finance system shows $X/3 |
| T+15 | Analyst pings data team: "did something change?" |
| T+45 | Data team begins investigation — checks for recent deploys |
| T+60 | Identifies `stg_orders` as suspect (recent PR added order_items enrichment) |
| T+80 | Root cause confirmed: join in staging model, fan-out on line items |
| T+95 | Fix deployed: stg_orders cleaned, stg_order_items extracted, fct models updated |
| T+110 | Verification queries pass, dashboard shows correct numbers |

---

## What Happened

A developer added order item detail (quantity, unit_price) to `stg_orders` to power a new feature. They joined `raw_order_items` directly inside the staging model. Because orders can have multiple line items, this turned a 1-row-per-order model into a 1-row-per-line-item model.

The downstream aggregation models (`fct_revenue_daily`, `fct_orders`) didn't know the grain had changed. They continued summing `amount` — now appearing once per line item instead of once per order — producing inflated totals.

The query also got slower because the staging model was now materially larger.

---

## Root Cause

**Wrong location for a join.** Staging models should be thin wrappers: one source table → one clean model. No joins. No aggregations. This is a grain discipline failure.

The right place for enrichment:
- Line item totals → aggregate in `stg_order_items`, join the result (already aggregated to order grain) in the mart
- Per-order enrichment → intermediate model or mart, after establishing correct grain

---

## Changes Made

### Immediate (in this fix)
- [ ] `stg_orders`: removed join, one row per order, clean columns only
- [ ] `stg_order_items`: new staging model, one row per line item, `line_total` computed
- [ ] `fct_orders`: updated to join from `stg_order_items` aggregated to order level
- [ ] `fct_revenue_daily`: no change needed — self-healed once stg_orders was fixed
- [ ] Grain test added: `assert_stg_orders_grain.sql`

### Process (this sprint)
- [ ] Add PR checklist item: "Does this model maintain the expected grain? Document it in the model YAML."
- [ ] Add model YAML field: `grain: one row per [X]` — make it explicit
- [ ] Staging model convention: staging models never join across sources

### Tooling (next quarter)
- [ ] Automated grain monitoring: detect when a model's distinct key count diverges from row count
- [ ] Lineage alert: flag when a staging model is joined inside another staging model
- [ ] Revenue reconciliation check: daily job cross-checking fct_revenue_daily vs raw_orders

---

## What Went Well

- Finance caught the anomaly quickly (2 hours)
- Root cause was traceable through dbt lineage
- Fix was self-propagating — upstream fix healed downstream models

## What Could Be Better

- Staging model grain should be tested, not just documented
- PRs that change staging model structure should trigger a grain check in CI
- "Slow query" was actually a symptom of "more rows" — monitoring should track row count trends, not just query runtime

---

## Agent Perspective

**What an agent could have caught:**
- Grain test failure immediately after merge: `count(*) != count(distinct order_id)` in stg_orders
- Anomaly detection on fct_revenue_daily: 3x revenue jump on a daily basis → automatic alert
- Lineage analysis: detected join of `raw_order_items` inside a staging model → flagged as pattern violation
- Blast radius: automatically identified that stg_orders feeds 2 mart models and 3 dashboards

**What needed human judgment:**
- Is this worth reverting the PR vs patching forward?
- Do we want to keep line-item detail in fct_orders or not?
- What's the right grain for "orders" in this business context?
- Communication to finance (how do we explain the historical data discrepancy?)

**Form factor implication:**
This is a great agent-copilot scenario. Agent runs the investigation queries in real time, surfaces the grain mismatch, proposes the fix — human reviews and decides on the data model direction. Human stays in control of the business logic decisions; agent handles the mechanical investigation.
