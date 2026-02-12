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

---
*Update protocol: Number decisions sequentially. Update outcomes retroactively. Link decisions from STATE.md when they affect current context. Reference decisions from CHARTER.md changelog when they modify governance.*
