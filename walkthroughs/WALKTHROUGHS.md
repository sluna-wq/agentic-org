# Data Engineering Walkthroughs

> 10 hands-on scenarios. Each one teaches different skills.
> Each builds on the previous. All run locally with DuckDB.
> Designed so you feel what a data engineer feels.

## Setup
All walkthroughs use the same environment:
```
~/Desktop/claude/de-playground/
├── .venv/                    ← Python environment (dbt + duckdb)
├── acme_analytics/           ← Walkthrough 1 (base project)
└── walkthrough-NN/           ← Each subsequent walkthrough
```

Activate before any walkthrough:
```bash
cd ~/Desktop/claude/de-playground
source .venv/bin/activate
```

---

## WT-01: "The Data You Inherit" ✅ DONE
**You are**: New data engineer, day 1 at Acme Corp
**The scenario**: Previous DE left. CEO wants a dashboard by Friday.
**What you learn**:
- What dbt is and why it exists (ETL/ELT)
- Seeds, staging, intermediate, mart layers
- What `dbt run` and `dbt test` actually do
- The manifest and dependency graph
- Why "tests pass" means nothing with 4 tests on 10 models
- NULL semantics bugs, multi-currency mixing, duplicate customers
- How to investigate data quality issues with SQL

**Key takeaway**: Passing tests ≠ correct data. Coverage matters.

---

## WT-02: "The Dashboard Is Wrong"
**You are**: On-call data engineer. It's 9 AM Monday.
**The scenario**: VP of Sales messages Slack: "Revenue on the Looker dashboard doesn't match what I exported from Stripe. Off by like 40%. Board meeting is Wednesday."
**What you learn**:
- How to triage a data issue (don't panic, reproduce first)
- Tracing a number from dashboard → mart → intermediate → staging → raw
- Revenue reconciliation (orders vs payments vs billing system)
- How timezone bugs cause data to shift between days
- Writing a reconciliation test that would have caught this
- How to communicate findings to non-technical stakeholders

**Key skills**: Investigation methodology, reconciliation, stakeholder communication

---

## WT-03: "New Data Source Onboarding"
**You are**: Data engineer asked to integrate a new system
**The scenario**: Marketing just bought HubSpot. They want campaign performance data in the warehouse alongside order data so they can see CAC (customer acquisition cost) by channel.
**What you learn**:
- How source data arrives (Fivetran/Airbyte concepts)
- Designing staging models for a new source
- Schema design decisions (normalize? denormalize? SCD type 2?)
- Joining across source systems (matching HubSpot contacts to customers)
- The "entity resolution" problem (fuzzy matching on email/name)
- Building a mart that blends marketing + revenue data

**Key skills**: Source integration, schema design, cross-system joins

---

## WT-04: "The Schema Migration"
**You are**: Data engineer. Backend team just deployed.
**The scenario**: The app team renamed `users` to `accounts` and split `address` into `street`, `city`, `state`, `zip`. Your models just broke. 15 downstream dashboards are showing errors.
**What you learn**:
- How upstream schema changes propagate through dbt
- The blast radius of a column rename
- Using `dbt ls --select +model_name` to find downstream impact
- Writing backward-compatible staging models
- Source freshness tests and schema change detection
- The "contract" between app team and data team

**Key skills**: Change management, impact analysis, backward compatibility

---

## WT-05: "Why Is This Query So Slow?"
**You are**: Data engineer. Analytics team is complaining.
**The scenario**: A critical daily report that used to take 2 minutes now takes 45 minutes. The warehouse bill tripled last month. Nobody changed anything (they think).
**What you learn**:
- Reading query execution plans (EXPLAIN)
- Table scans vs index/partition usage
- Materialization strategy (view vs table vs incremental)
- How a single `SELECT *` in staging can cascade into massive warehouse costs
- Incremental models — the most important dbt concept for scale
- Warehouse cost optimization

**Key skills**: Performance debugging, materialization, cost control

---

## WT-06: "The Data Is Stale"
**You are**: Data engineer. It's 10 AM and dashboards show yesterday's data.
**The scenario**: The Fivetran sync failed at 3 AM. Nobody noticed until the CEO asked why the numbers look the same as yesterday. There are no alerts.
**What you learn**:
- Source freshness testing (`loaded_at` fields)
- Building observability (what should be monitored?)
- dbt source freshness commands
- Alerting strategies (Slack, PagerDuty, email)
- SLA definitions (how fresh does data need to be?)
- Incident response for data pipelines

**Key skills**: Observability, freshness, alerting, incident response

---

## WT-07: "PII Everywhere"
**You are**: Data engineer. Security team just did an audit.
**The scenario**: Legal says GDPR applies now because you have EU customers. The security audit found: raw email addresses in 4 mart tables, full names in analytics schemas, IP addresses in web events. You have 30 days to fix it.
**What you learn**:
- PII identification and classification
- Column-level masking and hashing strategies
- Row-level access control concepts
- dbt column tags and meta fields
- Building a PII-safe analytics layer
- "Right to be forgotten" implementation (DELETE requests)

**Key skills**: Data governance, PII handling, compliance

---

## WT-08: "The Duplicate Problem"
**You are**: Data engineer. Finance is panicking.
**The scenario**: Someone noticed that customer "Michael Chen" appears twice in the customer dimension. Revenue is double-counted for his orders. How many more duplicates are there? How much revenue is wrong?
**What you learn**:
- Entity resolution / deduplication strategies
- Fuzzy matching (Levenshtein distance, Jaro-Winkler)
- Deterministic vs probabilistic matching
- Surrogate keys vs natural keys
- Building a deduplication model
- Quantifying the business impact of duplicates

**Key skills**: Deduplication, entity resolution, data quality quantification

---

## WT-09: "Building the Metrics Layer"
**You are**: Data engineer. The company is scaling.
**The scenario**: Marketing, Sales, and Finance each calculate "revenue" differently. Marketing includes refunded orders. Sales excludes tax. Finance includes tax but excludes shipping. The board deck has three different revenue numbers. CEO is livid.
**What you learn**:
- The metrics layer concept (dbt metrics / MetricFlow)
- Single source of truth for business metrics
- Metric definitions as code
- Dimensional modeling (Kimball methodology basics)
- Building consensus across teams on metric definitions
- The "one metric, many slices" pattern

**Key skills**: Metrics layer, dimensional modeling, business alignment

---

## WT-10: "The Autonomous Agent"
**You are**: Data engineer who's tired of being on-call.
**The scenario**: You've done walkthroughs 1-9. You've seen every type of data issue. Now you want to build an agent that handles 80% of these investigations automatically. What does it need to know? What does it need access to? How does it escalate?
**What you learn**:
- Designing an agent's knowledge base from your experience
- What patterns are automatable vs need human judgment
- Building investigation playbooks (the agent's "runbook")
- Tool design: what MCP servers / tools the agent needs
- Trust boundaries: what can it fix vs what it should flag
- The feedback loop: how the agent gets smarter over time

**Key skills**: Agent design, automation boundaries, operational AI

---

## Progress Tracker
| # | Walkthrough | Status | Date |
|---|------------|--------|------|
| 1 | The Data You Inherit | ✅ Done | 2026-02-16 |
| 2 | The Dashboard Is Wrong | ✅ Done | 2026-02-17 |
| 3 | New Data Source Onboarding | ✅ Done | 2026-02-17 |
| 4 | The Schema Migration | ⬜ | |
| 5 | Why Is This Query So Slow? | ⬜ | |
| 6 | The Data Is Stale | ⬜ | |
| 7 | PII Everywhere | ⬜ | |
| 8 | The Duplicate Problem | ⬜ | |
| 9 | Building the Metrics Layer | ⬜ | |
| 10 | The Autonomous Agent | ⬜ | |
