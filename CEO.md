# CEO.md

> **Your single async interface to the org.**
> What needs you → what's happening → what's been done.
> _Last updated: 2026-02-17 (CEO session — deep simplification, DEC-013)_

---

## Your Queue — Needs You

_Nothing. When this is empty, the org is running without you._

---

## Where Things Stand

**Phase**: `DISCOVERY` — learning what agent DEs actually need through hands-on walkthroughs

| # | Walkthrough | Status |
|---|------------|--------|
| 1 | The Data You Inherit | Done |
| 2 | The Dashboard Is Wrong | Done |
| 3 | New Data Source Onboarding | Done |
| 4 | The Schema Migration | **Next** |
| 5–10 | ... | Pending |

**Pattern emerging**: Agent DEs should automate the mechanical 80% and escalate the 20% requiring business judgment. Not a narrow tool, not fully autonomous — something in between that knows when to ask.

**Blockers**: None. Walkthroughs need CEO time.

---

## Last 10 Cycles

| Cycle | Type | What Happened |
|-------|------|--------------|
| 12 | Autonomous | Monitoring only — walkthroughs need CEO |
| 13 | Autonomous | Wrote `narrow-vs-general-agents.md` to preserve DEC-012 insight |
| 14 | Autonomous | Monitoring + CI cleanup (node_modules) |
| 15 | Autonomous | Monitoring only |
| 16 | Autonomous | Process audit — identified bloat, recommendations written |
| WT-01 | CEO session | "The Data You Inherit" — dbt Guardian caught nothing; general agent found everything → DEC-012 pivot |
| WT-02 | CEO session | "The Dashboard Is Wrong" — 3 bugs found (NULL semantics, duplicates, multi-currency) |
| WT-03 | CEO session | "New Data Source Onboarding" — HubSpot pipeline, entity resolution boundary |
| — | CEO session | Org simplification — CEO.md, pruned to 5 playbooks, deleted 6 dead files, compressed DECISIONS + LEARNINGS |

---

## How to React

Open Claude Code in `agentic-org/` and talk to the CTO. That's it.
