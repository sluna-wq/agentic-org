# Org State

> **This is the single source of truth for "where are we right now."**
> Any agent starting a session reads this first. Any agent completing work updates this.
> Last updated: 2026-02-16 (Cycle #11, Test Generator relationship inference added)

## Phase
`BUILDING` — Product direction confirmed. dbt Guardian greenlit. Transitioning from planning to product work.

Phases: `BOOTSTRAP` → `PLANNING` → **`BUILDING`** → `SHIPPING` → `OPERATING`

## Product: dbt Guardian
**Autonomous reliability agents for dbt projects.** Starting with dbt Core users (not dbt Cloud). First agent: Test Generator — analyzes dbt project coverage gaps, generates schema.yml tests, opens PRs.

- **Target customer**: Mid-market data teams (5-20 engineers) running dbt Core + Snowflake/Postgres
- **Strategic framing**: Work with the data stack, then hollow it out. Start alongside tools, make them interchangeable over time.
- **Moat**: Cross-stack remediation. dbt is entry point, not ceiling.
- **Key decision**: DEC-009

## Active Work
| ID | Description | Owner | Status | Last Activity | What's Next |
|----|-------------|-------|--------|---------------|-------------|
| — | No active work | — | — | Cycle #11: Relationship inference | Awaiting CEO pilot plan approval to start BL-020 |

## Blockers
- **Cloud daemon**: Anthropic API credits at $0 + ORG_PAT needs repo write scope. Daemon paused until both fixed.
- **Multi-repo workflow**: Can't create separate GitHub repos from daemon. Product code temporarily in `products/` directory of org repo.

## Where CEO Can Help
- **Credits**: Top up Anthropic API balance → unblocks autonomous daemon cycles
- **ORG_PAT**: Regenerate with `repo` scope → unblocks daemon push
- **GitHub repo creation**: Daemon needs ability to create repos via GitHub API → enables proper multi-repo architecture
- **Design partners**: If you know dbt Core teams who'd try an early prototype, flag them

## Recent Decisions
- **DEC-011**: Org talent plan — Stay lean (CTO-Agent solo) through pilot (Month 0-3). First specialist hire: Data Engineer Agent at Month 6-9 when cross-stack work begins. SaaS team (Frontend/DevOps/Security) at Month 9-12 if needed. 7 specialist roles defined with hiring triggers. Reassess after pilot synthesis. (2026-02-16)
- DEC-010: dbt Guardian defensibility — Strategic constraints on dbt Labs (dev>ops, partnership lock-in, Core community tension) create permanent opening for operational agents. Path: win Core users (6mo) → autonomous capabilities (6-12mo) → cross-stack (12-18mo). Window open NOW. (2026-02-15)
- DEC-009: CEO-CTO contract evolution — retired DIR-001/002, issued DIR-003 (ownership), greenlit dbt Guardian, expanded CTO autonomy, improved visibility (2026-02-14)
- DEC-008: Cloud daemon via GitHub Actions + SDK harness (2026-02-12)

## Active Directives
- **DIR-003** (ACTIVE): CTO operates with ownership and bias for action. Own outcomes, strong POV, disagree when warranted.
- ~~DIR-001~~ (RETIRED): Org infra before product — done.
- ~~DIR-002~~ (RETIRED): AI expertise before product — done.

## Health
| Dimension | Status | Notes |
|-----------|--------|-------|
| Liveness | PAUSED | Cloud daemon needs credits + PAT |
| Delivery | ON_TRACK | Test Generator v0 complete! End-to-end validated, ready for pilot |
| Quality | EXCELLENT | 35+ unit tests, CI/CD enforced, end-to-end tested on sample project |
| Team | Minimal | CTO-Agent only |
| Knowledge | Strong | Research complete, product direction clear |

---
*Update protocol: Update the "Last updated" timestamp on every change. Keep "Where CEO Can Help" current — this is how the CEO knows where to unblock. Keep this under 100 lines.*
