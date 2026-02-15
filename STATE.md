# Org State

> **This is the single source of truth for "where are we right now."**
> Any agent starting a session reads this first. Any agent completing work updates this.
> Last updated: 2026-02-15 (Cycle #2, BL-014 complete)

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
| BL-015 | dbt project parser (manifest.json, catalog, YAML) | CTO-Agent | Queued | — | Ready to start (BL-014 done) |
| BL-016 | Test Generator agent v0 | CTO-Agent | Queued | — | Blocked on BL-015 |
| BL-017 | Pilot plan & design partner strategy | CTO-Agent | Queued | — | Can start anytime |
| BL-018 | Defensibility analysis (vs dbt Labs) | CTO-Agent | Queued | — | Can start anytime |

## Blockers
- **Cloud daemon**: Anthropic API credits at $0 + ORG_PAT needs repo write scope. Daemon paused until both fixed.

## Where CEO Can Help
- **Credits**: Top up Anthropic API balance → unblocks autonomous daemon cycles
- **ORG_PAT**: Regenerate with `repo` scope → unblocks daemon push
- **Design partners**: If you know dbt Core teams who'd try an early prototype, flag them

## Recent Decisions
- **DEC-009**: CEO-CTO contract evolution — retired DIR-001/002, issued DIR-003 (ownership), greenlit dbt Guardian, expanded CTO autonomy, improved visibility (2026-02-14)
- DEC-008: Cloud daemon via GitHub Actions + SDK harness (2026-02-12)
- DEC-007: Conversation mode, separate repos, operational evolution (2026-02-12)
- DEC-006: CEO product direction — autonomous agents for data stack (2026-02-11)

## Active Directives
- **DIR-003** (ACTIVE): CTO operates with ownership and bias for action. Own outcomes, strong POV, disagree when warranted.
- ~~DIR-001~~ (RETIRED): Org infra before product — done.
- ~~DIR-002~~ (RETIRED): AI expertise before product — done.

## Health
| Dimension | Status | Notes |
|-----------|--------|-------|
| Liveness | PAUSED | Cloud daemon needs credits + PAT |
| Delivery | IN_PROGRESS | dbt-guardian repo live, parser next |
| Quality | N/A | No product code yet |
| Team | Minimal | CTO-Agent only |
| Knowledge | Strong | Research complete, product direction clear |

---
*Update protocol: Update the "Last updated" timestamp on every change. Keep "Where CEO Can Help" current — this is how the CEO knows where to unblock. Keep this under 100 lines.*
