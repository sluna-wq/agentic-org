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

---
*Update protocol: Number decisions sequentially. Update outcomes retroactively. Link decisions from STATE.md when they affect current context. Reference decisions from CHARTER.md changelog when they modify governance.*
