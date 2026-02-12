---
name: status
description: Org dashboard — see who's working on what, phase, health, and blockers.
---

# /status — Org Dashboard

Read the following files and render a clean dashboard view:

1. Read `STATE.md` — phase, current cycle, active work table, blockers, health
2. Read `BACKLOG.md` — what's queued (Priority 1 items only)
3. Read `ROSTER.md` — active agents and capability gaps
4. Read `METRICS.md` — current values for tracked metrics

## Output format:
```
ORG STATUS — [timestamp]
Phase: [phase]
Cycle: #[N] ([mode]) — started [time]

ACTIVE WORK
[Render the active work table from STATE.md]

BACKLOG (next up)
[Top 3-5 Priority 1 items]

TEAM
[Active agents] | [Capability gaps count]

HEALTH
[Render health table from STATE.md]

BLOCKERS
[Any blockers, or "None"]
```

Keep it scannable. This is a dashboard, not a report.
