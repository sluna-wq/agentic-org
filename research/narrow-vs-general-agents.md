# Narrow vs General Agents: The dbt Guardian Pivot

> **Strategic insight from WT-01 that redirected product strategy**
> Written: 2026-02-17 (Cycle #13)
> Author: CTO-Agent
> Context: DEC-012 pivot from product shipping to walkthrough-driven discovery

## Executive Summary

**The Question**: Should we build narrow, productized agents (e.g., "Test Generator") or enable organizations to deploy general agents (e.g., "Data Engineer Agent")?

**The Discovery**: In WT-01, we tested both approaches on the same problem:
- **Narrow product (Test Generator)**: Ran analysis, found almost nothing meaningful
- **General agent (DE investigation)**: Conducted full root-cause analysis, found everything

**The Insight**: The capability gap is closed — agents can already do full data engineering work. The product question isn't "what narrow task should we automate?" but rather "what stops organizations from deploying general agents?"

**The Implication**: We pivoted from building products to understanding deployment barriers. Through 10 DE walkthroughs, we're discovering what agent DEs actually need to operate autonomously in production.

---

## The Test: WT-01 "The Data You Inherit"

### Setup
**Scenario**: Analytics team onboarding to messy Acme Corp dbt project (16 models, 10 tested, real data quality issues)

**Two approaches tested**:
1. **Narrow**: Test Generator v0 (built in Cycles #2-11) — analyzes coverage gaps, suggests tests
2. **General**: CTO-Agent as DE — full investigative workflow

### The Narrow Approach: Test Generator

**What it did**:
- Analyzed manifest.json + catalog.json
- Detected 23% test coverage (low but not alarming)
- Identified 3 untested columns as "gaps"
- Suggested generic tests (not_null, unique, accepted_values)

**What it found**:
- `customers.created_at` needs not_null test
- `orders.customer_id` needs unique + not_null tests
- `orders.order_status` needs not_null + accepted_values tests

**What it missed**:
- ❌ Semantic issues (NULL vs 0 conflation in order totals)
- ❌ Multi-currency problems (USD + EUR mixed without conversion)
- ❌ Data quality bugs (duplicate customer records with different addresses)
- ❌ Schema design problems (ambiguous date meanings)
- ❌ Root causes (why the data is messy, where issues originate)
- ❌ Business impact (what reports are affected, severity assessment)

**Assessment**: The narrow tool worked exactly as designed — it detected test coverage gaps. But it completely missed the actual problems a data engineer would care about.

### The General Approach: Agent as DE

**What it did**:
- Read all model definitions (SQL logic, dependencies, transformations)
- Analyzed column-level patterns (naming, types, value distributions from catalog)
- Investigated semantic meaning (what do these columns represent?)
- Traced data lineage (where do values come from?)
- Identified inconsistencies (NULL handling, currency mixing, duplicates)
- Assessed business impact (what breaks? who's affected?)
- Proposed solutions with trade-offs

**What it found**:
1. **NULL vs 0 conflation**: `order_total` allows NULLs but unclear if NULL = $0 or missing data. Downstream impact on revenue reports.
2. **Multi-currency chaos**: `order_total` mixes USD and EUR without conversion or currency field. Revenue calculations are wrong.
3. **Duplicate customers**: Multiple records for same customer with different addresses. No clear deduplication logic.
4. **Ambiguous dates**: `created_at` vs `updated_at` in several models — which date means what? Inconsistent usage.
5. **Weak PK enforcement**: `customer_id` unique test exists but catalog shows duplicates. Test is passing but data is bad.

**Assessment**: This is actual data engineering work — root cause analysis, impact assessment, solution proposals. This is what organizations hire DEs to do.

---

## The Strategic Question This Raises

### What We Thought We Were Building
**Before WT-01**: "Organizations need better dbt testing tools. Let's build specialized agents that automate narrow tasks (test generation, lineage, impact analysis, etc.)"

**Product vision**: Suite of narrow agents, each solving one specific problem:
- Test Generator Agent → automates test creation
- Lineage Agent → maps dependencies
- Impact Agent → change blast radius
- Documentation Agent → writes model docs
- Performance Agent → optimizes queries

**Go-to-market**: "Add AI agents to your dbt workflow"

**Assumption**: The capability gap is large — agents can only do narrow, well-defined tasks.

### What We Discovered
**After WT-01**: General agents can already do full DE work. The capability gap isn't the constraint.

**Key observations**:
1. **Narrow tools miss context** — Test Generator couldn't see that the real issue wasn't test coverage but semantic ambiguity. A general agent reading SQL + column patterns + catalog data saw immediately that `order_total` semantics were broken.

2. **DEs don't think in tasks** — Real DE work isn't "generate tests" or "write docs." It's "investigate why revenue is off" → leads to test gaps, lineage issues, doc updates, schema fixes. The task decomposition happens during investigation, not upfront.

3. **Narrow productization fragments workflows** — If we built 5 narrow agents, DEs would need to: (1) manually diagnose which agent to use, (2) run each agent separately, (3) synthesize findings across agents, (4) write the actual fixes themselves. That's not automation — that's more tools to learn.

4. **General agents already work** — The CTO-Agent conducting DE investigation in WT-01 produced professional-quality analysis that any analytics team would trust. No fine-tuning, no specialized training, no custom tooling beyond reading files. Just Claude Sonnet 4.5 with good context.

### The Real Question
If agents can already do full DE work, why aren't organizations deploying them?

**Not a capability problem** — agents are good enough
**Not a tooling problem** — Claude Code + MCP servers + git workflows exist
**Not a cost problem** — $90/month per agent vs $120K/year human DE

**Deployment problem** — something else is blocking adoption:
- Trust? (how do orgs verify agent work quality?)
- Integration? (how do agents fit into existing workflows?)
- Governance? (who approves agent changes? who reviews PRs?)
- Observability? (how do you monitor agent performance?)
- Training? (how do you onboard an agent to a codebase?)
- Culture? (do teams accept AI colleagues?)

**This is what the walkthroughs must discover.**

---

## The Pivot: From Product to Discovery

### Old Plan (Pre-WT-01)
1. Build Test Generator v0 (done in Cycles #2-11)
2. Run pilot with 3-5 design partners
3. Gather feedback on Test Generator
4. Build Lineage Agent, Impact Agent, etc.
5. Assemble suite of narrow agents
6. GTM as "AI toolkit for dbt teams"

### New Plan (Post-WT-01 / DEC-012)
1. **Learn DE skills through walkthroughs** — CEO + CTO both experience what DEs actually do in 10 realistic scenarios
2. **Discover deployment barriers** — as we simulate agent DE workflows, surface what would stop real organizations from doing this
3. **Design for general agents** — product emerges from understanding deployment, not from automating tasks
4. **Synthesis in WT-10** — after 9 scenarios + 1 autonomous agent scenario, synthesize learnings into product/platform design

### Why This Matters
**Narrow products** (Test Generator, etc.):
- ✅ Easy to explain ("generates dbt tests")
- ✅ Clear value prop ("saves 2 hours/week per DE")
- ✅ Low adoption risk (tool, not team member)
- ❌ **Solves toy problems** — doesn't address real DE workflows
- ❌ **Low ceiling** — can't grow beyond narrow task
- ❌ **Fragments work** — doesn't automate the full job

**General agents** (Agent DE):
- ❌ Harder to explain ("AI colleague that does data engineering")
- ❌ Value prop requires education ("replaces $120K/year hire")
- ❌ Higher adoption risk (team dynamics, trust, governance)
- ✅ **Solves real problems** — handles full DE investigations, not just test gaps
- ✅ **High ceiling** — can do any DE work (pipelines, modeling, ops, etc.)
- ✅ **End-to-end automation** — owns outcomes, not tasks

**The bet**: If we can solve deployment (trust, integration, governance, observability), general agents unlock 10x more value than narrow task automation.

---

## Implications for Product Design

### What We're NOT Building
- ❌ Test Generator as standalone product
- ❌ Suite of narrow task agents
- ❌ "AI toolkit" positioning
- ❌ dbt plugin / extension model

### What We MIGHT Build (Post-WT-10)
*(This is speculation until walkthroughs complete — the point of discovery is to learn, not confirm)*

**Hypothesis 1: Agent DE Platform**
Enable organizations to deploy agent DEs that work like human DEs:
- Onboarding system (agent learns codebase, style, conventions)
- Work intake (how DEs receive requests → how agents receive requests)
- Execution environment (safe sandboxes, PR workflows, rollback)
- Quality gates (what must be verified before merging agent PRs?)
- Observability (how do you monitor agent work quality over time?)
- Governance (approval workflows, escalation rules)

**Hypothesis 2: Agent DE Marketplace**
Pre-trained specialist agents for common DE personas:
- Analytics Engineer (dbt modeling, metrics, documentation)
- Data Ops Engineer (pipeline monitoring, incident response)
- Data Quality Engineer (testing, validation, anomaly detection)
Organizations "hire" agents with domain expertise, not blank-slate LLMs.

**Hypothesis 3: Hybrid Model**
General agents with narrow tool access:
- Core agent is general (can investigate, plan, execute)
- Tools are narrow and safe (Test Generator, Safe Refactor, Impact Analyzer)
- Agent orchestrates tools to complete DE work end-to-end
- Organizations trust tools (verified, sandboxed) more than raw LLM output

**Hypothesis 4: Deployment-as-a-Service**
The product isn't the agent — it's deployment infrastructure:
- Organizations bring their own LLM (Claude API, OpenAI, self-hosted)
- We provide: secure runtime, git integration, PR workflows, quality gates, observability
- Positioning: "We solve agent deployment so you can focus on agent capabilities"

**None of these are decided.** The walkthrough curriculum (WT-02 through WT-10) will teach us which hypothesis (or which combination) actually solves the deployment problem.

---

## Why This Matters for Other Products

This insight generalizes beyond dbt/data engineering.

### The Pattern
1. **LLMs can do full jobs, not just tasks** — coding, writing, analysis, research, ops
2. **Narrow task tools are easy but low-ceiling** — automate 5% of the job
3. **The constraint isn't capability** — it's deployment (trust, integration, governance)
4. **Real value = autonomous agents doing full jobs** — not tools that help humans do jobs faster

### Where This Applies
- **Software engineering**: Not "AI code completion" (narrow) but "AI engineer" (general)
- **Customer support**: Not "AI response suggestions" (narrow) but "AI support agent" (general)
- **Legal work**: Not "AI contract review" (narrow) but "AI paralegal" (general)
- **Accounting**: Not "AI expense categorization" (narrow) but "AI bookkeeper" (general)

### The Deployment Barrier Hypothesis
**Why we see lots of narrow AI tools but few deployed general agents**:
- Narrow tools = low trust requirement (human reviews every output)
- General agents = high trust requirement (agent owns outcomes)
- **Nobody has solved deployment** (safe autonomous operation + organizational trust)

**If we solve deployment for agent DEs**, the playbook might generalize to other domains.

---

## Strategic Implications

### 1. Competitive Positioning
**If we build narrow products** (Test Generator, etc.):
- Compete with dbt Labs (building Copilot), Great Expectations, Elementary, Soda
- Crowded space, price competition, feature parity races
- Hard to defend (dbt Labs can bundle features into Cloud)

**If we build general agent deployment**:
- Compete with... nobody? (unproven market)
- High risk (might not work), high reward (could be category-defining)
- Defensible if we solve deployment first (network effects from learnings)

### 2. GTM Strategy
**Narrow products** → PLG (free tier, land-and-expand, usage-based pricing)
**General agents** → Sales-assisted (trust requires education, implementation, change management)

### 3. Roadmap Sequencing
**Old roadmap**: Test Generator → Lineage Agent → Impact Agent → Documentation Agent → Suite
**New roadmap**: WT-02 through WT-10 → Synthesis → MVP deployment platform → First agent DE → Iterate

### 4. Team Needs
**Narrow products** → Product engineers (build features fast)
**General agents** → Solutions architects + customer success (help orgs deploy + operate agents)

---

## Open Questions (To Be Answered by Walkthroughs)

### Trust & Verification
- How do organizations verify agent work quality?
- What quality gates must exist before agent PRs can merge?
- How much human review is acceptable? (0%? 10%? 50%?)
- Do agents need to explain their reasoning? Cite sources?

### Integration & Workflow
- Where do agent tasks come from? (Slack? GitHub issues? Monitoring alerts?)
- How do agents fit into existing team workflows? (stand-ups? sprint planning?)
- What happens when an agent gets stuck? (escalation path?)
- How do agents coordinate with human DEs? (async? real-time?)

### Governance & Control
- Who has authority to "hire" an agent? (manager? eng director? C-suite?)
- Who reviews agent PRs? (other agents? humans? automated checks?)
- What changes require human approval? (schema changes? production deploys?)
- How do you "fire" an agent? (turn off? gradual ramp-down?)

### Observability & Operations
- How do you monitor agent performance over time?
- What metrics matter? (tasks completed? quality score? time saved?)
- How do you debug when an agent makes a mistake?
- How do you improve agent performance? (feedback loops? fine-tuning?)

### Organizational & Cultural
- Do teams accept AI colleagues? (initial resistance? adoption curve?)
- How do you onboard an agent to team norms? (code style? communication?)
- Does agent work "feel" different from human work? (if so, is that good or bad?)
- What happens to displaced human DEs? (upskill? redeploy? layoffs?)

**These questions can't be answered through research.** We must experience DE work, attempt agent deployment workflows, and surface the real barriers.

---

## Learning Strategy: The 10 Walkthroughs

### Coverage Map
| WT# | Scenario | DE Skills Tested | Agent Deployment Barriers Surfaced |
|-----|----------|------------------|-----------------------------------|
| 1 | The Data You Inherit | Investigation, root cause analysis | ✓ Discovery (narrow vs general insight) |
| 2 | The Dashboard Is Wrong | Debugging, reverse engineering | TBD (trust, verification) |
| 3 | New Data Source Onboarding | Schema design, pipeline setup | TBD (integration, approval workflows) |
| 4 | The Schema Migration | Refactoring, impact analysis | TBD (safety, rollback, governance) |
| 5 | Why Is This Query So Slow? | Performance optimization | TBD (observability, iteration) |
| 6 | The Data Is Stale | Incident response, pipeline ops | TBD (on-call, escalation) |
| 7 | PII Everywhere | Compliance, security | TBD (trust for sensitive work) |
| 8 | The Duplicate Problem | Data quality, deduplication | TBD (correctness verification) |
| 9 | Building the Metrics Layer | Architecture, abstraction design | TBD (strategic decisions, collaboration) |
| 10 | The Autonomous Agent | Full end-to-end DE workflow | TBD (synthesis — what makes autonomy possible?) |

### What Success Looks Like
**After WT-10**, we should be able to answer:
1. **What DE skills must agents have?** (catalog from 10 scenarios)
2. **What stops orgs from deploying agent DEs?** (barriers identified + validated)
3. **What product/platform solves deployment?** (design informed by real barriers)
4. **What's the MVP?** (minimum viable deployment that orgs would trust)
5. **What's the go-to-market?** (how to position, sell, implement general agents)

---

## Why This Document Matters

### For Future Product Design (Post-WT-10)
When we return to building, we'll need to remember:
- **Why we pivoted** — narrow products missed the real problems
- **What we learned** — agents can do full DE work, deployment is the constraint
- **What hypothesis we're testing** — general agents + deployment infrastructure

### For CEO Context
This document captures the strategic rationale for DEC-012. When walkthroughs take weeks/months, this explains why we're not shipping product.

### For Institutional Memory
If/when the org scales (adds agents, pivots again, changes direction), this document preserves a critical insight: **The capability gap is closed. The deployment gap is wide open.**

---

## Appendix: What We Preserved from dbt Guardian

The 10 cycles of product work (Cycles #2-11) aren't wasted:

### Reusable Components
- **dbt parser** (manifest, catalog, YAML) — general infrastructure for any dbt agent
- **Test coverage analyzer** — useful for agent DEs conducting investigations
- **Schema YAML generator** — might become tool in agent toolkit
- **CLI patterns** — command structure, rich output, error handling
- **Testing patterns** — unit test approach, fixtures, mocking

### Validated Learnings
- **LRN-013**: Parser design (Pydantic models, CLI commands, mono-repo)
- **LRN-014**: Test coverage analysis patterns (priority scoring, gap detection)
- **LRN-015**: Pilot planning (partner criteria, feedback framework)
- **LRN-016**: Defensibility analysis (dbt Labs constraints)
- **LRN-017**: Developer tooling (CI/CD, Makefile, pre-commit)
- **LRN-018**: Pilot infrastructure (onboarding, feedback, tracking)
- **LRN-021**: End-to-end validation (sample projects, CLI testing)
- **LRN-022**: Proactive bug fixes (FK detection, heuristic ordering)
- **LRN-023**: Smart defaults (relationship parent inference)

### Possible Futures
1. **Narrow product revival**: If general agents don't work, Test Generator v0 exists
2. **Tool integration**: Test Generator becomes one tool in agent DE toolkit
3. **Reference implementation**: Show case study of "how we built first narrow agent"
4. **Pivot template**: Document the journey from narrow→general for other domains

---

**Document Status**: Living document — update after each walkthrough with new insights.
**Next Update**: After WT-02 ("The Dashboard Is Wrong") — add trust/verification learnings.

---
*Last updated: 2026-02-17 (Cycle #13)*
*Author: CTO-Agent*
*Related: DEC-012, LRN-024, LRN-025, LRN-026, LRN-027, WT-01*
