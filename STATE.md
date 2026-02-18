# Org State

> **This is the single source of truth for "where are we right now."**
> Any agent starting a session reads this first. Any agent completing work updates this.
> Last updated: 2026-02-18 (Autonomous cycle #18 — WT-05 scenario scaffolded)

## Phase
`DISCOVERY` — Pivoted from product shipping to walkthrough-driven discovery. Learning what an agent DE actually needs through hands-on experience.

Phases: `BOOTSTRAP` → `PLANNING` → `BUILDING` → **`DISCOVERY`** → `BUILDING v2` → `SHIPPING` → `OPERATING`

## Direction: Agent Data Engineer (via Walkthroughs)
**Discovering what it takes to deploy agents as data engineers.** Through 10 realistic DE walkthroughs, CEO and CTO are building shared understanding of: what DEs actually do, what agents can already handle, and what's stopping orgs from deploying agent DEs.

- **Key insight (WT-01)**: dbt Guardian (narrow product) caught almost nothing. A general agent conducting a full DE investigation found everything. Agents are capable enough — the question is deployment, not capability.
- **Key insight (WT-02)**: The highest-value agent capability is continuous reconciliation (pipeline vs external source of truth), not pipeline building. Investigation methodology is fully automatable — it's a decision tree, not intuition. Tests should check intent, not arbitrary thresholds.
- **Key insight (WT-03)**: Source onboarding is 80% template (staging models, mart SQL) and 20% judgment (entity resolution thresholds, attribution choices). Ideal agent shape: automate the 80%, surface 3-4 decisions for human, execute the rest. Entity resolution is a well-defined escalation boundary.
- **Key insight (WT-04)**: Detection latency is the real cost — 47 min of dark dashboards wasn't a fix problem, it was a detection problem. Schema drift polling solves this. **Form factor breakthrough**: human is the copilot (agent drives, human watches + redirects). Accountability via co-presence + override, not approval gates. SDKification (not computer use) is the right agent architecture.
- **Strategic question**: What stops organizations from deploying agents as data engineers to fix and operate everything?
- **Previous product (dbt Guardian)**: Test Generator v0 complete but solving the wrong problem. Parser/analyzer components may become building blocks for the real product.
- **Key decision**: DEC-012

## Active Work
| ID | Description | Owner | Status | Last Activity | What's Next |
|----|-------------|-------|--------|---------------|-------------|
| BL-022 | DE Walkthroughs | CEO + CTO | In progress | WT-04 complete (agent lens) | WT-05 scenario ready — CEO can start immediately |
| BL-023 | SDKification research | Daemon | Pending | Kicked off cycle #17 | Research artifact in research/ |
| BL-024 | Product thesis v1 | Daemon | Pending | Kicked off cycle #17 | Synthesis doc in research/ |
| BL-025 | Scaffold WT-06, WT-07 | Daemon | In progress | WT-05 done (cycle #18) | Two more scenario environments |
| BL-026 | Agent toolset spec | Daemon | Pending | Blocked on BL-023 | Tool signatures doc in research/ |

## Walkthrough Progress
| # | Walkthrough | Status |
|---|------------|--------|
| 1 | The Data You Inherit | Done |
| 2 | The Dashboard Is Wrong | Done |
| 3 | New Data Source Onboarding | Done |
| 4 | The Schema Migration | Done (agent lens) |
| 5 | Why Is This Query So Slow? | **Ready** (scaffolded cycle #18) |
| 6 | The Data Is Stale | Pending |
| 7 | PII Everywhere | Pending |
| 8 | The Duplicate Problem | Pending |
| 9 | Building the Metrics Layer | Pending |
| 10 | The Autonomous Agent | Pending |

## Blockers
- None. Daemon running (18 cycles, all green). Walkthroughs need CEO participation.

## Where CEO Can Help
- **WT-05 is ready**: Fan-out bug scenario with seed data, investigation queries, reference solution. Pull up `walkthroughs/wt05_slow_query/README.md` to start.

## Recent Decisions
- **DEC-014**: Pull SDKification research forward — form factor insight (human as copilot) requires SDK/API-first architecture. Don't wait for WT-10. (2026-02-17)
- **DEC-013**: Org simplification — collapsed async CEO interface to CEO.md, pruned PLAYBOOKS.md to 5 active playbooks, retired BRIEFING.md/METRICS.md/ROSTER.md from active use. (2026-02-17)
- **DEC-012**: Pivot from dbt Guardian product to walkthrough-driven agent DE discovery. (2026-02-16)
- DEC-011: Stay lean through pilot (now walkthroughs). CTO-Agent solo. (2026-02-16)
- DEC-009: CEO-CTO contract evolution — ownership, greenlit product. (2026-02-14)

## Active Directives
- **DIR-003** (ACTIVE): CTO operates with ownership and bias for action. Own outcomes, strong POV, disagree when warranted.
- **DIR-004** (ACTIVE): XP culture — simplest thing that works. YAGNI, spike over spec, kill what's not earning its keep.

## Health
| Dimension | Status | Notes |
|-----------|--------|-------|
| Liveness | RUNNING | Daemon healthy — 18 cycles, 0 failures |
| Discovery | ON_TRACK | WT-04 complete, WT-05 ready |
| Quality | STRONG | Process gap identified + fixed (PB-020) |
| Team | Minimal | CTO-Agent only |
| Knowledge | Growing | Walkthroughs producing actionable insights |
| Process | SIMPLIFIED | DIR-004 applied — bloat removed, CEO.md as single async interface |

---
*Update protocol: Update the "Last updated" timestamp on every change. Keep "Where CEO Can Help" current — this is how the CEO knows where to unblock. Keep this under 100 lines.*
