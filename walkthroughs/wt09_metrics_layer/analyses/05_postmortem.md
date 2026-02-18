# WT-09 Postmortem: Three MRRs, One Board Presentation

**Date**: 2025-12-18
**Severity**: High — board presentation delayed 90 minutes; CFO manual reconciliation required
**Detection**: CEO Slack message two hours before board meeting ("Finance says $1.2M, Sales says $1.4M, Marketing says $1.1M — which is right?")

---

## What Happened

The CEO was preparing a board presentation and pulled the current MRR figure. Three different teams provided three different numbers from three different dashboards, all claiming to show "MRR." Finance reported $1,200,000. Sales reported $1,400,000. Marketing reported $1,100,000. None of the teams had flagged a discrepancy — each believed their number was correct.

The board meeting was rescheduled. The CFO spent 90 minutes manually reconciling the three figures against raw billing records. The final board-ready number ($1,260,000) was produced from a scratch SQL query rather than any existing model.

---

## Root Cause

Metric fragmentation. Three teams independently encoded three different business definitions into SQL over 18 months, with no shared canonical definition and no cross-team review.

The three models diverged on four independent axes:

| Decision point | Finance | Sales | Marketing | Canonical |
|---|---|---|---|---|
| Date basis | Invoice date | Contract start date | Payment date | Invoice date (accrual) |
| Revenue type | All invoice types incl. setup | Contract ARR | Cash receipts incl. pro services | Subscription only |
| Contract filter | All paid invoices | Active + pilot | All payments | Active recurring only |
| Pilot treatment | Included | Included | N/A | Excluded |

None of the three models was wrong in an absolute sense — each answered a slightly different question. The problem was that all three were labeled and used as "MRR," as if they were interchangeable.

---

## Contributing Factors

**No metrics governance.** There was no process requiring new revenue metrics to be reviewed against an existing definition. Any team could build and name a model `fct_*_revenue` without coordination.

**Contractor-built model with no handoff.** The Sales RevOps metric (`fct_arr_by_account`) was built by an external contractor during a Salesforce integration. The contractor left without documenting the business decisions encoded in the SQL. The pilot inclusion logic was traced to a single comment ("per Mike's request") — Mike left the company six months prior.

**Growth team built in isolation.** Marketing's metric was built during a paid acquisition analysis and was never intended to be the authoritative MRR figure. It was adopted as such because it was the only model that included the payment data the growth team was already querying.

**Definitions were in SQL, not in documents.** Business decisions (what counts as MRR) were expressed as SQL filters, not written down anywhere. When assumptions drifted, there was no document to check against.

---

## Impact

- Board presentation delayed 90 minutes
- CFO produced the board number manually from a scratch query — no audit trail
- Data team credibility with Finance and executive leadership damaged
- Three legacy models remain in production queried by downstream dashboards that still show the wrong numbers

---

## Resolution

1. Built `fct_mrr_canonical` with the agreed definition: accrual basis (invoice_date), subscription invoices only, active recurring contracts only, paid status only.
2. Finance, Sales, and Marketing redirected to `fct_mrr_canonical` as the single source of truth.
3. Three legacy models (`fct_revenue_monthly`, `fct_arr_by_account`, `fct_marketing_revenue`) marked `-- DEPRECATED: use fct_mrr_canonical` and scheduled for removal in the next sprint.
4. Board number confirmed: $1,260,000 MRR for December 2025.

---

## Prevention

**Metrics governance process.** All new metrics models require review by Finance before merging. Review checklist: What business question does this answer? How does it differ from existing metrics? Who owns the definition?

**Business definitions in schema YAML, not just SQL.** The canonical MRR definition is now documented in `schema.yml` as model-level and column-level descriptions. The definition is the source of truth; the SQL is the implementation.

**Test-encoded contracts.** Three dbt tests now encode the agreed definition as executable contracts: `assert_mrr_no_pilots`, `assert_mrr_no_one_time`, `assert_mrr_matches_finance`. Any future drift from the canonical definition will surface as a CI failure before it reaches a dashboard.

**Deprecation policy.** Models that have been superseded must be removed within two sprints. Deprecated models that remain in production are a future divergence waiting to happen.

---

## Agent Lens

This incident is the canonical use case for a data agent. The technical work — tracing each model back to its assumptions, quantifying the dollar impact of each divergence point, proposing a canonical definition with SaaS industry precedent, building the unified model, and generating tests that encode the agreed contract — took the agent under an hour. A human DE doing the same work navigates org politics, chases down the contractor's original intent, and produces a reconciliation table over two to three days.

The one step the agent cannot compress: getting Finance, Sales, and Marketing to agree on a single definition. That required a human with authority. The agent's role is to arrive at that meeting with a fully-analyzed proposal and a draft model ready to ship on approval — so the human's decision is yes or no, not where do we even start.

---

## Lessons

- Three models with the same name are not the same metric.
- Business definitions belong in documents, not SQL comments.
- A metrics layer is not a technical artifact — it is a governance artifact that happens to be implemented in SQL.
- Test the definition, not just the schema.
