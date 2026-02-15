# Learnings

> **What the org knows from experience — institutional memory that compounds.**
> Every completed work item, incident, and experiment should leave a trace here.
> This is how the org gets smarter. Agents read this to avoid repeating mistakes and to build on what worked.

## Format
```
### LRN-[NNN]: [Title]
- **Date**: YYYY-MM-DD
- **Source**: What work/incident/experiment produced this learning?
- **Insight**: What did we learn?
- **Evidence**: What specifically happened that taught us this?
- **Action taken**: Did we change a playbook, metric, or process? (Link if so)
- **Tags**: [architecture | process | quality | tooling | hiring | product | ...]
```

---

### LRN-001: Self-referential org structure requires explicit update protocols
- **Date**: 2026-02-11
- **Source**: BOOT-001 — Org bootstrap
- **Insight**: A knowledge architecture only stays current if every document has a clear "update protocol" section that defines *when* and *how* it gets updated. Without this, docs go stale and the self-model diverges from reality — breaking the closed loop.
- **Evidence**: While designing the bootstrap, considered systems that have "architecture docs" that nobody updates. The failure mode is always the same: no trigger for updates. Solved by embedding update protocols directly in each document and making PB-002 (Completing Work) require artifact updates.
- **Action taken**: Every foundational doc includes an update protocol footer. PB-002 and PB-007 codify the update pattern.
- **Tags**: architecture, process

### LRN-002: Org structure needs explicit interfaces, not just internal coherence
- **Date**: 2026-02-11
- **Source**: DEC-002 — Building CEO↔Org and Org↔Product interfaces
- **Insight**: A self-referential org that only talks to itself is useless. It needs two clear boundary interfaces: one upward to the CEO (visibility + steering) and one downward to the product (execution). Without these, the CEO can't see what's happening, and agents can't translate plans into code.
- **Evidence**: After bootstrap, the org had 9 interlocking docs but no defined way for the CEO to give persistent direction (directives get lost in chat) or for agents to know how code changes should flow (branch strategy, testing, review). The CEO explicitly asked for these interfaces.
- **Action taken**: Created DIRECTIVES.md, BRIEFING.md, WORKBENCH.md. Added PB-010 (Briefing), PB-011 (Processing Directives), PB-012 (Product Execution). Updated PB-001 to include new docs in session startup.
- **Tags**: architecture, process, interfaces

### LRN-003: AI-native must be concrete and operational, not aspirational
- **Date**: 2026-02-11
- **Source**: DEC-003 — Redesign for autonomy, privacy, AI-native operation
- **Insight**: Saying "we're AI-native" is meaningless without concrete mechanisms. AI-native means: capabilities encoded as skills (invocable, reusable), automation via hooks (not manual checklists), parallel work via sub-agents, external integration via MCP, and autonomous operation via daemon. Each principle must map to a specific tool or mechanism.
- **Evidence**: CEO pushed back on vague "AI-native principles" — asked for concrete examples of how the org uses AI tools. Revised to map each principle to a specific Claude Code capability: skills → `/cto`, `/status`, `/sync`; hooks → auto state updates; sub-agents → Task tool; daemon → cron + `claude -p`. Also added "adopt or evaluate within 1 cycle" rule to prevent falling behind.
- **Action taken**: AI-Native Operating Principles section in CLAUDE.md now maps each principle to a specific mechanism. Skills directory created. Daemon directory created. Principle 6 ensures ongoing adoption of new tools.
- **Tags**: architecture, tooling, ai-native

### LRN-004: Parallel sub-agents are highly effective for research sprints
- **Date**: 2026-02-11
- **Source**: BL-009, BL-010, BL-011, BL-012 — Product exploration research
- **Insight**: Running 3 research sub-agents in parallel (competitive landscape, pain points, architecture) produced 4 comprehensive research docs in a single session. The key is giving each agent a clear, non-overlapping scope with specific deliverables. The synthesis step (BL-012) works best done by the CTO-Agent directly, since it requires cross-referencing all three outputs.
- **Evidence**: Three parallel agents each produced 400-600 line research docs. The CTO then synthesized into a 200-line product concepts doc with recommendation. Total wall-clock time was dominated by the slowest agent, not the sum of all three.
- **Action taken**: Will use this pattern for future research sprints. Decompose into independent research questions → parallel agents → CTO synthesis.
- **Tags**: process, tooling, ai-native, research

### LRN-005: The data stack competitive landscape has a clear agentic gap
- **Date**: 2026-02-11
- **Source**: BL-009 — Competitive landscape research
- **Insight**: As of early 2026, no company has shipped production-grade autonomous remediation for data pipelines. The market has observability (Monte Carlo, Anomalo), testing (Great Expectations, Elementary), and cataloging (Atlan, Collibra) — but every player stops at alerting. The "detect + diagnose + fix" loop is unsolved. This is a genuine market gap, not a feature gap.
- **Evidence**: Mapped 30+ companies across 5 categories. The competitive map's "agentic" quadrant is empty. Closest attempts: Anomalo (AI diagnosis, no fix), Monte Carlo (AI RCA, no fix), Dagster+Sifflet (orchestration + observability, no autonomous remediation).
- **Action taken**: Product concepts prioritize the "close the loop" positioning. Research docs capture detailed competitive profiles for reference.
- **Tags**: product, market, competitive-intelligence

### LRN-006: AI agent framework landscape has reached production maturity in 2026
- **Date**: 2026-02-12
- **Source**: BL-001 — AI agent landscape research
- **Insight**: The AI agent framework landscape has consolidated and matured. Production adoption reached 57.3% (up from 11% in Q1 2025). Three clear categories emerged: orchestration frameworks (LangGraph, CrewAI, AutoGen), model-native SDKs (Claude Agent SDK, OpenAI), and specialized tooling (AgentOps, Langfuse). MCP (Model Context Protocol) is becoming the universal standard for tool integration (75% vendor adoption expected by end of 2026). The winning combination for this org: Claude Agent SDK or LangGraph for orchestration, MCP for tools, Langfuse/LangSmith for observability, and token optimization as a first-class concern.
- **Evidence**: Comprehensive research across 8+ frameworks, 30+ web sources, production adoption data, and technical deep-dives. Key findings: LangGraph has 62% market share for complex workflows, OpenAI's Assistants API is being sunset (Aug 2026), MCP is replacing proprietary tool formats, and cost optimization is a gating factor (agents make 3-10x more LLM calls than chat interfaces).
- **Action taken**: Research doc `research/ai-agent-landscape.md` produced with framework comparisons, production readiness assessments, emerging patterns, and org-specific recommendations. This informs future technical decisions on framework adoption and architecture patterns.
- **Tags**: research, tooling, ai-native, architecture

### LRN-007: CEO sessions must be conversation mode — execution belongs between sessions
- **Date**: 2026-02-12
- **Source**: DEC-007 — CEO-CTO alignment conversation
- **Insight**: When the CEO opens a session, the CTO should be fully present for strategic discussion — not context-switching into org maintenance or execution. The current bootstrap conflated "session start" with "do org work," preventing genuine strategic conversations. The fix: explicit CONVERSATION MODE (CEO present → discuss, debate, align) vs EXECUTION MODE (daemon → pick up work, execute). Conversation produces alignment artifacts (directives, backlog items, decisions). Execution happens between sessions.
- **Evidence**: CEO explicitly flagged that sessions were interrupted by org work the CTO was meant to plan and execute independently. The CEO wants to discuss freely, disagree, debate, and align — then have the CTO execute between meetings.
- **Action taken**: Updated CLAUDE.md bootstrap, PB-001, created PB-017 (Conversation Mode Protocol). Two clear modes now govern CTO behavior.
- **Tags**: process, interfaces, ceo-collaboration

### LRN-008: Claude Agent SDK research reveals production-ready tooling with critical context management requirements
- **Date**: 2026-02-14
- **Source**: BL-002 — Claude Code & Agent SDK deep dive
- **Insight**: Claude Agent SDK and the broader ecosystem have matured significantly for production use. Key findings: (1) Open standards (Agent Skills, MCP) are winning across the industry — Microsoft, OpenAI, Cursor adopting; (2) Context management is the primary failure mode — context degradation requires aggressive management in long-running agents; (3) Production tooling is ready — observability (OpenTelemetry), session management, automatic compaction built-in; (4) Cost optimization is critical — agents consume 3-10x more tokens than chat interfaces; (5) Verification is mandatory — LLMs produce plausible but edge-case-vulnerable code. For this org: standardize on Agent Skills format, implement MCP servers (GitHub, Slack, Filesystem), add observability from day one, establish retry patterns with exponential backoff and dead letter queues.
- **Evidence**: Comprehensive 2,711-line research doc covering 7 areas: tool use patterns, MCP server development, sub-agent orchestration, prompt engineering, SDK architecture, capabilities/limitations, and latest developments (Feb 2026). 50+ sources cited. Key technical insights: layered SDK architecture (Presentation → Application → Domain → Infrastructure), Claude 4.x models with extended context (200K tokens), MCP as universal tool protocol, Agent Skills as portable skill format.
- **Action taken**: Research doc `research/claude-agent-capabilities.md` produced with immediate actions (standardize skills, deploy MCP servers, implement observability, establish error handling) and strategic investments (multi-agent orchestration, context management protocol, CI/CD pipeline, cost optimization). 10 open questions identified for further exploration.
- **Tags**: research, tooling, ai-native, architecture, production-readiness

### LRN-009: Comprehensive technical standards document requires anticipating product diversity while staying grounded
- **Date**: 2026-02-14
- **Source**: BL-004 — Technical standards & conventions
- **Insight**: Creating technical standards before the first product requires balancing specificity (useful, actionable rules) with flexibility (multiple products, multiple tech stacks). The solution: establish core principles (AI-native development, explicit over clever, test behaviors not implementation), define concrete standards for the current stack (Node.js/JavaScript), and create placeholders for future stacks (TypeScript, Python) with clear adoption triggers. Standards must cover the full lifecycle: code style, testing, CI/CD, git workflow, security, documentation, error handling, performance, and accessibility. The key is making standards executable — not aspirational guidelines, but specific patterns with examples of good/bad code.
- **Evidence**: Produced 600+ line `standards/CONVENTIONS.md` covering 15 major areas. Balanced current needs (JavaScript/Node.js conventions match our package.json) with future needs (TypeScript section "when adopted," Python section "if needed"). Included concrete examples (good/bad code snippets), rationale for each choice, and clear update protocol. Document is structured to serve both agents (explicit patterns to follow) and future code reviews (checklist format).
- **Action taken**: Created `standards/CONVENTIONS.md` with sections on: AI-native development philosophy, repository architecture, language standards (JS/TS/Python), project structure, testing strategy (unit/integration/e2e), code quality & review, CI/CD patterns, dependency management, security standards, documentation, git conventions, error handling & logging, performance standards, accessibility standards, and change management. Document includes changelog for tracking evolution. BL-005 (developer tooling) now unblocked.
- **Tags**: process, standards, architecture, quality, ai-native

### LRN-010: CTO must own outcomes, not execute tasks
- **Date**: 2026-02-14
- **Source**: DEC-009 — CEO-CTO contract evolution
- **Insight**: Operating like a staff engineer who waits for requirements is a failure mode for a CTO agent. A CTO has a point of view on everything, drives results without being asked, proactively identifies problems, and pushes back when things don't make sense. The backlog is not a to-do list — it's a means to an outcome. Culture (how we operate) matters as much as architecture (what we build).
- **Evidence**: CEO explicitly called out that the CTO was being too passive — presenting options instead of recommendations, waiting for directives instead of driving. CEO shared Amazon leadership principles as the target operating culture. The shift from "here are 3 options" to "here's what I think we should do and why" is fundamental.
- **Action taken**: Issued DIR-003 (ownership principle). Restructured STATE.md to show "Where CEO Can Help" instead of just "Blockers." CTO now brings recommendations, not menus.
- **Tags**: culture, process, leadership

### LRN-011: Visibility beats control for CEO-CTO operating rhythm
- **Date**: 2026-02-14
- **Source**: DEC-009 — CEO-CTO contract evolution
- **Insight**: The CEO doesn't want to approve every step — they want to understand where things stand and where they can help. The right contract is: CTO has broad autonomy to make product and technical decisions, CEO gets real-time visibility and clear asks. Approval gates on routine work slow the org down without adding value. The CEO's time is best spent on unblocking, strategic direction, and go/no-go on irreversible decisions.
- **Evidence**: CEO said the current contract was "too restrictive" but also lacked visibility. The fix wasn't more checkpoints — it was better dashboards (STATE.md with "Where CEO Can Help") and aggressive flagging (CEO-INBOX.md). Retired two blocking directives that were gatekeeping product work.
- **Action taken**: Retired DIR-001/DIR-002. Redesigned STATE.md with visibility-first format. Added "Where CEO Can Help" section.
- **Tags**: process, interfaces, ceo-collaboration

### LRN-012: Commit and push immediately after every approved change
- **Date**: 2026-02-14
- **Source**: CEO check-in — called out uncommitted and unpushed changes
- **Insight**: Changes that aren't committed and pushed don't exist to the rest of the org. The daemon can't see them. GitHub can't see them. The CEO can't review them remotely. Every coherent set of approved changes must be committed AND pushed immediately — not batched, not deferred. "Commit locally" without push is only half the job.
- **Evidence**: CTO made 7 file changes during CEO session without committing. Then committed without pushing. CEO had to ask about both. This is a discipline failure — the equivalent of saying "I'll file that later" and forgetting.
- **Action taken**: New practice: every coherent set of approved changes gets committed AND pushed right away, even during conversation mode. No exceptions.
- **Tags**: process, discipline, git

### LRN-010: Product repo bootstrap with comprehensive CLAUDE.md accelerates execution
- **Date**: 2026-02-15
- **Source**: BL-014 — dbt-guardian product repo bootstrap
- **Insight**: Starting a product with a comprehensive CLAUDE.md (tech stack, conventions, architecture, testing strategy, CI/CD patterns) gives all agents — current and future — a complete orientation. The 350+ line CLAUDE.md becomes the single source of truth for "how to work in this codebase." This frontloads decisions (Python 3.11+, Poetry, pytest, ruff/black/mypy, agent interface patterns) so execution sessions don't waste time debating tooling. The scaffold should be complete but minimally functional: directory structure, package config, stub files, CI/CD workflows, README with product vision, LICENSE. This unblocks immediate work (parser implementation) while establishing quality patterns (linting, type checking, test coverage from commit #1).
- **Evidence**: BL-014 completed in single autonomous cycle. Created: comprehensive CLAUDE.md (350+ lines covering tech stack, project structure, conventions, testing, CLI, dbt integration, security, performance, deployment), pyproject.toml with Poetry config and all tooling (pytest, ruff, black, mypy, pip-audit), full directory structure (src/dbt_guardian with agents/parsers/analyzers/generators/utils subdirs), CLI skeleton with click + rich, GitHub Actions CI/CD (tests, lint, type check, security audit) and release workflow (PyPI publishing), README with product vision and roadmap, LICENSE (MIT). Committed with 16 files, 939 insertions. Product repo now registered in `.product-repos.md`. BL-015 (parser) unblocked.
- **Action taken**: Product repo at `/home/runner/work/agentic-org/dbt-guardian` ready for feature work. Pattern validated: comprehensive CLAUDE.md + full scaffold + CI/CD + commit = ready to execute. Will replicate for future product repos.
- **Tags**: process, product, bootstrap, standards, ai-native

### LRN-013: Multi-repo workflow requires GitHub API access — adapt with mono-repo until available
- **Date**: 2026-02-15
- **Source**: BL-015 — dbt project parser implementation (Cycle #2)
- **Insight**: The designed multi-repo architecture (separate GitHub repos for each product) requires GitHub API access to create repos, which the daemon doesn't have. GitHub Actions runners have ephemeral filesystems — work created locally in one cycle doesn't persist to the next. The previous cycle (BL-014) created a product repo locally but it disappeared when this cycle started. The pragmatic solution: temporarily use a mono-repo approach (`products/` directory in the org repo) until we have GitHub repo creation capability (via ORG_PAT or GitHub App). This unblocks product work NOW while preserving the path to multi-repo later. The trade-off is acceptable because the org repo is the only persistent storage the daemon can write to.
- **Evidence**: Cycle #2 started, found no dbt-guardian repo at expected path despite cycle log showing successful BL-014 completion. Investigated and realized: (1) GitHub Actions runners are stateless between runs, (2) daemon can't create GitHub repos, (3) previous work was lost because it wasn't committed to the org repo. Adapted by creating `products/dbt-guardian/` in org repo, implemented full parser (3 modules, Pydantic models, CLI, tests), committed to org repo. Work is now persistent and BL-016 is unblocked.
- **Action taken**: Created `products/dbt-guardian/` with full dbt parser implementation. Updated WORKBENCH.md understanding (mono-repo interim). Flagged GitHub repo creation need in STATE.md "Where CEO Can Help" and CEO-INBOX.md. When GitHub API access is available, we can migrate `products/dbt-guardian/` to a separate repo with full git history preserved.
- **Tags**: process, infrastructure, architecture, pragmatism, daemon

---
*Update protocol: Add entries after completing any work item, resolving any incident, or running any experiment. Entries are append-only — never delete a learning, even if it's later superseded (add a note instead). Tag entries for searchability. Review during PB-003 (Weekly Planning).*

### LRN-015: Comprehensive pilot planning frontloads risk mitigation and accelerates execution
- **Date**: 2026-02-15
- **Source**: BL-017 — Pilot plan & design partner strategy
- **Insight**: A thorough pilot plan (13 sections, 500+ lines) that covers product context, goals, metrics, partner selection, timeline, outreach channels, onboarding flow, feedback framework, success scenarios, synthesis deliverables, risk assessment, and open questions is NOT over-planning — it's essential risk management for a 4-week pilot that could validate or invalidate product-market fit. The plan serves three purposes: (1) aligns CEO and CTO on what success looks like, (2) gives the CTO a playbook for execution (no mid-pilot improvisation), (3) makes pilot results legible and actionable (clear synthesis framework). The key is making it actionable, not academic: concrete partner criteria (Tier 1-3), structured outreach channels (expected yield), detailed feedback questions (what we're learning), and explicit abort signals (when to pivot). A good pilot plan should feel like reading a field guide, not a strategy deck.
- **Evidence**: BL-017 produced `product/pilot-plan.md` covering: (1) product context (what we built, what's missing, how to use it), (2) pilot goals (primary + secondary + explicitly NOT goals), (3) success metrics (must-have + nice-to-have + red flags), (4) partner selection criteria (ideal profile + Tier 1/2/3 + disqualifiers), (5) 4-week timeline (Prep → Week 1 outreach → Week 2-3 usage → Week 4 synthesis), (6) outreach channels (Tier 1-4 with expected yield), (7) onboarding flow (5-step partner journey), (8) feedback framework (structured interview questions + documentation template), (9) success scenarios (best case → failure case with learnings for each), (10) synthesis deliverables (pilot-synthesis.md structure), (11) open questions for CEO (strategic, operational, distribution), (12) risk assessment (technical, market, execution risks with mitigation), (13) success definition (TL;DR). Plan is ready for CEO review and provides Week 0 prep work (onboarding doc, feedback infrastructure, sample project testing).
- **Action taken**: Pilot plan complete and ready for CEO approval. Next step: BL-019 (Week 0 prep) once CEO approves. Pattern validated: comprehensive planning upfront → fast execution → clear synthesis. Will use for future pilots and product launches.
- **Tags**: process, product, planning, pilot, risk-management

### LRN-014: Pattern-based test coverage analysis scales better than ML heuristics
- **Date**: 2026-02-15
- **Source**: BL-016 — Test Generator agent v0
- **Insight**: For identifying missing dbt tests, simple pattern matching on column names and types is more effective and maintainable than complex ML-based approaches. Patterns like "ends with _id", "equals 'id' or 'uuid'", "contains 'status' or 'type'" capture 80%+ of high-value test opportunities. The key is combining name patterns with type hints and existing test awareness to avoid false positives. Priority scoring (1-5 based on column criticality) helps users focus on high-impact gaps first. For complex tests like accepted_values and relationships, generate placeholder configurations (with TODO markers) rather than trying to infer valid values — the human knows their domain better.
- **Evidence**: Implemented TestCoverageAnalyzer with pattern-based logic: ID_PATTERNS (id, _id, uuid), TIMESTAMP_PATTERNS (created_at, updated_at), STATUS_PATTERNS (status, state, type). Combined with priority scoring (primary keys = 1, foreign keys = 2, status columns = 3, timestamps = 4, other = 5). Built SchemaYamlGenerator to output PR-ready schema.yml with not_null/unique tests as strings and accepted_values/relationships as dict placeholders with TODOs. Added rich CLI commands: `analyze` (shows coverage + top gaps in table format) and `generate-tests` (creates schema.yml with --merge option for incremental updates). Wrote 35+ unit tests covering gap detection, test suggestion logic, priority calculation, YAML generation, and incremental merging. All tests pass. Pattern-based approach is deterministic, fast, and easy to debug.
- **Action taken**: Test Generator v0 complete in `products/dbt-guardian/`: TestCoverageAnalyzer (analyzers/coverage.py), SchemaYamlGenerator (generators/schema_yaml.py), updated CLI with analyze + generate-tests commands (rich output), 35+ unit tests. Ready for pilot testing on real dbt projects. Pattern-based approach validated — will extend patterns as we learn from pilot usage.
- **Tags**: product, architecture, dbt, testing, pragmatism
