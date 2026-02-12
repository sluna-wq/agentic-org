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

---
*Update protocol: Number decisions sequentially. Update outcomes retroactively. Link decisions from STATE.md when they affect current context. Reference decisions from CHARTER.md changelog when they modify governance.*
