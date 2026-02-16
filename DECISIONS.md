# Decision Log

> **Why did we choose what we chose?**
> Every material decision records context, options, rationale, and outcome.
> This is how the org maintains institutional reasoning — not just what happened, but *why*.

## Format
```
### DEC-[NNN]: [Title]
- **Date**: YYYY-MM-DD
- **Decider**: [Role]
- **Context**: What situation prompted this decision?
- **Options considered**:
  1. Option A — tradeoffs
  2. Option B — tradeoffs
- **Decision**: What we chose
- **Rationale**: Why this option over others
- **Outcome**: [Pending | Succeeded | Failed | Revised] — updated after results
- **Learnings**: What we'd do differently (updated retroactively)
```

---

### DEC-001: Bootstrap org with self-referential knowledge architecture
- **Date**: 2026-02-11
- **Decider**: CTO-Agent (approved by CEO)
- **Context**: CEO directed bootstrap of agentic org. Need a structure that enables a "closed loop of self-understanding."
- **Options considered**:
  1. Flat folder structure with templates — simple but no self-referential properties, agents can't reason about org state
  2. Database-backed system — powerful but complex, breaks repo-native principle
  3. Interlocking markdown documents with explicit update protocols — repo-native, readable by any agent, self-referential through cross-references and a single STATE.md entry point
- **Decision**: Option 3 — interlocking markdown with STATE.md as the live self-model
- **Rationale**: Markdown is universally readable by agents and humans. Cross-references create a knowledge graph. STATE.md as entry point means any agent can orient in one read. Update protocols on each doc ensure the loop stays closed (execution → artifact → state update → next planning cycle).
- **Outcome**: Pending — will evaluate after first real execution cycle
- **Learnings**: TBD

### DEC-002: Build two explicit interfaces — CEO↔Org and Org↔Product
- **Date**: 2026-02-11
- **Decider**: CTO-Agent (directed by CEO)
- **Context**: CEO identified two missing interfaces: (1) how the CEO sees what's happening and steers without micromanaging, and (2) how the org actually executes changes on a product codebase.
- **Options considered**:
  1. Embed interface protocols into existing docs — smaller footprint but buries critical workflows in larger documents
  2. Create dedicated interface documents — clearer separation of concerns, each doc has one job
  3. Use external tools (dashboards, CI/CD config) — powerful but breaks repo-native principle
- **Decision**: Option 2 — three new dedicated documents: DIRECTIVES.md, BRIEFING.md, WORKBENCH.md
- **Rationale**: Each interface deserves its own artifact because they serve fundamentally different audiences (CEO vs agents) and purposes (visibility vs execution). DIRECTIVES.md is the CEO's persistent voice. BRIEFING.md is the org's narrative report. WORKBENCH.md is the execution boundary between org thinking and product doing. Three new playbooks (PB-010, PB-011, PB-012) operationalize them.
- **Outcome**: Pending — will evaluate when first product work flows through the interfaces
- **Learnings**: TBD

### DEC-003: Redesign for autonomy, privacy, and AI-native operation
- **Date**: 2026-02-11
- **Decider**: CTO-Agent (directed by CEO)
- **Context**: CEO identified four gaps: (1) org has no heartbeat — nothing triggers work without human prompting, (2) no private CEO↔CTO channel — everything is visible to all agents, (3) visibility is snapshot-based — no granular real-time view of work, (4) nothing is AI-native — org doesn't use skills, hooks, sub-agents, MCP, or daemon automation. CEO also wanted clear CTO autonomy and a structured weekly sync.
- **Options considered**:
  1. Incremental patches to existing docs — add a few new sections to existing artifacts
  2. Full interface redesign with three distinct interfaces (Private, Public, Execution) + daemon + skills — more work upfront but solves all gaps comprehensively
  3. External tooling (Slack, Linear, etc.) for notifications and scheduling — powerful but breaks repo-native principle
- **Decision**: Option 2 — full redesign with three interfaces, daemon, skills, CTO Autonomous Zone
- **Rationale**: The CEO's requirements are structurally different from what existed. Private communication, 24/7 autonomy, and AI-native operation can't be patched onto the existing design — they need dedicated mechanisms. `.cto-private/` for privacy, `daemon/` for heartbeat, `.claude/skills/` for AI-native capabilities, and CTO Autonomous Zone in CHARTER.md for codified autonomy. Staying repo-native while using Claude Code's skill/hook/sub-agent capabilities makes this practically AI-native without external dependencies.
- **Outcome**: Pending — will evaluate after first autonomous cycle and first weekly sync
- **Learnings**: TBD

### DEC-004: Prioritize AI agent expertise building as pre-product foundation
- **Date**: 2026-02-11
- **Decider**: CEO (directed to CTO-Agent)
- **Context**: Org infrastructure is complete. Before choosing a product to build, CEO wants the org to develop deep expertise in AI agent technologies — frameworks, tools, patterns, and latest developments. CEO also wants simplified interaction (CEO-GUIDE.md) and backlog seeded so the daemon can begin autonomous work.
- **Options considered**:
  1. Jump straight to product — start building something and learn along the way
  2. Structured research phase — survey the AI agent landscape, go deep on our own stack, then plan talent needs before building
- **Decision**: Option 2 — structured research phase with three backlog items (BL-001: landscape research, BL-002: Claude deep dive, BL-003: talent plan)
- **Rationale**: The org will build AI agent products. Having an informed perspective on the ecosystem, tools, and trade-offs before committing to a product direction reduces risk of building on the wrong stack or missing key capabilities. Research items are within CTO Autonomous Zone (M effort) and can be executed by the daemon autonomously.
- **Outcome**: Pending — will evaluate when research docs are produced and talent plan is proposed
- **Learnings**: TBD

### DEC-005: Expand CTO autonomy, GitHub CI, proactive CTO backlog
- **Date**: 2026-02-11
- **Decider**: CEO (directed to CTO-Agent)
- **Context**: CEO flagged three issues: (1) daemon cycle prompt was too cautious — CTO should have full authority within the repo, (2) no GitHub remote — work should be continuously pushed, (3) CTO should proactively identify pre-product responsibilities beyond research.
- **Options considered**:
  1. Keep conservative daemon constraints, set up GitHub later — less risk but org stays timid
  2. Full autonomy with do-no-harm principle, GitHub now, proactive CTO backlog — matches CEO intent and gets the org moving
- **Decision**: Option 2 — expanded CTO Autonomous Zone (full repo authority with do-no-harm principle), public GitHub repo with auto-push, 5 new proactive backlog items (standards, tooling, market research, product vision, stress test)
- **Rationale**: CEO explicitly said "full permissions to do anything within the repo" and "first principle is do no harm." This is the right balance — autonomy with judgment. GitHub CI ensures work is backed up and visible. Proactive backlog ensures the CTO thinks like a real CTO/CPO, not just a task executor.
- **Outcome**: Pending — will evaluate after first autonomous cycle with expanded permissions
- **Learnings**: TBD

### DEC-006: CEO product direction — autonomous agents for data stack excellence
- **Date**: 2026-02-11
- **Decider**: CEO (communicated to CTO-Agent)
- **Context**: CEO shared initial product vision: "deploying an army of specialized agents that work 24/7 to make your company's data stack great and keep it that way." This is directional, not a commitment — CEO wants the org to explore and develop the idea proactively before the next meeting.
- **Options considered**:
  1. Wait for more specifics from CEO before researching — safe but wastes time
  2. Proactively explore the idea space — competitive landscape, technical feasibility, agent architecture, data stack pain points — and have informed findings ready for next CEO session
- **Decision**: Option 2 — CTO proactively researches the product idea across multiple dimensions. New backlog items added (BL-009 through BL-012). Existing research items (BL-001, BL-002) now have product context to focus them.
- **Rationale**: CEO explicitly asked for proactive exploration. The idea has strong signal: clear pain point (data stack fragility), natural agent decomposition (specialized agents per concern), high willingness-to-pay market. Research should validate or challenge these assumptions before next CEO meeting.
- **Outcome**: Pending — will evaluate when research docs are ready for CEO review
- **Learnings**: TBD

### DEC-007: CEO-CTO alignment — conversation mode, separate repos, operational evolution
- **Date**: 2026-02-12
- **Decider**: CEO (aligned with CTO-Agent)
- **Context**: After first autonomous cycle and several CEO sessions, a strategic conversation identified areas needing evolution: session behavior (CTO executes during conversations instead of being present), org/product boundary (directory isn't strong enough separation), activity visibility (CEO can't see what happened), and cloud deployment path.
- **Options considered**:
  1. Incremental patches — add features piecemeal as requested
  2. Comprehensive evolution — treat as significant org maturation, redesign across all affected areas atomically
- **Decision**: Option 2 — comprehensive evolution across 6 dimensions: (1) conversation vs execution mode, (2) /inbox skill for lightweight CEO check-ins, (3) enhanced activity logs, (4) separate git repos for products, (5) cloud deployment path documented, (6) new playbooks PB-017/018/019
- **Rationale**: Changes are interconnected — session behavior affects playbooks, separation affects architecture, logging affects daemon. Doing them atomically ensures consistency. Some topics (leadership principles, credit efficiency, org measurement) were flagged as ongoing discussions, not ready for codification.
- **Outcome**: Pending — will evaluate after first CEO session under new conversation mode and first daemon cycle with enhanced logging
- **Learnings**: TBD

### DEC-008: Cloud daemon via GitHub Actions + Claude Agent SDK harness
- **Date**: 2026-02-12
- **Decider**: CEO + CTO-Agent (aligned in conversation)
- **Context**: The org's daemon was running on the CEO's MacBook via launchd — but it had only ever run once, the PATH was broken so `claude` couldn't be found, and the org dies when the laptop sleeps. CEO directed: "put this in the cloud" and prioritized making the org genuinely 24/7 before all other work.
- **Options considered**:
  1. **GitHub Actions (scheduled workflow)** — zero infrastructure, YAML file in repo, ~$4/mo for private repo. Scheduling has 5-30min jitter and occasional dropped runs. Concurrency groups prevent overlap.
  2. **Google Cloud Run Jobs** — free tier, exact scheduling, no timeout concern. Requires GCP account, Docker container, Artifact Registry, Cloud Scheduler. More reliable but more setup.
  3. **Hetzner/DigitalOcean VM ($4/mo)** — cron is bulletproof, full control. You own the machine (OS updates, monitoring, recovery).
  4. **AWS Lambda** — disqualified: 15-minute hard timeout, daemon cycles can take 5-15min with no margin.
- **Decision**: GitHub Actions to start, with migration path to Cloud Run Jobs if reliability proves insufficient. Use Claude Agent SDK (not raw CLI) as the execution runtime for cost tracking, structured output, and observability. CLI remains the CEO's interactive interface.
- **Rationale**: GitHub Actions is the fastest path to cloud with zero infrastructure. The repo is already on GitHub. Scheduling jitter (5-30min) is irrelevant for 4-hour cycles. The SDK over CLI gives us cost visibility, turn limits, budget caps, and structured health reporting — all things we need to measure whether the org is alive. Concurrency groups prevent the >4h overlap risk CEO flagged. The harness writes `health.json` and per-cycle reports for liveness monitoring.
- **Architecture**:
  - CEO ↔ CTO: Claude Code CLI (interactive, conversation mode)
  - Org execution: Claude Agent SDK in GitHub Actions (headless, execution mode)
  - Persistence: Git repo (the only thing that survives between sessions)
  - Scheduler: GitHub Actions cron (every 4h) + manual dispatch
  - Observability: `daemon/health.json`, `daemon/reports/cycle-N.json`, CYCLE-LOG.md
- **Future considerations logged**:
  - Parallelism: multiple SDK instances can run but need coordination (separate repos or dispatcher). Not needed yet.
  - Concurrency overlap: GitHub Actions `concurrency` group queues (doesn't cancel) overlapping cycles.
- **Outcome**: Pending — will evaluate after 48h of cloud cycles running
- **Learnings**: TBD

### DEC-009: CEO-CTO contract evolution — retire gates, expand autonomy, improve visibility, greenlight product
- **Date**: 2026-02-14
- **Decider**: CEO (aligned with CTO-Agent)
- **Context**: CEO check-in covered three topics: (1) product direction — CEO likes dbt Guardian, wants dbt Core focus, wants pilot plan; (2) culture — CEO wants CTO to be 10x more proactive, own outcomes like a real CTO, adopt Amazon-style leadership principles; (3) CEO/CTO contract feels too restrictive but lacks visibility into progress.
- **Options considered**:
  1. Keep current directives and gates — safe but slows the org down and doesn't match CEO's desired operating rhythm
  2. Retire blocking directives, expand CTO product authority, dramatically improve visibility — matches CEO intent and unblocks product work
- **Decision**: Option 2 — comprehensive evolution:
  - **Retired DIR-001** (org infra before product) — infrastructure is solid, time to build
  - **Retired DIR-002** (AI expertise before product) — research done, learn by building
  - **Issued DIR-003** (ownership and bias for action) — permanent operating principle
  - **Product greenlit**: dbt Guardian, starting with dbt Core users (not dbt Cloud), Test Generator agent as first capability
  - **Pilot approach**: 1-2 design partners, mid-market, dbt Core + Snowflake/Postgres, 3-4 week prototype → 2-4 week pilot
  - **Visibility contract**: STATE.md becomes real-time dashboard with active work detail, CEO-INBOX.md used aggressively for unblocking
  - **Culture shift**: CTO owns outcomes, has strong POV, disagrees when warranted, drives without being asked
  - **Clarity commitment**: Keep research docs (what's true) cleanly separated from product specs (what we're building)
  - **Strategic framing**: "Work with the data stack, then hollow them out" — start alongside existing tools, make them interchangeable over time
- **Rationale**: The org has been in planning/research mode for 3 days. Infrastructure works. Research is done. The CEO is ready to build. Keeping gates up is the opposite of bias for action. The real risk now is moving too slowly, not moving too fast.
- **Outcome**: Pending — will evaluate after first product milestone (working Test Generator prototype)
- **Learnings**: TBD

### DEC-010: dbt Guardian is defensible against dbt Labs competition
- **Date**: 2026-02-15
- **Decider**: CTO-Agent
- **Context**: BL-018 (Defensibility analysis) — Before committing to pilot execution, need to validate whether dbt Guardian can build a sustainable business when dbt Labs (40K+ companies, $4.2B valuation, massive community) could theoretically build everything we're building. If dbt Labs is likely to ship competitive features in 6-12 months, we should pivot now rather than after pilot investment.
- **Options considered**:
  1. **Pivot to non-dbt-adjacent opportunity** — Avoid competing with dbt Labs entirely, focus on different data stack layer (ingestion, BI, orchestration). Reduces competitive risk but abandons dbt community advantage and requires new research.
  2. **Differentiate on dbt Cloud exclusivity** — Build for dbt Cloud only, partner with dbt Labs. Eliminates competition but creates dependency on dbt Labs' roadmap and pricing, limits TAM to Cloud users.
  3. **Execute dbt Core-first, cross-stack expansion strategy** — Start where dbt Labs won't go (operational agents for dbt Core users), expand where they can't go (cross-stack autonomous remediation). Requires speed but creates sustainable moat.
  4. **Wait and see** — Defer product commitment until dbt Labs' 2026 roadmap is fully clear. Reduces risk but wastes 3-6 months of first-mover advantage in an emerging category.
- **Decision**: Option 3 — Execute dbt Core-first strategy with cross-stack expansion path. Move fast to establish category leadership before potential competitive response (6-12 month window).
- **Rationale**: Web research (Feb 2026) reveals four structural constraints on dbt Labs that create permanent defensibility gaps:
  1. **Development > Operations focus**: dbt Labs' 2026 roadmap is entirely dev-focused (dbt Copilot for AI coding in IDE, dbt Explorer for catalog, dbt Semantic Layer for governance). Zero operational/incident response products. Their DNA is "empower analytics engineers to write code," not "fix code when it breaks."
  2. **Partnership ecosystem lock-in**: Strategic partnerships with Monte Carlo, Metaplane, Elementary (observability/monitoring) are revenue-critical. If dbt Labs builds full-stack observability/remediation, they compete with partners and destroy ecosystem value. Blog posts consistently position observability as partner territory.
  3. **dbt Core community tension**: Community actively resists dbt Cloud pricing ($100/seat/month) and feature gating. dbt Labs can't aggressively monetize Core users without backlash. Mid-market Core users are structurally underserved.
  4. **Enterprise governance mindset**: Enterprise customers (dbt Labs' revenue base) require human-in-loop for production changes. Autonomous remediation conflicts with compliance/audit requirements. dbt Labs unlikely to ship "auto-fix production" features that enterprises would disable.

  **Our path forward**: (1) Win dbt Core segment (next 6 months) — pilot with Core users, position as "operational layer dbt is missing," GitHub-first distribution. (2) Build autonomous capabilities dbt Labs won't (6-12 months) — continuous monitoring (not on-demand IDE), autonomous PR generation (not human-in-loop suggestions), production gap analysis. (3) Go cross-stack (12-18 months) — add Snowflake/Airflow integration, differentiate on "one agent for full stack."

  **Timing is critical**: Window is open NOW. dbt Labs focused on Copilot + Semantic Layer in 2026. Other well-funded startups likely pursuing same space. First-mover advantage matters for trust/safety moat (autonomous remediation requires track record).

  **Positioning strategy**: "The operational layer dbt is missing" (complement, not compete). "dbt Labs helps you write dbt code. Guardian keeps it reliable in production." Explicitly call out their strengths (Copilot for development, Semantic Layer for governance). Target dbt Core power users.
- **Outcome**: Pending — will evaluate after pilot results and 6-month market validation
- **Learnings**: Comprehensive defensibility analysis document created (`research/defensibility-analysis.md`, 8 sections, 9,000+ words) covering: dbt Labs roadmap, what they're NOT building, overlap analysis, strategic constraints, moat framework, threat scenarios (acquisitions, autonomous test gen, warehouse vendors, new startups), positioning strategy, tactical/strategic recommendations. LRN-016 captured. Strategic path validated for execution.

### DEC-011: Stay lean on specialist agents until PMF is validated
- **Date**: 2026-02-16
- **Decider**: CTO-Agent
- **Context**: BL-003 (Org talent & capability plan) — As the org enters product execution phase (pilot → v1.0 → cross-stack), need to define what specialist agents are required, when to hire them, and how to avoid premature team scaling before validating product-market fit.
- **Options considered**:
  1. **Hire specialists now** — Proactively hire Backend Specialist (agent orchestration), QA Specialist, Data Engineer to build parallel capacity and accelerate delivery. Enables faster execution but adds $270-450/month cost and 4-6 hours/week management overhead before we know if the product has PMF.
  2. **Hire incrementally as capabilities are needed** — Add specialists when specific features require expertise CTO-Agent lacks (e.g., hire Data Engineer when Airflow integration starts). Reduces premature cost but may create delivery bottlenecks if hiring takes 2+ weeks.
  3. **Stay lean (CTO solo) until execution bottleneck or PMF validation** — CTO-Agent handles all work through pilot and v1.0. Hire only when triggered by: (a) execution bottleneck (can't deliver on roadmap), (b) specialized expertise gap (capability CTO doesn't have), (c) operational scale (customer volume requires support), or (d) quality/velocity trade-off. Maximizes efficiency and defers hiring cost/complexity until constraints are proven.
  4. **Hire PM and QA immediately, defer technical specialists** — Add Product Manager Agent to handle customer research and QA Specialist to ensure quality, but keep technical work with CTO-Agent. Balances quality/customer focus with technical efficiency but splits strategic context across roles early.
- **Decision**: Option 3 — Stay lean (CTO-Agent solo) through pilot (Month 0-3). Reassess after pilot synthesis with actual execution data. Hire Data Engineer Agent at Month 6-9 when cross-stack work begins (FIRST must-hire). Hire SaaS team (Frontend/DevOps/Security) at Month 9-12 if SaaS product is greenlit.
- **Rationale**: Analyzed dbt Guardian roadmap against CTO-Agent current capabilities and found NO blocking capability gaps for next 6 months:
  - **Test Generator pilot (Month 0-3)**: Requires backend (Python), dbt domain, pilot execution — CTO-Agent has all ✅. Performance to date: 14/14 backlog items completed on time (100% delivery rate), 35+ unit tests, comprehensive documentation, zero rework. No execution bottleneck.
  - **v0.2-0.3 with PR automation (Month 1-3)**: Requires GitHub API + dbt Cloud API integration — within CTO-Agent capability ✅. No specialized expertise needed.
  - **Multi-agent orchestration v1.0 (Month 3-6)**: Requires agent framework knowledge (LangGraph or Claude SDK) — CTO researched in BL-002, can architect and implement ✅. Optional Backend Specialist hire if complexity bottlenecks delivery, but not required upfront.
  - **Cross-stack expansion (Month 6-12)**: Requires deep Airflow/Snowflake/Looker domain knowledge — this is FIRST true capability gap. Hire Data Engineer Agent then.
  - **SaaS product (Month 9-12, if greenlit)**: Requires frontend (React), DevOps (Kubernetes), security (compliance) — hire 3-4 specialists then.

  Defined 7 specialist roles in detail at `org/talent-capability-plan.md`: Backend Specialist (Agent Orchestration), Data Engineer Agent, Frontend Engineer Agent, DevOps Engineer Agent, QA Specialist Agent, Product Manager Agent, Security Engineer Agent. Each role has: scope, hiring trigger, tools, reporting structure, success criteria. Estimated cost: $90/month per agent (Claude API), scaling from $90 (current) to $630 (7-agent SaaS team). Human review overhead: ~2 hours/week per specialist. At 6+ agents, CTO becomes full-time manager (may need Engineering Manager Agent).

  **Key insight**: Hiring before PMF is premature optimization. The risk is NOT "we can't execute fast enough" (CTO is delivering on all commitments) — the risk is "we hire a team and then pivot because pilot reveals we're building the wrong thing." Stay lean, move fast, validate PMF, THEN scale the team based on actual constraints (not hypothetical needs).

  **Hiring triggers defined**: (1) Execution bottleneck — CTO can't deliver on roadmap due to lack of parallel capacity, (2) Specialized expertise gap — capability requires deep domain knowledge CTO doesn't have and would take >1 month to learn, (3) Operational scale — customer volume requires dedicated support, (4) Quality/velocity trade-off — shipping speed constrained by insufficient testing/review.

  **Reassessment gates**: (a) After pilot synthesis (end of Month 3) — use real execution data to validate hiring timeline, (b) Quarterly reviews — update talent plan based on product roadmap changes, (c) When any hiring trigger is met — hire immediately, don't wait for next planning cycle.
- **Outcome**: Pending — will evaluate after pilot synthesis (BL-020) with actual data on execution bottlenecks, customer needs, and PMF validation
- **Learnings**: Comprehensive talent plan created at `org/talent-capability-plan.md` (11 sections, 400+ lines): current state assessment, 7 specialist roles with hiring triggers, sequencing timeline (Month 0-3 solo → Month 6-9 Data Engineer → Month 9-12 SaaS team), cost analysis, org structure evolution, alternative staffing models (consultant agents, human specialists, hybrid model), decision framework, success metrics, open questions for CEO. LRN-019 captured. Pattern: define roles and triggers BEFORE you need them → hire quickly when triggered.

---
*Update protocol: Number decisions sequentially. Update outcomes retroactively. Link decisions from STATE.md when they affect current context. Reference decisions from CHARTER.md changelog when they modify governance.*
