# Decision Log

> Material decisions with context, options, and rationale. Add new entries. Update outcomes retroactively.

---

## Summary: DEC-001 through DEC-009
Bootstrap decisions (2026-02-11 through 2026-02-14). Full text in git history.

| # | Decision | Outcome |
|---|----------|---------|
| DEC-001 | Interlocking markdown org (STATE.md as entry point) | Working |
| DEC-002 | Explicit CEO↔Org and Org↔Product interfaces | Partially — interfaces simplified in DEC-013 |
| DEC-003 | Three interfaces + daemon + skills + CTO Autonomous Zone | Working |
| DEC-004 | AI expertise research before product | Complete — research done, pivoted to walkthroughs |
| DEC-005 | Full repo autonomy for CTO, do-no-harm principle | Working |
| DEC-006 | CEO product direction: agents for data stack | Evolved → DEC-012 |
| DEC-007 | Conversation mode, separate repos, activity logging | Working |
| DEC-008 | Cloud daemon via GitHub Actions + Claude Agent SDK | Pending — daemon needs credits/PAT (BL-013) |
| DEC-009 | Retire gates, expand CTO autonomy, greenlight dbt Guardian | Evolved → DEC-012 |

---

### DEC-010: dbt Guardian is defensible vs dbt Labs
- **Date**: 2026-02-15
- **Decision**: Execute dbt Core-first strategy. dbt Labs has structural constraints (dev-focused DNA, partner ecosystem lock-in, community tension on pricing, enterprise governance mindset) that create a 6-12 month window for operational agents.
- **Outcome**: Pending — strategy superseded by DEC-012 (walkthroughs first). Will revisit after WT-10.

### DEC-011: Stay lean on specialist agents until PMF
- **Date**: 2026-02-16
- **Decision**: CTO-Agent solo through discovery. First hire: Data Engineer Agent at Month 6-9 when cross-stack work begins.
- **Outcome**: Active — no capability gaps for current work.

### DEC-012: Pivot to walkthrough-driven discovery
- **Date**: 2026-02-16
- **Deciders**: CEO + CTO
- **Context**: WT-01 showed dbt Guardian Test Generator caught almost nothing on a realistic project. A general agent conducting a full DE investigation found everything. Fundamental question: if agents can already do full DE work, why build a narrow tool?
- **Decision**: Pause product shipping. Run 10 DE walkthroughs (CEO + CTO together). CEO learns DE reality, CTO learns agent requirements, both learn deployment barriers. Product direction emerges from WT-10 synthesis.
- **Outcome**: In progress — WT-01 through WT-03 complete.

### DEC-013: Org simplification — CEO.md single interface, prune everything
- **Date**: 2026-02-17
- **Deciders**: CEO + CTO
- **Context**: Observable bloat. Async split across 3 files. 20 playbooks, 5 used. Dead files accumulating.
- **Decision**: CEO.md as single async interface. PLAYBOOKS.md pruned to 5 active. BRIEFING.md, METRICS.md, ROSTER.md, WORKBENCH.md, CEO-GUIDE.md, PLAYBOOKS-ARCHIVE.md deleted. BACKLOG.md and DECISIONS.md compressed. DIR-004 applied to org process itself.
- **Outcome**: Implemented this session.

---
*New decisions go here. Update outcomes when results are known.*
