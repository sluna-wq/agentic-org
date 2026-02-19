# Product Thesis v1: The Agent Data Engineer

**Version:** 1.0
**Date:** 2026-02-19
**Status:** Hypothesis — validated against WT-01-04, open questions remain for WT-05-10
**Authors:** CEO + CTO-Agent

---

## What We Set Out to Learn

In late 2025, this org was building dbt Guardian — a test generator for dbt projects. The premise: data engineers spend too much time writing dbt tests, an agent could automate that. We shipped it. It caught almost nothing.

That failure prompted a sharper question: if capability isn't the barrier, what is? We'd run the same LLM as a general DE investigator — no product constraints, just "go figure out what's wrong with this pipeline" — and it found everything dbt Guardian missed. Not because it was smarter. Because it wasn't constrained to one narrow task.

So we pivoted. Instead of building another narrow product, we ran walkthroughs. Ten scenarios covering the full operational surface of a data engineering role: inherited data, broken dashboards, new source onboarding, schema migrations, slow queries, stale data, PII, duplicates, metrics conflicts, and full autonomous operation. Each walkthrough was structured as a real DE scenario — we ran the agent, watched what happened, and asked: where does it succeed? Where does it fail? Where does a human have to step in, and why?

The question we're trying to answer: **what stops orgs from deploying agents as data engineers?**

Four walkthroughs in. This document is our current hypothesis.

---

## What We've Learned (WT-01-04)

### The Core Pattern

Every walkthrough showed the same thing, without exception.

The agent starts with structured inputs — a dbt manifest, access to information_schema, a warehouse connection, sometimes an API endpoint. It follows a decision tree: check this, if anomaly then branch here, else continue. The investigation is mechanical. It is not creative. It is a very large, very fast checklist executed with perfect memory and no ego.

At the end of that checklist, there is almost always a clear finding: a bug, a data quality issue, a design decision that needs to be made. The bug part is automatable. The design decision is not — not because the agent lacks the technical capability to choose, but because the choice involves context the agent doesn't have or organizational standing the agent doesn't hold.

Concretely, across four walkthroughs:

- **WT-01 (The Data You Inherit)**: Agent found NULL semantics bugs across three tables, identified multi-currency mixing in a revenue model, flagged duplicate payment IDs from a webhook deduplication gap. The test generator the same agent was using in dbt Guardian mode found nothing — because tests can only be written for things you already know to look for.

- **WT-02 (The Dashboard Is Wrong)**: 70% of orders were being silently dropped in a staging model. The agent traced the drop through three join conditions in under ten minutes. A human DE would have spent hours. The fix was a two-line SQL change. The agent proposed it. The human approved it. But the real finding was: this had been broken for weeks. Continuous reconciliation — comparing pipeline output to an external source of truth on a schedule — would have caught it on day one.

- **WT-03 (New Data Source Onboarding)**: HubSpot source for CAC calculation. The agent generated staging models, wrote source freshness tests, inferred grain from the API schema. It surfaced four decisions: entity resolution across HubSpot contacts and warehouse customers, attribution window choice, MRR vs ARR normalization, and pipeline ownership. It executed everything else without asking. The 80/20 split was real: 80% of onboarding is template execution, 20% is judgment calls that require business context.

- **WT-04 (The Schema Migration)**: A column rename in a source table caused 47 minutes of dark dashboards before a human noticed. The agent, in retrospect, would have detected the schema drift in the first polling cycle. The incident post-mortem showed the fix took four minutes once the cause was identified. Detection was the entire cost. Not remediation.

The pattern: mechanical investigation leads to automatable root cause leads to human judgment at specific, well-defined boundaries.

### Key Findings

**LRN-030 — Reconciliation is the highest-value DE capability.** Not test generation. Not documentation. Continuous comparison of pipeline output to an external source of truth — an API, a financial system, a third-party report — is the single thing that catches the bugs that matter. WT-02 demonstrated this. The dashboard was wrong for weeks. No test caught it because no one had written a test for "70% of orders should not be dropped." Reconciliation doesn't require knowing what to look for. It requires only knowing what the answer should look like.

**LRN-031 — Test intent, not metrics.** Threshold tests break constantly — the data changes, the threshold becomes stale, engineers disable the test. Intent-based tests (this column should never be NULL in a revenue context; orders should not decrease week-over-week by more than X%) are stable because they encode why the data matters, not what value it happened to have last Tuesday. WT-01 validated this: every test dbt Guardian tried to generate was threshold-based, and every one was either trivially satisfiable or immediately brittle.

**LRN-032 — DE investigation methodology is fully automatable.** The investigation the agent runs in every walkthrough follows a fixed structure: read the manifest, identify affected models, run systematic queries against information_schema and the warehouse, match findings against a bug pattern library. This is not reasoning in the creative sense. It is a decision tree with a lot of branches. The branches can be encoded. The agent is faster and more thorough than a human DE running the same investigation, not because it's smarter, but because it doesn't skip steps and doesn't get interrupted by Slack.

**LRN-033 — Source onboarding is 80% template, 20% judgment.** Staging models, source freshness tests, basic grain inference, column naming conventions — all of this is templatable. The agent can generate it from an API schema in minutes. The 20% that isn't templatable: entity resolution, attribution choices, ownership decisions. These require knowing things about the business that aren't in the manifest or the schema.

**LRN-034 — Entity resolution is a well-defined escalation boundary.** This is a concrete instance of LRN-033's 20%. High-confidence entity matches (same email, same ID, same name) can be auto-merged. Ambiguous matches (same name, different email, different geography) need a human. The boundary is definable. The agent can execute the high-confidence path and escalate the ambiguous cases with a clear rationale. This is not "the agent doesn't know" — it's "the agent knows it doesn't know enough to decide without risk."

**LRN-035 — Single async interface beats distributed channels.** Every walkthrough confirmed this operationally: one place where the agent surfaces findings, one place where the human responds. Not email, Slack, a dashboard, and a Jira ticket simultaneously. The cognitive overhead of managing multiple channels is the overhead we're trying to eliminate.

**LRN-036 — Detection latency is the real incident cost.** WT-04 made this quantitative: 47 minutes of dark dashboards, four-minute fix. The cost of the incident was not the fix. It was the 43 minutes before anyone knew something was wrong. Every product that focuses on making fixes easier is optimizing the wrong thing. The product that catches schema drift in the first polling cycle eliminates the incident, not just the fix time.

**LRN-038 — SDKification beats computer use.** The data stack has real APIs: manifest.json, information_schema, dbt Cloud REST API, warehouse Python SDKs (Snowflake connector, BigQuery client). An agent that uses these APIs directly is faster, more reliable, and more auditable than an agent that drives a browser. This is not a marginal difference. Computer use on a dbt Cloud UI will break every time the UI changes. An agent calling the dbt Cloud REST API will break only when the API changes — which is slower and versioned.

**LRN-039 — The human's residual role is context and org standing, not capability.** This is the most important finding for product design. The agent's escalations are not "I don't know how to do this." They are "I don't know whether 'platinum' means enterprise-tier for this customer, and I need that to calculate ARR correctly" or "I need someone with standing to go back to the backend team and ask them to change the event schema." These are not capability gaps. They are information gaps and authority gaps. A product that helps the agent surface and resolve these gaps is different in kind from a product that makes the agent more capable.

### What We Got Wrong

The dbt Guardian assumption was: there is a specific DE task (writing tests) that is annoying and automatable, and a narrow product that does that task well will be valuable.

This was wrong in a structural way, not just an execution way.

Narrow products for specific DE tasks are brittle because DE work is not modular. A test generator that doesn't understand the data it's testing generates tests that are either trivially true or immediately broken. Understanding the data requires the general investigation capability. Once you have the general investigation capability, the narrow test generation is a one-line output of a much richer process.

The general agent experiment revealed this. We gave the agent a data scenario with no product constraints — just "investigate this." It ran the same investigation it would have run as dbt Guardian, plus twenty things dbt Guardian would never have looked at, and came back with actual bugs. dbt Guardian, constrained to test generation, came back with test scaffolding that encoded no real knowledge of the data.

The lesson is not "general agents are better than narrow agents." The lesson is: **the product needs to match the shape of the work.** DE work is fundamentally investigative and cross-cutting. A product that constrains the agent to one slice of that work will perform worse than the unconstrained agent on that same slice — because the slice depends on the whole.

---

## The Form Factor Hypothesis

### The Role Inversion

The conventional mental model for AI in DE work is "AI assistant." The engineer is in the driver's seat. The AI helps. The engineer asks a question; the AI answers. The engineer reviews output; the AI waits.

This is the wrong model. It is wrong not because AI assistants are bad, but because it preserves the bottleneck. If the human is driving, the throughput is bounded by human attention and human working hours. The agent's speed advantage is neutralized because it's waiting for the human to formulate the next question.

LRN-037 describes what we saw in WT-04: **agent drives, human watches.** The agent is executing — running queries, checking schema, proposing fixes — and the human is present, watching the work happen, able to intervene. The human is not approving each step. The human is not reviewing output before the agent continues. The human is co-present with override capability.

This is not a subtle distinction. An approval-gate model — where the agent proposes and the human approves before execution — has the same throughput problem as the assistant model. Every gate is a synchronization point. Synchronization points are where speed dies.

The copilot model is: agent drives, human can pull the wheel. The human's job is not to approve every turn. The human's job is to watch for the situations where the agent is about to drive off a cliff and intervene. Accountability is established through presence and override capability, not through pre-approval of every action.

For orgs that have trained themselves on approval-gate workflows, this is the biggest cultural shift the product requires. It is also the most important insight for how the product gets designed: the agent needs to be auditable in real-time (the human needs to see what it's doing), not just auditable in retrospect (the human reviews a log after the fact).

### The Technical Architecture It Implies

LRN-038 is not just a technical preference. It has product implications.

An SDK-first agent can be deterministic in its actions. If the agent calls `manifest.json` and parses it, you can inspect exactly what it read. If the agent calls `information_schema.columns`, you can log the query and the result. If the agent calls the dbt Cloud REST API to trigger a run, you have an API call ID and a response code. The audit trail is complete by construction.

A computer-use agent clicking through a UI cannot give you this. The action is "clicked on the 'Run' button in the dbt Cloud interface." The result is whatever the UI rendered. The audit trail is screenshots.

This matters for trust. Orgs will not deploy an agent that acts as a black box. They will deploy an agent whose actions are logged, inspectable, and reproducible. SDK calls are inherently logged. UI interactions are not.

It also matters for reliability. The dbt Cloud UI has changed its layout three times in the past year. An agent whose tool calls target UI elements will break on each change. An agent whose tool calls target REST endpoints will break only on API version changes, which are announced, versioned, and backward-compatible for a predictable window.

The product is an SDK orchestration layer, not a browser automation layer. This choice determines the engineering architecture, the reliability profile, and the trust story.

### The Human's Residual Role

LRN-039 identified two types of gaps that require human involvement: context gaps and standing gaps.

**Context gaps**: "Does 'platinum' mean enterprise-tier for this customer?" "Is this churn or a plan downgrade?" "When we say 'active user,' does marketing mean MAU or WAU?" The agent cannot resolve these from the manifest or the schema. They require organizational knowledge that lives in people's heads or in documents the agent doesn't have access to.

**Standing gaps**: "Someone needs to go back to the backend team and ask them to stop sending duplicate events." "The finance stakeholder needs to sign off on the attribution window." "The data contract with the analytics team needs to be updated." These are not capability gaps. The agent knows what needs to happen. It cannot make it happen because it doesn't have the organizational standing to negotiate or commit on behalf of the data team.

For product design, this means: the product's escalation interface is not a capability interface ("the agent can't do X, so a human must"). It is an information and authority interface ("the agent can do X but needs Y input or Y permission first"). The design of that interface determines how often the agent has to stop and wait, which determines the operational throughput of the system.

A product that is well-designed here surfaces context gaps and standing gaps clearly, with enough context for the human to resolve them quickly and return control to the agent. A product that is poorly designed here presents the human with a wall of technical detail and waits.

---

## What the Product Needs to Be

### The Core Engine

**Reconciliation engine (LRN-030).** Continuous comparison of pipeline output to an external source of truth. The source of truth may be a financial system (Stripe, NetSuite), a third-party data provider, an upstream API, or an agreed-upon reference dataset. The engine checks, on a schedule, that what the pipeline produced matches what the source of truth says it should have produced. When it doesn't match, the engine investigates. This is the highest-value capability the product can have, because it catches the bugs that don't exist in the manifest — the silent failures, the wrong aggregations, the dropped rows.

**Investigation engine (LRN-032).** When an anomaly is detected — by reconciliation, by schema drift, by a test failure, by a user report — the engine runs a structured investigation: read the manifest, identify affected models, run systematic queries, match against a bug pattern library, produce a root cause hypothesis with confidence level and supporting evidence. This is the automatable half of what a DE does in incident response. The output is not just "something is wrong" but "here is what is wrong, here is the evidence, here is the proposed fix."

**Escalation protocol (LRN-033, LRN-034).** Well-defined boundaries where human judgment is required, with a structured interface for surfacing those escalations. The protocol encodes: here are the categories of decision that require human input (entity resolution, attribution choices, ownership decisions, compliance-adjacent calls), here is what the agent provides when escalating (the options it considered, the evidence for each, the recommendation if it has one), here is how the human responds. The escalation protocol is not a fallback. It is a designed handoff point that keeps the agent moving as fast as possible while ensuring humans are in the loop on the decisions that matter.

**Human presence layer (LRN-037).** The interface through which the human observes the agent driving. Not a review queue. Not an approval gate. A real-time view of what the agent is doing, with the ability to intervene, override, or redirect. The human's normal operating mode is: watch, occasionally redirect. The human's exceptional operating mode is: pull the wheel because the agent is about to do something wrong. The product needs to make both modes natural.

### What It's NOT

- **Not a narrow test generator.** WT-01 demonstrated this conclusively. A product constrained to test generation catches nothing, because test generation requires knowing what to look for, and knowing what to look for requires the general investigation capability. If you have the general investigation capability, test generation is a free byproduct, not a product.

- **Not a computer-use screen-scraper.** LRN-038 is unambiguous: the data stack has real APIs. Using them produces a faster, more reliable, more auditable agent. Using a browser UI produces a slower, more brittle, less auditable agent. The product does not automate UIs. The product orchestrates APIs.

- **Not an approval-gate chatbot.** LRN-037 is the role inversion insight. An agent that proposes, waits for approval, then executes, is constrained by human attention and response time. The throughput is bounded by the human. The copilot model — agent drives, human can override — is not just a UX preference. It is the throughput model that makes autonomous operation possible.

- **Not "AI as assistant."** The framing of AI as assistant preserves the human as the primary actor. The agent fetches, drafts, summarizes. The human decides, executes, owns. This is not what the walkthroughs showed. The walkthroughs showed an agent that can own the investigation and remediation workflow end-to-end, with human intervention at specific, well-defined points. The product should reflect that.

### The Product Primitives

Derived from the four walkthroughs, the product needs these concrete capabilities:

1. **Schema drift detection** (WT-04). Poll source schemas on a schedule. Detect column additions, renames, deletions, type changes. When detected, run impact analysis against the manifest, identify downstream models at risk, surface alert with severity rating before any model runs on the changed schema. Response time target: one polling cycle, not one incident.

2. **Pipeline reconciliation** (WT-02). Given a pipeline output and an external source of truth, compute the difference. The difference is not just row counts — it's a semantic comparison. Orders should match Stripe. Revenue should match NetSuite. The agent produces a reconciliation report on a schedule and investigates when the delta exceeds defined thresholds.

3. **Root cause investigation** (WT-01, WT-02). When an anomaly is detected, the agent runs a structured investigation: lineage traversal, query analysis, pattern matching against a bug library. The output is a root cause hypothesis with confidence level, supporting evidence, and a proposed fix. This is not a search result. It is a structured finding.

4. **Source onboarding scaffold** (WT-03). Given a new data source (API schema, existing warehouse tables, a Fivetran connector), the agent generates staging models, source freshness tests, and basic documentation. It surfaces the 20% of decisions that require business context. It executes the 80% that doesn't.

5. **Escalation interface** (WT-03, LRN-034, LRN-039). A structured interface for surfacing context gaps and standing gaps to the human, with enough supporting information that the human can resolve them quickly. Not a generic "I need help" message. A structured escalation: here is the decision, here are the options, here is the evidence, here is what I recommend, here is what happens next.

6. **Real-time audit log** (LRN-037, LRN-038). Every API call the agent makes, every query it runs, every schema it reads, every action it takes — logged with timestamp, rationale, and result. This is the trust foundation. The human can see, at any point, exactly what the agent did and why.

---

## Deployment Barriers: What We Know So Far

### Technical Barriers (Partially Solved)

The walkthroughs showed that the core technical capabilities exist. The agent can investigate pipelines, detect schema drift, reconcile data, onboard sources. The SDK-first approach (LRN-038) solves the tool reliability problem — API calls are more stable and auditable than UI automation.

What is not solved: the integration surface. Different orgs have different warehouses (Snowflake, BigQuery, Redshift, Databricks), different orchestrators (Airflow, Prefect, dbt Cloud, Dagster), different source systems. The product needs adapters. Writing those adapters is engineering work, and the set of combinations is large.

The investigation decision tree (LRN-032) needs to be encoded as a bug pattern library. We have patterns from four walkthroughs. We need patterns from ten. The patterns generalize — NULL semantics, type coercions, join fanouts, schema drift, reconciliation deltas — but the library needs to be built.

Entity resolution (LRN-034) has a partial solution: confidence threshold for auto-merge, escalation for ambiguous cases. But the confidence model needs training data, and the escalation interface needs to be designed well enough that humans actually resolve escalations promptly rather than letting them queue.

### Organizational Barriers (Still Unclear)

LRN-039 is the most important finding for organizational barriers, and it is the one we understand least well.

The context gap problem: orgs have institutional knowledge that is not in any system the agent can access. "Platinum means enterprise." "The backend team is backlogged and won't respond to schema change requests." "Finance treats refunds differently from chargebacks." This knowledge exists in people's heads, in Notion docs, in Slack threads. Getting it into a form the agent can use is a change management challenge, not an engineering challenge.

The standing gap problem: who authorizes the agent to act? If the agent identifies that a data contract needs to change, who has the standing to initiate that conversation? If the agent determines that a source system is emitting bad data, who escalates to the source system team? The agent can identify the issue and draft the ask. But it cannot substitute for organizational authority.

We do not know yet whether these barriers are product problems or change management problems. They may be both. A product that provides a structured interface for feeding context to the agent (a knowledge base the team maintains, a set of business rules the agent references) partially addresses the context gap. The standing gap may require a change management playbook, not a product feature.

### Trust and Accountability

The copilot model (LRN-037) is our current answer to the trust problem. The human is present, watching the agent work, with override capability. Accountability is established through presence: the human is not just reviewing logs after the fact, the human is watching the work happen and can intervene at any point.

This addresses the audit accountability question (a human was present and responsible) and the error containment question (a human can pull the wheel before the agent does something irreversible).

What it does not address: what happens when the human is not watching? Overnight reconciliation, weekend schema drift detection — these run without a human present. The product needs a clear model for what the agent can do autonomously (read-only operations, detection, alerting) vs. what requires human presence (remediation, schema changes, data contract modifications).

We do not have this model fully specified. WT-10 (Autonomous Agent) is designed to surface it.

---

## Open Questions for WT-05-10

The four completed walkthroughs validated the core pattern: mechanical investigation, automatable root cause, human judgment at specific boundaries. The six remaining walkthroughs are designed to stress-test that pattern in more complex scenarios and surface the deployment barriers that haven't appeared yet.

**WT-05 (Slow Query)**: Does the agent's investigation capability extend to performance? The investigation pattern for correctness issues (query information_schema, traverse lineage, match patterns) is well-defined. Performance investigation requires different inputs: EXPLAIN plans, QUERY_HISTORY, warehouse compute metrics. The hypothesis is that the same decision tree structure applies — the inputs are different, not the methodology. The risk is that performance optimization requires warehouse-specific expertise (Snowflake clustering keys, BigQuery partitioning, Redshift sort keys) that doesn't generalize across the pattern library. WT-05 will test whether the investigation engine extends to performance or whether performance is a separate domain.

**WT-06 (Data Stale)**: Can the agent detect silent failures? The schema migration scenario (WT-04) involved a schema change that caused an explicit error. Staleness scenarios often involve successful exits with no actual work: a job that exits 0 but processes no rows, a source that stops updating without emitting an error, a pipeline that runs on schedule but reads from a stale snapshot. The hypothesis is that orchestrator log parsing plus reconciliation detection can catch these. The risk is that log parsing is highly orchestrator-specific (Airflow logs look nothing like Prefect logs), and staleness by definition doesn't appear in lineage or test failures. WT-06 will test whether the reconciliation engine can catch what tests can't.

**WT-07 (PII Everywhere)**: Does PII compliance cross into a new trust domain? The walkthroughs so far have involved data quality issues where the agent's judgment is trusted for technical decisions. PII classification and handling involve compliance and legal risk, which may put them in a different trust category. The hypothesis is that PII detection is automatable (pattern matching + classification model) but PII remediation decisions are not (deleting, masking, or restricting data has legal implications that require human and possibly legal sign-off). The risk is that orgs will not trust any autonomous action in the PII domain, regardless of how good the detection is. WT-07 will test where the trust boundary actually sits for compliance-adjacent decisions.

**WT-08 (Duplicate Problem)**: Does the 80/20 pattern hold when finance is the stakeholder? Financial reconciliation is a domain where errors have direct revenue and compliance implications. The hypothesis is that the investigation pattern is the same — find duplicates, trace to source, propose deduplication strategy — but the escalation threshold is lower because the consequences of errors are higher. The risk is that financial stakeholders require a fundamentally different accountability model (four-eyes principle, explicit sign-off, audit trail that satisfies external auditors) that the copilot model doesn't satisfy. WT-08 will test whether the trust and accountability model holds under financial-grade requirements.

**WT-09 (Metrics Layer)**: Can the agent mediate between teams with conflicting metric definitions? The previous walkthroughs involved single-team scenarios with clear technical root causes. The metrics layer scenario involves multiple teams (product, finance, marketing) with legitimately different definitions of the same metric ("active user," "revenue," "conversion"). The hypothesis is that the agent can surface the conflict and present options but cannot resolve it — this is pure organizational politics, not a technical problem. The risk is that the agent exacerbates the conflict by suggesting a resolution that one team can point to as "what the AI said" and use as political cover. WT-09 will test whether the escalation protocol holds in multi-stakeholder scenarios where the decision has political dimensions.

**WT-10 (Autonomous Agent)**: The synthesis. After nine scenarios, what would it actually take to deploy this as a full autonomous agent? What would the org need to provide (context, standing, trust model)? What would the product need to provide (audit trail, escalation protocol, presence layer)? What operations are in scope for autonomous execution vs. requiring human presence? WT-10 is not a new scenario — it is a structured retrospective across all nine scenarios, distilled into a deployment specification. The output of WT-10 is the input to product thesis v2 and the build decision.

---

## Strategic Positioning

### Why dbt Labs Can't Build This

Three structural constraints prevent dbt Labs from building the agent DE product, and they are not execution constraints — they are business model and strategic constraints.

**Focus on development, not operations.** dbt Labs' product is a development tool. The dbt Cloud product is oriented around building and running dbt projects. It has excellent developer experience for writing models, running tests, and deploying pipelines. It is not oriented around operational monitoring, continuous reconciliation, or incident response. Expanding into operations would require a different product surface and different buyer conversations.

**Can't go cross-stack.** The most valuable capability the agent DE needs is cross-stack visibility: reading warehouse metadata, calling orchestrator APIs, reconciling against source systems (Stripe, NetSuite, HubSpot). dbt Labs' business model requires dbt to be at the center of the data stack. A product that treats dbt as one component among several — rather than the center — conflicts with the core positioning. The reconciliation engine, by definition, operates outside dbt: comparing pipeline output to Stripe, reading Airflow logs, calling the Fivetran API. dbt Labs can't build a product that minimizes dbt's centrality.

**Won't build autonomous remediation.** dbt Labs is a developer tool. Developer tools give developers control. An autonomous agent that detects a schema migration and automatically updates downstream models is a product that removes developer control. This conflicts with the DNA of a developer tool company. dbt Labs can build AI that suggests fixes. It will not build AI that applies fixes autonomously — that positions dbt as the thing that changes your code without your approval, which is antithetical to the developer tool value proposition.

These constraints are structural, not directional. They don't change with new leadership or new strategy. They are load-bearing walls of the dbt Labs business model.

### The Build vs Buy Question

What does an org bring to this product? Their warehouse credentials, their dbt project, their source system integrations, their organizational knowledge (the 20% context that isn't in the manifest). What does the product bring? The investigation engine, the reconciliation engine, the escalation protocol, the SDK orchestration layer, the bug pattern library.

The deployment model implied by this split: the product connects to the org's existing data stack via standard APIs. No new infrastructure. No migration. The agent operates on the org's existing models, existing orchestration, existing warehouse. The deployment is an integration, not a migration.

This is the right model for adoption. Data teams don't want to rebuild their stack. They want to augment their existing stack with autonomous operational capability. The product needs to meet them where they are.

### Timing

Three things converged in 2025-2026 that make this possible now:

**Model capability crossed the threshold.** LLMs can now read a 50-model dbt manifest, traverse a lineage graph, and produce a coherent root cause hypothesis without hallucinating table names or column types. This was not reliably true 18 months ago. The walkthroughs validated this directly — the investigation quality is production-grade.

**Data stacks standardized on APIs.** The modern data stack converged on REST APIs, Python SDKs, and standard metadata schemas (dbt manifest, information_schema, OpenLineage). This makes the SDK-first approach viable at scale. The surface area of integrations is large but bounded and well-documented.

**Autonomous agent frameworks matured.** The infrastructure for running agents in production — reliable tool calling, structured output, long-context reasoning, agent orchestration frameworks — reached production maturity in 2025. Building on this infrastructure in 2026 means building on a stable foundation, not a research prototype.

The window is 12-18 months. The model capability threshold has been crossed; other teams will reach the same conclusion. The first product to validate the deployment model — copilot-first, SDK-orchestrated, reconciliation-centered — owns the category.

---

## What We're NOT Claiming Yet

This document is a hypothesis, not a conclusion. The following claims are not established:

**We haven't validated that the pattern generalizes.** Four walkthroughs is not a representative sample. WT-05-10 are specifically designed to probe the edges — performance, compliance, multi-stakeholder politics, full autonomy. The pattern (mechanical investigation → automatable root cause → human judgment at defined boundaries) held across four scenarios. It may not hold when the scenario involves legal risk, financial accountability, or multi-team organizational dynamics.

**We don't know if orgs will actually trust the copilot model.** LRN-037 describes what happened in our walkthroughs. It does not describe what happens when a real data team, with real accountability concerns and real organizational risk tolerance, is asked to let an agent drive their production pipelines. The trust-building process for production deployment has not been tested.

**We don't know the context gap magnitude.** LRN-039 identified context gaps as a deployment barrier, but we don't know how large they are in practice. If every escalation requires 30 minutes of human research to resolve, the throughput advantage of the autonomous agent evaporates. If most escalations can be resolved in 30 seconds, the model works. We haven't measured this.

**The financial and compliance trust domain is untested.** WT-07 and WT-08 will probe this. Our current hypothesis is that the copilot model holds but with a lower autonomy threshold. It is possible that financial and compliance stakeholders require a fundamentally different accountability model that our current architecture doesn't satisfy.

**We have not validated SDKification at scale.** The SDK-first approach worked in walkthroughs with direct API access. Production deployment involves authentication management, rate limiting, credential rotation, and multi-tenant isolation. The architecture works in principle. It has not been stress-tested at production scale.

What would falsify this thesis?

- WT-05-10 reveal a class of DE scenarios where the investigation pattern breaks down and a different approach is required.
- Orgs refuse the copilot model and require approval gates, making the throughput advantage disappear.
- The context gap problem turns out to be so large that the agent spends more time waiting for human input than executing autonomously.
- A competitor ships a credible version of this product before we reach product thesis v2.

---

## Next Steps

**Walkthroughs WT-05-10**: Run with CEO. Each walkthrough tests a specific deployment barrier hypothesis. WT-10 is the synthesis that feeds product thesis v2.

**SDKification research (BL-023)**: Enumerate the SDK surface area for the primary data stacks (Snowflake, BigQuery, Redshift, Databricks) and orchestrators (Airflow, Prefect, dbt Cloud, Dagster). This research feeds the toolset specification (BL-026), which is the technical foundation for building the investigation engine.

**Toolset specification (BL-026)**: Once BL-023 is complete, specify the agent's tool set: the exact API calls, the SDK methods, the metadata schemas, the input/output contracts. This is the engineering specification that turns the investigation pattern into buildable software.

**Product thesis v2**: After WT-10, synthesize all ten walkthroughs into a revised thesis with the deployment model fully specified and the trust/accountability model validated. This document, plus the toolset specification, is the input to the build decision.

**Build decision**: Go/no-go on building the product. Input: product thesis v2, toolset spec, competitive landscape, org capacity. This is a CEO decision with CTO-Agent recommendation.

---

*Product Thesis v1. Validated against WT-01-04. Hypothesis pending WT-05-10. Next revision after WT-10.*
