# Learnings

> Institutional memory. Add entries after completing work or learning something material. Full entries in git history.

---

## Summary: LRN-001 through LRN-023
Bootstrap and product-build learnings (2026-02-11 through 2026-02-15). Full text in git history.

| # | Learning |
|---|----------|
| LRN-001 | Every doc needs an explicit update protocol or it goes stale |
| LRN-002 | Org needs explicit interfaces upward (CEO) and downward (product) |
| LRN-003 | AI-native must map to concrete mechanisms — not aspirational |
| LRN-004 | Parallel sub-agents excel at research sprints |
| LRN-005 | Data stack has a clear agentic gap — operational agents, not dev tools |
| LRN-006 | AI agent frameworks reached production maturity in 2026 |
| LRN-007 | CEO sessions = conversation mode; execution happens between sessions |
| LRN-008 | Claude Agent SDK production-ready; context management is the critical constraint |
| LRN-009 | Comprehensive standards upfront reduce rework |
| LRN-010 | Thorough product CLAUDE.md accelerates agent execution |
| LRN-011 | Visibility beats control for CEO-CTO rhythm |
| LRN-012 | Commit and push immediately after every approved change |
| LRN-013 | Multi-repo workflow needs GitHub API — mono-repo until available |
| LRN-014 | Pattern-based test coverage analysis scales better than ML heuristics |
| LRN-015 | Comprehensive pilot planning frontloads risk mitigation |
| LRN-016 | dbt Labs' structural constraints create a defensibility window for operational agents |
| LRN-017 | Opinionated developer tooling from day one accelerates onboarding |
| LRN-018 | Proactive pilot infrastructure prep unblocks when approvals arrive |
| LRN-019 | Stay lean on specialist agents until PMF is validated |
| LRN-020 | Regular org audits catch drift early |
| LRN-021 | End-to-end testing before pilot de-risks launch |
| LRN-022 | Proactive bug fixes from validation improve quality |
| LRN-023 | Auto-inferring relationship test targets improves UX |

---

### LRN-024: Narrow product catches nothing — general agent investigates everything
- **Date**: 2026-02-16 | **Source**: WT-01
- **Insight**: dbt Guardian Test Generator suggested generic `not_null` tests. The same agent acting as a general DE investigator found NULL semantics bugs, multi-currency mixing, and duplicate payments. Narrow product was solving the wrong problem. Capability isn't the barrier — deployment is.

### LRN-025: The question is deployment, not capability
- **Date**: 2026-02-16 | **Source**: WT-01
- **Insight**: Agents can already do full DE investigations. The open question is: what stops organizations from deploying them? That's what the walkthroughs are for.

### LRN-026: Learn by doing beats learn by researching
- **Date**: 2026-02-16 | **Source**: WT-01 + CEO feedback
- **Insight**: Weeks of research led to a product that caught nothing. One walkthrough session triggered a strategic pivot. Experiencing the DE role firsthand produces more actionable insight than any research doc.

### LRN-027: Lost session state = lost work
- **Date**: 2026-02-16 | **Source**: Process failure
- **Insight**: Pivot session committed walkthrough files but skipped all state updates. Next session had completely stale context. PB-020 (Session Close Protocol) created as mandatory fix.

### LRN-028: Use idle daemon cycles for strategic documentation
- **Date**: 2026-02-17 | **Source**: Cycle #13
- **Insight**: When backlog requires CEO participation, use cycle time to preserve strategic reasoning. Prevents insight decay between sessions.

### LRN-029: Apply DIR-004 to org process, not just code
- **Date**: 2026-02-17 | **Source**: Cycle #16 audit
- **Insight**: 16 cycles of usage data showed 75% of playbooks never referenced. Evidence-based simplification: archive what's not earning its keep. It's reversible.

### LRN-030: Highest-value agent DE capability is continuous reconciliation
- **Date**: 2026-02-17 | **Source**: WT-02
- **Insight**: Acme had 4 passing tests and a 33% revenue error — all silent. Caught only when VP manually compared dashboard to Stripe. Continuous reconciliation (pipeline output vs external source of truth) catches this on day one. "Tell me when my numbers are wrong" is the real product.

### LRN-031: Test intent, not metrics
- **Date**: 2026-02-17 | **Source**: WT-02
- **Insight**: Threshold tests ("don't drop more than 10% of rows") are brittle and arbitrary. Intent-based tests ("every non-test order appears in staging") are stable and catch real bugs. Agents should generate intent-based tests.

### LRN-032: DE investigation methodology is fully automatable
- **Date**: 2026-02-17 | **Source**: WT-02
- **Insight**: The entire revenue investigation was a mechanical decision tree: compare row counts at each DAG layer → find the drop → read SQL → match to known bug pattern. No intuition required. Manifest + systematic queries + bug pattern library = autonomous investigation.

### LRN-033: Source onboarding is 80% template, 20% judgment
- **Date**: 2026-02-17 | **Source**: WT-03
- **Insight**: Staging models are copy-paste from raw schema. The 20% requiring human judgment: entity resolution thresholds, attribution model choice, target metrics. Ideal agent shape: automate the 80%, surface 3-4 decisions, execute the rest.

### LRN-034: Entity resolution is a well-defined escalation boundary
- **Date**: 2026-02-17 | **Source**: WT-03
- **Insight**: Agent builds match table with confidence scores, auto-merges high confidence, escalates ambiguous. False positives worse than false negatives — conservative default. Human decides ambiguous cases, agent executes.

### LRN-035: Single async interface beats distributed channels
- **Date**: 2026-02-17 | **Source**: CEO session feedback
- **Insight**: CEO couldn't see pending items, status, and recent activity without reading 3 separate files. CEO.md consolidates all three. Design async human-in-the-loop interfaces as one artifact with clear sections.

---
*Add entries after completing work or learning something material. Keep them atomic and actionable.*
