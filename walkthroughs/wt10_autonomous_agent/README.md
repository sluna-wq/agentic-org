# WT-10: The Autonomous Agent

**Scenario**: "The Autonomous Agent" — Acme Analytics deploys an AI agent as a full-time data engineer. After 9 walkthroughs, you know every failure mode the data stack produces. This walkthrough asks the design question: what changes when the DE is on 24/7?

**The key learning**: Autonomy is not a capability question — it's a trust architecture question. An agent can already do the work. What determines whether you deploy it is whether you have solved accountability, escalation routing, and the boundary between autonomous action and required human authority. Those are org design problems, not AI problems.

**Estimated Time**: ~60 min (design exercise — no SQL to run)

| Phase | Time | What You're Doing |
|-------|------|-------------------|
| 1. Capability audit | 10 min | Map each WT scenario to: autonomous fix / escalate / human-only |
| 2. Monitor design | 15 min | Design the agent's continuous monitoring loop |
| 3. Escalation routing | 10 min | Design the decision tree for when to act vs. escalate |
| 4. Trust architecture | 15 min | Design accountability, override, and audit trail |
| 5. Deployment design | 10 min | What does "go live" look like? |

---

## The Decision

> **From**: Marcus Webb, VP Engineering
> **To**: Data Team + CTO
> **Subject**: Agent DE — do we do it?
>
> We've run 9 walkthroughs. The agent found every bug. It investigated faster than a human would. It drafted fixes we'd have approved. The question on the table: do we replace the on-call rotation with an autonomous agent for data incidents?
>
> I'm not asking whether it's *capable*. It clearly is. I'm asking whether we'd know what it was doing, whether we could trust its judgment, and who is accountable when it gets something wrong.
>
> Give me a design. Not a pitch — a design.
>
> — Marcus

This is the right question to end on. Not "can the agent do it?" (yes). "What do we need to believe, build, and accept before we let it run?"

---

## Phase 1: Capability Audit

Before designing the deployment, map every failure mode from walkthroughs 1–9 to an autonomous action tier:

| WT | Scenario | Agent Action | Tier | Reasoning |
|----|----------|-------------|------|-----------|
| 1 | Inherited data (audit) | Full audit + report | Auto | No mutation; detection only |
| 2 | Dashboard wrong (revenue bugs) | Detect + draft PR + escalate | Escalate | Mutation of business metric logic |
| 3 | New source onboarding | 80% auto, 20% escalate | Hybrid | Entity resolution + attribution choices are human |
| 4 | Schema migration failure | Detect immediately + auto-fix well-typed nulls, escalate schema semantic changes | Hybrid | Type coercions are safe; semantic column renames need human |
| 5 | Slow query (fan-out bug) | Auto-detect + draft fix + escalate | Escalate | Query plan changes can have downstream effects |
| 6 | Stale data (orchestrator bug) | Auto-detect + page on-call | Escalate | Restarting jobs is safe; diagnosing root cause may need infra access |
| 7 | PII leak | Auto-detect + BLOCK pipeline + escalate immediately | Auto+Block | PII exposure is never a "draft a fix" situation |
| 8 | Duplicate records (ETL) | Auto-detect + quantify impact + escalate | Escalate | Data mutation of financial records requires human sign-off |
| 9 | Metric conflicts | Auto-detect + surface decisions to CFO | Escalate | Semantic authority cannot be automated |

### The Three Tiers

**Tier 1 — Fully Autonomous**: The agent acts, logs, notifies.
- Read-only investigations and audits
- Detection and alerting (always autonomous)
- PII pipeline blocking (security exception: autonomous block, escalate simultaneously)
- Schema drift detection and ticketing

**Tier 2 — Draft + Escalate**: The agent prepares the fix and waits for human approval.
- Any mutation to business logic (metric definitions, filter logic)
- Changes to financial data pipelines
- Schema changes with semantic implications
- Anything that affects data that's been reported externally

**Tier 3 — Human-Only**: The agent surfaces the problem and stops.
- Semantic authority decisions (what does "revenue" mean?)
- Org standing decisions (negotiate process change with another team)
- Any action with legal, compliance, or financial reporting implications
- Changes to source data (upstream systems)

---

## Phase 2: Monitor Design

The agent's continuous loop. This is what replaces the on-call rotation for data incidents.

### The Monitoring Stack

```
Every 5 minutes:
  □ Schema drift check: INFORMATION_SCHEMA vs. last-known-good snapshot
    → Any new/dropped/retyped columns: create incident, classify tier, route

Every 15 minutes:
  □ Freshness check: max(updated_at) for each source table vs. expected cadence
    → Stale beyond 1.5x expected interval: create incident
    → Stale beyond 3x expected interval: page on-call + auto-escalate

Every 30 minutes:
  □ Reconciliation check: pipeline output vs. external source of truth
    → Revenue: compare fct_revenue_monthly to Stripe daily payout
    → Inventory: compare fct_inventory to ERP snapshot
    → Any delta >1%: create incident with quantified impact

Every hour:
  □ Semantic layer integrity: run dbt test suite
    → Any test failure: create incident, classify (structural vs. semantic)
    → Structural failures (null PK, broken reference): Tier 1 auto-draft fix
    → Semantic failures (unexpected row count, reconciliation miss): Tier 2 escalate

Every day:
  □ Lineage audit: trace all columns that touch PII fields through downstream models
    → Any PII reaching non-approved destinations: BLOCK + incident
  □ Metric consistency: check all metric definitions against metrics_canonical.yml
    → Any new model using "revenue" without canonical filter: flag + PR comment
```

### What the Agent Sees

The agent is not watching dashboards. It has direct SDK access to:
- **dbt artifacts**: `manifest.json`, `catalog.json`, `run_results.json` — the full DAG state
- **Warehouse `INFORMATION_SCHEMA`**: real-time schema and freshness
- **`QUERY_HISTORY`**: what queries are running, how long, who's running them
- **dbt Cloud API**: job status, run logs, trigger reruns
- **External sources**: Stripe API, ERP exports, bank reconciliation files

This is the SDKification insight from WT-04: the agent is an SDK orchestrator, not a dashboard watcher. It does not need computer use. It has richer access than a human analyst clicking through a BI tool.

---

## Phase 3: Escalation Routing

The single most important design decision: who does the agent wake up, and for what?

### The Routing Table

| Incident Type | Primary Escalation | Secondary | SLA |
|---------------|-------------------|-----------|-----|
| PII exposure | Privacy Officer + Engineering VP | Legal | Immediate |
| Financial data mutation needed | Finance BP + Data Lead | CFO if >$10K | 2h |
| Pipeline down (data stale) | Data engineer on-call | Engineering VP | 30min |
| Schema drift detected | Data engineer on-call | Data Lead | 4h |
| Metric conflict detected | Data Lead | CFO if board-facing | 24h |
| Query performance degradation | Data engineer on-call | — | 8h |
| Source data anomaly | Source system owner | Data Lead | 4h |

### The Escalation Message Contract

Every escalation includes:
1. **What happened** (1 sentence, plain language)
2. **Dollar/user impact** (quantified, not estimated)
3. **What the agent has already done** (detection, blocking, investigation)
4. **What the agent is waiting for** (the specific decision or action needed)
5. **Recommended action** (with confidence level)
6. **Time to impact** (how long before this gets worse)

Example escalation for WT-08 (duplicate payments):

> **[DATA INCIDENT]** ETL retry duplicates detected in payment pipeline.
>
> Revenue impact: $244,000 overstated in December dashboard (40 duplicate rows across 20 canonical payments). Bank reconciliation confirms $603K; dashboard shows $847K.
>
> Agent has: detected duplicates, quantified impact, traced root cause to ETL retry logic (missing idempotency key), drafted dedup fix in `stg_payments.sql`.
>
> Waiting for: approval to merge dedup logic to production. This will retroactively correct December figures.
>
> Recommended: approve the PR at [link]. High confidence — ROW_NUMBER() dedup on (order_id, amount, customer_id) with 10-second window eliminates all 20 duplicate pairs, zero false positives confirmed on test data.
>
> Time to impact: Monthly close is in 48 hours. Correction before close avoids restating figures post-close.

This is the format from the agent lens in WT-02 through WT-09 operationalized. The human reads one message, makes one decision.

---

## Phase 4: Trust Architecture

The hardest design problem. Not "can the agent do the work?" but "how do we know what it did, why it did it, and what to do when it's wrong?"

### Four Trust Requirements

**1. Complete audit trail — every action logged**

The agent writes a structured event to a dedicated audit log for every action it takes:
```
{
  "timestamp": "2026-01-15T09:23:41Z",
  "incident_id": "INC-2026-0115-003",
  "action": "blocked_pipeline",
  "trigger": "PII column email found in vendor_exports model (WT-07 pattern)",
  "tier": 1,
  "reversible": true,
  "reversal_command": "dbt run --select vendor_exports --vars '{pii_block: false}'",
  "notified": ["privacy@acme.com", "data-lead@acme.com"]
}
```

Every Tier 1 action is logged. Every Tier 2 draft is logged with the PR link. Every Tier 3 escalation is logged with the routing decision.

**2. Override is always one action away**

For every Tier 1 action the agent takes autonomously, there is a single command to undo it. The reversal command is in the audit log entry. The on-call engineer who wakes up at 2am and disagrees with what the agent did can undo it in 30 seconds.

If the reversal command is not one action, the agent should not have acted autonomously.

**3. Accountability is on the human who set the tier**

When the agent acts in Tier 1 and gets it wrong, the question is not "why did the agent do that?" The question is "why was this action classified as Tier 1?" The human who classified the action tier is accountable for the consequences of autonomous action.

This is the accountability model: tier classification is the locus of human judgment. Acting within a tier is the agent's job. Misclassified tiers surface through incidents and should trigger tier reclassification.

**4. Trust is earned incrementally**

Start with read-only. Prove the monitoring loop catches what it should. Then enable Tier 1 blocking actions. Run for 30 days. Review every incident. Upgrade Tier 2 draft-and-escalate to Tier 1 autonomous for actions that humans approve >95% of the time within 15 minutes.

Trust expansion is a data problem: you have enough data to make a Tier 2 action Tier 1 when the approval rate and approval speed both exceed the threshold for your risk tolerance.

### The "Wrong Call" Protocol

When the agent gets something wrong — and it will — the protocol is:
1. **Undo** via the reversal command (logged in audit trail)
2. **Document** what happened: what the agent saw, what it did, why it was wrong
3. **Classify root cause**: wrong tier assignment, bad detection logic, missing context
4. **Fix forward**: update tier table, detection logic, or escalation routing
5. **Do not retrain or punish** — the agent's capability isn't the problem. The trust architecture is.

This protocol treats agent errors as org design failures, not AI failures. That is the correct framing.

---

## Phase 5: Deployment Design

### Week 0: Read-Only Shadow Mode

Deploy the monitoring loop in read-only mode. Every incident the agent *would* create is logged but no actions are taken. Run for 1 week. Compare agent detections to actual incidents reported by humans. Answer:
- What did the agent catch that humans missed?
- What did the agent flag as an incident that humans would not have?
- What did humans catch that the agent missed?

This is the calibration baseline. You cannot design the tier table without it.

### Week 1: Detection + Alerting Only

Enable Tier 1 detection and alerting. The agent pages humans; humans act. The agent does not block, draft, or escalate to CFO. This proves the alerting channel works, the escalation routing is correct, and the SLAs are achievable.

### Week 2-4: Tier 1 Autonomous + Tier 2 Draft

Enable autonomous Tier 1 actions (blocking PII pipelines, schema drift ticketing). Enable Tier 2 draft-and-escalate. Track approval rates and times. At the end of Week 4, review the tier table:
- Any Tier 2 action approved >95% of the time in <15 minutes → promote to Tier 1
- Any Tier 1 action that triggered reversals → demote to Tier 2

### Month 2+: Steady State + Continuous Tier Review

Monthly review of the tier table using incident data. Trust expands or contracts based on performance, not instinct.

### What "Going Live" Actually Means

"Going live" with an autonomous agent DE does not mean firing the data team. It means:
- The on-call rotation shrinks (agent handles Tier 1, humans handle Tier 2+)
- The data team shifts from incident response to trust architecture: designing tiers, reviewing escalations, expanding autonomous scope
- The data team develops a new skill: reading agent audit logs and improving the detection logic

The org's total data engineering capacity increases. The human role shifts from execution to judgment.

---

## Agent Lens

This walkthrough synthesizes every agent lens from WT-01 through WT-09.

### What the 9 Walkthroughs Proved

| WT | What the Agent Demonstrated |
|----|---------------------------|
| 1 | General investigation beats narrow product. Detection is the value. |
| 2 | Continuous reconciliation catches what tests miss. The pattern is automatable. |
| 3 | 80% of DE work is template execution. 20% requires human judgment. |
| 4 | Detection latency is the real cost. Schema drift polling collapses it. |
| 5 | Query plan analysis is fully automatable. Root cause is mechanical. |
| 6 | Freshness monitoring + orchestrator log analysis is a decision tree, not intuition. |
| 7 | PII detection + lineage tracing is deterministic. Blocking should be automatic. |
| 8 | Semantic uniqueness testing requires understanding business intent. Tests must check intent, not structure. |
| 9 | Semantic conflict detection is fully automatable. Semantic authority is irreducibly human. |

The pattern across 9 walkthroughs:
- **Detection**: fully automatable in every scenario
- **Investigation**: automatable (decision tree, not intuition)
- **Fix preparation**: automatable (draft PR, draft SQL, draft escalation memo)
- **Execution of technical fix**: automatable for well-defined cases
- **Semantic decisions**: irreducibly human
- **Org standing decisions**: irreducibly human

### The Real Product Question

The walkthroughs answered "can agents do DE work?" The answer is yes.

The remaining question — the product question — is: **what is the minimal infrastructure a company needs to deploy an agent DE with confidence?**

Based on the 9 walkthroughs, the answer has four components:

**1. The monitoring layer** (WT-02, WT-04, WT-06)
Continuous reconciliation + schema drift detection + freshness monitoring. This is the detection layer. Without it, the agent is reactive (waits for a human to file a ticket). With it, the agent is proactive (detects before anyone notices).

**2. The toolset** (WT-01, WT-03, WT-05, WT-07)
42 tools across 7 SDK surfaces (dbt artifacts, warehouse SQL, dbt Cloud API, orchestrator API, BI API, dbt filesystem, computer use fallback). The toolset is bounded and buildable. This was fully specified in BL-026 (research/agent-toolset-spec.md).

**3. The trust architecture** (WT-08, WT-09, WT-10)
Tier classification, escalation routing, audit trail, override mechanism. This is the org design layer. It determines what the agent is allowed to do autonomously and what requires human sign-off.

**4. The escalation interface** (WT-02, WT-09)
How the agent communicates with humans. The format: what happened, dollar impact, what agent did, what human must decide, recommendation, time to impact. This format is the product.

A company that has all four components can deploy an agent DE with confidence. A company missing any one of them will either over-constrain the agent (manual approval for everything) or under-constrain it (autonomous action without accountability).

### The Irreducible Boundary

Across all 10 walkthroughs, the human role reduces to three categories:

**Semantic authority** — deciding what business terms mean for reporting purposes (WT-09). Cannot be automated because it requires legal/fiduciary standing and organizational accountability.

**Org standing** — decisions that require relationships and authority within the organization (WT-03, WT-04). The agent can identify that a process needs to change; it cannot force the upstream team to change it.

**Trust architecture maintenance** — reviewing the tier table, expanding autonomous scope, approving new actions. This is the meta-level work: the humans who set the boundaries within which the agent operates.

Everything else is agent-executable.

### The Answer to Marcus's Question

> "I'm asking whether we'd know what it was doing, whether we could trust its judgment, and who is accountable when it gets something wrong."

The answer:

**Would we know what it's doing?** Yes — complete audit trail, every action logged with trigger, reasoning, and reversal command.

**Would we trust its judgment?** Trust is not binary. You trust it within the tier boundaries you've set. The tier boundaries are your trust boundary. Expand them as performance earns it.

**Who is accountable when it gets something wrong?** The human who classified the action as Tier 1. Tier classification is the locus of human judgment. If you're not prepared to own the consequences of a tier classification, classify it as Tier 2.

The org that can answer these three questions clearly is ready to deploy. The org that cannot answer them is not ready — and no amount of AI capability changes that.

---

## Key Takeaway

Deploying an autonomous agent DE is not primarily a capability problem. The capability exists.

It is a trust architecture problem: can you define what the agent is authorized to do, track what it does, override it when needed, and expand its authority as it earns trust?

The orgs that deploy agent DEs successfully will be the ones that treat this as an org design challenge first and a technology challenge second.

The agent is ready. The question is whether the org is.

> The capability gap is closed. The trust gap is the work.
