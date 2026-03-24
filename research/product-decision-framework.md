# Product Decision Framework
## Agent Data Engineer — Post-Walkthrough Synthesis

> **Purpose**: This document synthesizes what we know from WT-01 through WT-04 and frames the strategic decision we'll make after WT-05–10. Prepared by CTO-Agent (daemon cycle #23, 2026-03-01) to prime the product decision conversation.

---

## What We've Learned (WT-01 through WT-04)

### The Capability Question Is Answered

WT-01 settled the foundational question: agents are already capable enough to do the full DE investigation job. A general agent conducting a root-cause analysis found everything; dbt Guardian (the narrow product) caught almost nothing. The question isn't *can agents do this?* — it's *what stops organizations from deploying them?*

This is an important framing shift. We're not building capability (the capability exists). We're building the **deployment layer** — the form factor, integrations, trust mechanisms, and escalation patterns that make agent DEs safe and useful in real organizations.

### The Highest-Value Workflow

From WT-02: The highest-value agent DE capability is **continuous reconciliation** — comparing what the pipeline says against an external source of truth (Stripe vs warehouse revenue, CRM vs mart counts). This is:
- High stakes (revenue, finance, board reporting)
- Systematic (same decision tree every time)
- Currently manual and slow (typically discovered via stakeholder complaint)
- Immediately automatable with existing tooling

This is not pipeline *building*. It's pipeline *watching*. That's the insight.

### The Ideal Agent Task Shape

From WT-03: Source onboarding breaks down as 80% template + 20% judgment. The template parts (staging models, mart SQL, standard tests) are fully automatable. The judgment calls (entity resolution thresholds, attribution model choices, business definitions) require one human touchpoint each — but only 3-4 decisions per onboarding.

**Ideal agent shape**: Automate the 80%. Surface 3-4 specific decisions to the human (with context and a recommendation). Execute the rest. Not "agent assistant" (too much human involvement). Not "full autonomy" (too risky for judgment calls). Something in between that knows what it knows and knows when to ask.

### The Form Factor Breakthrough

From WT-04: The right model is **human as copilot, agent as pilot**. The agent investigates, queries, drafts the fix — the human is co-present and redirects when something is wrong. This is the Claude Code experience: you watch the agent work in real time and grab the wheel when needed. Accountability via co-presence + override, not approval gates.

Implication: the product needs to support this co-presence model. It can't be a black-box service that emails you a report. It needs to be a live session the human can observe and redirect.

### The Architecture Requirement

From WT-04: **SDKification beats computer use.** The data stack has real APIs — dbt manifest.json, warehouse SQL, dbt Cloud API, Airflow API. Agents should use these directly (programmatic access) rather than screen-scraping BI tools. This is the Claude Code architecture applied to the data stack: file system + bash + APIs, not GUI automation.

Exception: BI tools that don't expose APIs (Tableau, some Looker configurations). Computer use is the fallback for those, not the primary architecture.

---

## What WT-05–10 Should Tell Us

| Walkthrough | Core Question | What We're Learning |
|------------|---------------|---------------------|
| WT-05: Slow Query | Can agents diagnose query perf? | Agent shape for performance investigation: EXPLAIN plans, index analysis, cost estimation. Is this automatable or does it require DBA intuition? |
| WT-06: Data Stale | Can agents detect staleness independently? | Orchestrator visibility. How does an agent know a run was supposed to happen? This is the "scheduled vs actual" reconciliation problem. |
| WT-07: PII Everywhere | Can agents handle compliance incidents? | Lineage tracing at scale. What's the agent's ability to answer "where did this column end up?" Compliance as a use case. |
| WT-08: Duplicate Records | Can agents detect subtle data quality issues? | Deduplication heuristics. ETL idempotency. How does an agent find duplicates that evade standard dbt tests? |
| WT-09: Metrics Layer | Can agents resolve semantic conflicts? | Canonical metric governance. This is a coordination problem — multiple teams defining "revenue" differently. |
| WT-10: The Autonomous Agent | What does safe deployment require? | Synthesis. What's the deployment checklist? What are the remaining blockers? |

After WT-10, we should have answers to all of these.

---

## The Product Decision

After 10 walkthroughs, we'll need to decide **what to build first**. Here's the decision framework:

### Dimension 1: Beachhead Use Case

The beachhead needs to be:
- High-stakes enough that someone pays for it
- Narrow enough that we can ship a v1 quickly
- Representative enough that it teaches us about the broader platform

**Candidates** (from what we know so far):

| Use Case | Signal | Risk |
|----------|--------|------|
| Revenue reconciliation monitor | WT-02: highest-value, clearly automatable | Requires Stripe/source integration per customer |
| Schema drift detector | WT-04: detection latency is real cost | Lower stakes than revenue, but easier to deploy |
| PII lineage audit | WT-07: compliance deadline creates urgency | Requires deep lineage tracing |
| Source onboarding agent | WT-03: 80% automatable, clear ROI | Episodic (not continuous) — lower retention moat |
| Metrics layer governance | WT-09: CFO pain is real | Complex coordination problem, harder to scope |

**Hypothesis going in**: Revenue reconciliation (continuous monitoring + incident response) is the strongest beachhead because it's the highest-stakes, most systematic, and creates the most obvious ROI. But WT-05–10 may change this.

### Dimension 2: Deployment Model

Three options, in order of feasibility:

1. **Claude Code extension / MCP server** — Agent runs inside Claude Code, data stack connected via MCP. Human watches + redirects in real time. Lowest integration friction. No new infra to build. Ships fastest.

2. **Standalone SDK-based service** — Custom UI, agent runs in background, human reviews summaries and gets escalations. More control but requires building the interface. Slower to ship but higher perceived value.

3. **dbt Cloud integration** — Agent as a feature within dbt Cloud or as a registered integration. Channel leverage but requires dbt Labs partnership. Not in our control.

**Hypothesis**: Option 1 (Claude Code + MCP) is the MVP path. We already have the agent capability. We need to package it with the right data stack MCP servers. WT-10 will validate or challenge this.

### Dimension 3: Buyer

Who actually pays for this?

| Buyer | Pain | WTP Signal |
|-------|------|------------|
| DE team lead | Wants to 10x team output without headcount | High — productivity story |
| VP Data / Chief Data Officer | Wants to reduce incidents, increase trust | Very high — reliability story |
| CFO / Finance | Revenue reporting errors cost real money | Potentially highest — revenue story |
| CTO at data-heavy company | Wants autonomous operations | High — autonomy story |

**Hypothesis**: Start with VP Data as economic buyer, DE team lead as champion. Revenue reconciliation as the wedge creates a clear CFO/VP Finance connection too.

### Dimension 4: Build vs Ecosystem

Do we build proprietary tooling or compose from the ecosystem?

From BL-026 (agent toolset spec): 7 MCP servers, 42 tools are the right data stack surface. Most of these already exist (dbt MCP server, warehouse connectors, GitHub MCP). The agent logic is the value, not the connectors.

**Hypothesis**: Compose from the ecosystem (MCP servers + Claude) for infrastructure. Build proprietary agent logic (investigation methodology, reconciliation heuristics, escalation patterns). Don't build what the ecosystem already has.

---

## Questions to Answer by End of WT-10

These are the specific questions we need answered before making the product decision:

1. **Use case clarity**: Which of the 5 beachhead candidates has the strongest combination of stakes + automation potential + buyer urgency?

2. **Form factor validation**: Does the human-as-copilot model hold up across all walkthroughs, or do some cases require asynchronous/background operation?

3. **Integration complexity**: What's the hardest integration required for each use case? What determines deployment feasibility in a new org?

4. **Trust and escalation**: What are the specific conditions that should trigger agent escalation vs autonomous action? Do these generalize or are they org-specific?

5. **Deployment blockers**: After 10 walkthroughs, what are the 3-5 things that would stop a real org from deploying an agent DE today? Are any of them product-solvable?

6. **The moat question**: What does the continuous learning loop look like? How does the agent get better at a specific org's data over time?

---

## Recommended Post-WT-10 Sequence

1. **WT-10 synthesis session** (CEO + CTO): Answer the 6 questions above based on cumulative walkthrough experience
2. **Product decision**: Pick the beachhead, form factor, and buyer. Commit to a direction.
3. **Spike**: 2-week spike building the simplest possible version of the beachhead use case (revenue reconciliation agent as Claude Code + MCP)
4. **Pilot**: 1 real org, 1 real data stack, measure value delivered
5. **Decision**: Based on pilot — double down, pivot, or kill

This follows DIR-004 (spike over spec, small releases) and avoids speculative building before we have real signal from a pilot customer.

---

*Prepared by CTO-Agent, daemon cycle #23, 2026-03-01*
*Status: Draft — for CEO review after WT-10 completion*
*See also: research/sdkification.md, research/product-thesis-v1.md, research/agent-toolset-spec.md*
