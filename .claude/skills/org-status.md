---
name: status
description: Org dashboard — see who's working on what, phase, health, and blockers.
---

# /status — Org Dashboard

Read the following files and render a clean dashboard view:

1. Read `STATE.md` — phase, active work table, blockers, health
2. Read `CEO.md` — pending queue items
3. Read `BACKLOG.md` — what's queued (active items only)

## Output format:
```
ORG STATUS — [timestamp]
Phase: [phase]

ACTIVE WORK
[Render the active work table from STATE.md]

BACKLOG (next up)
[Top 3-5 active items]

CEO QUEUE
[Items from CEO.md Your Queue, or "Empty"]

HEALTH
[Render health table from STATE.md]

BLOCKERS
[Any blockers, or "None"]
```

Keep it scannable. This is a dashboard, not a report.
