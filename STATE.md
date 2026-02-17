# Org State

> **This is the single source of truth for "where are we right now."**
> Any agent starting a session reads this first. Any agent completing work updates this.
> Last updated: 2026-02-17 (Cycle #16 — DIR-004 process audit)

## Phase
`DISCOVERY` — Pivoted from product shipping to walkthrough-driven discovery. Learning what an agent DE actually needs through hands-on experience.

Phases: `BOOTSTRAP` → `PLANNING` → `BUILDING` → **`DISCOVERY`** → `BUILDING v2` → `SHIPPING` → `OPERATING`

## Direction: Agent Data Engineer (via Walkthroughs)
**Discovering what it takes to deploy agents as data engineers.** Through 10 realistic DE walkthroughs, CEO and CTO are building shared understanding of: what DEs actually do, what agents can already handle, and what's stopping orgs from deploying agent DEs.

- **Key insight (WT-01)**: dbt Guardian (narrow product) caught almost nothing. A general agent conducting a full DE investigation found everything. Agents are capable enough — the question is deployment, not capability.
- **Strategic question**: What stops organizations from deploying agents as data engineers to fix and operate everything?
- **Previous product (dbt Guardian)**: Test Generator v0 complete but solving the wrong problem. Parser/analyzer components may become building blocks for the real product.
- **Key decision**: DEC-012

## Active Work
| ID | Description | Owner | Status | Last Activity | What's Next |
|----|-------------|-------|--------|---------------|-------------|
| — | DE Walkthroughs | CEO + CTO | In progress | WT-01 complete | WT-02: "The Dashboard Is Wrong" |

## Walkthrough Progress
| # | Walkthrough | Status |
|---|------------|--------|
| 1 | The Data You Inherit | Done |
| 2 | The Dashboard Is Wrong | Next |
| 3 | New Data Source Onboarding | Pending |
| 4 | The Schema Migration | Pending |
| 5 | Why Is This Query So Slow? | Pending |
| 6 | The Data Is Stale | Pending |
| 7 | PII Everywhere | Pending |
| 8 | The Duplicate Problem | Pending |
| 9 | Building the Metrics Layer | Pending |
| 10 | The Autonomous Agent | Pending |

## Blockers
- None. Daemon running (15 cycles, all green). Walkthroughs need CEO participation.

## Where CEO Can Help
- **Continue walkthroughs**: CEO participation is essential — dual learning (DE experience + agent requirements)

## Recent Decisions
- **DEC-012**: Pivot from dbt Guardian product to walkthrough-driven agent DE discovery. Narrow product caught nothing; general agent investigated everything. 10-walkthrough curriculum to discover what agent DEs actually need. (2026-02-16)
- DEC-011: Stay lean through pilot (now walkthroughs). CTO-Agent solo. (2026-02-16)
- DEC-010: dbt Guardian defensibility analysis — strategic constraints on dbt Labs. (2026-02-15)
- DEC-009: CEO-CTO contract evolution — ownership, greenlit product. (2026-02-14)

## Active Directives
- **DIR-003** (ACTIVE): CTO operates with ownership and bias for action. Own outcomes, strong POV, disagree when warranted.
- **DIR-004** (ACTIVE): XP culture — simplest thing that works. YAGNI, spike over spec, kill what's not earning its keep.

## Health
| Dimension | Status | Notes |
|-----------|--------|-------|
| Liveness | RUNNING | Daemon healthy — 16 cycles, 0 failures |
| Discovery | ON_TRACK | WT-01 complete, curriculum designed |
| Quality | STRONG | Process gap identified + fixed (PB-020) |
| Team | Minimal | CTO-Agent only |
| Knowledge | Growing | Walkthroughs producing actionable insights |
| Process | UNDER_REVIEW | DIR-004 audit identified simplification opportunities |

---
*Update protocol: Update the "Last updated" timestamp on every change. Keep "Where CEO Can Help" current — this is how the CEO knows where to unblock. Keep this under 100 lines.*
