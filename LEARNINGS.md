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

---
*Update protocol: Add entries after completing any work item, resolving any incident, or running any experiment. Entries are append-only — never delete a learning, even if it's later superseded (add a note instead). Tag entries for searchability. Review during PB-003 (Weekly Planning).*
