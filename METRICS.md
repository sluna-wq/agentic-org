# Metrics

> **How the org judges itself — what good looks like, measured.**
> If we can't measure it, we don't claim it. Metrics evolve as the org matures.

## Metric Categories

### Delivery
| Metric | Definition | Target | Current | Trend |
|--------|-----------|--------|---------|-------|
| Backlog throughput | Items completed per week | TBD | N/A | — |
| Cycle time | Median days from start to done | TBD | N/A | — |
| Commitment reliability | % of planned items completed vs committed | >80% | N/A | — |

### Quality
| Metric | Definition | Target | Current | Trend |
|--------|-----------|--------|---------|-------|
| Rework rate | % of completed items requiring rework | <15% | N/A | — |
| Incident count | Production incidents per week | 0 | N/A | — |
| Test coverage | % of code covered by automated tests | TBD | N/A | — |

### Knowledge
| Metric | Definition | Target | Current | Trend |
|--------|-----------|--------|---------|-------|
| Learnings per cycle | New LEARNINGS.md entries per week | >=2 | N/A | — |
| Stale docs | Docs not updated in >2 weeks while work happened | 0 | N/A | — |
| Decision coverage | % of material choices logged in DECISIONS.md | 100% | N/A | — |

### Liveness (Is the org alive?)
| Metric | Definition | Target | Current | Trend |
|--------|-----------|--------|---------|-------|
| Cycles per day | Successful daemon cycles in 24h | 6 | 0 | — |
| Hours since last cycle | Time since last successful cycle completed | <5h | N/A | — |
| Consecutive failures | Back-to-back cycles that errored | 0 | 0 | — |
| Cycle cost (USD) | API spend per cycle | <$2.00 | N/A | — |
| Cycle duration (min) | Wall-clock time per cycle | <30 | N/A | — |

*Source: `daemon/health.json` (updated by harness after every cycle). `daemon/reports/cycle-N.json` for per-cycle detail.*

### Team
| Metric | Definition | Target | Current | Trend |
|--------|-----------|--------|---------|-------|
| Capability coverage | % of needed capabilities covered by roster | 100% | ~12% | — |
| Agent utilization | % of agent capacity on priority work vs overhead | >70% | N/A | — |

## Measurement Cadence
- **Per-cycle**: Liveness metrics updated automatically by daemon harness
- **Weekly**: All metrics reviewed during PB-003 (Weekly Planning)
- **Per-item**: Delivery and quality metrics updated per completed backlog item
- **Per-incident**: Incident metrics updated in real-time

## When to Add a Metric
Add a new metric when:
1. A goal exists but we can't tell if we're achieving it
2. A failure occurred and we want early warning next time
3. CEO sets a new priority that needs tracking

## When to Remove a Metric
Remove (or archive) a metric when:
1. It's consistently at target and no longer informative
2. It's not driving decisions (vanity metric)
3. The underlying goal changed

---
*Update protocol: Update "Current" and "Trend" columns weekly during PB-003. Add/remove metrics via DECISIONS.md. Targets are set collaboratively between CEO and CTO-Agent.*
