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

---
*Update protocol: Add entries after completing any work item, resolving any incident, or running any experiment. Entries are append-only — never delete a learning, even if it's later superseded (add a note instead). Tag entries for searchability. Review during PB-003 (Weekly Planning).*
