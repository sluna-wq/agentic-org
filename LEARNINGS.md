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

---
*Update protocol: Add entries after completing any work item, resolving any incident, or running any experiment. Entries are append-only — never delete a learning, even if it's later superseded (add a note instead). Tag entries for searchability. Review during PB-003 (Weekly Planning).*
