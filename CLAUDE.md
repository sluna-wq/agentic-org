# CLAUDE.md — Agent Bootstrap

> **Read this first. This is how you orient to the org.**

## What This Org Is
A CEO-led, CTO-agent-directed agentic tech/product organization. The repository IS the org — all strategy, execution, decisions, and learnings live as artifacts here.

## How to Start a Session
Follow **PB-001** in PLAYBOOKS.md:
1. Read `STATE.md` — know where things stand RIGHT NOW
2. Read `DIRECTIVES.md` — know active CEO constraints and priorities
3. Read `BACKLOG.md` — know what's prioritized
4. Read `ROSTER.md` — know who's here and what gaps exist
5. Check `LEARNINGS.md` — don't repeat past mistakes
6. If continuing work, read relevant entries in `DECISIONS.md`
7. If doing product work, read `WORKBENCH.md` and `product/CLAUDE.md`

## The Knowledge Architecture
```
CHARTER.md     ← What the org IS (constitution, principles, authority)
STATE.md       ← Where the org IS RIGHT NOW (live dashboard — read first, update always)
DIRECTIVES.md  ← What the CEO wants (standing orders, persistent across sessions)
BRIEFING.md    ← What happened lately (CEO's newspaper — narrative view)
ROSTER.md      ← Who is in the org (agents, capabilities, gaps)
DECISIONS.md   ← Why we chose what we chose (reasoning log)
BACKLOG.md     ← What to do next (prioritized work queue)
PLAYBOOKS.md   ← How we operate (repeatable patterns)
LEARNINGS.md   ← What we know from experience (institutional memory)
METRICS.md     ← How we judge ourselves (targets and actuals)
WORKBENCH.md   ← How we execute on the product (code → test → ship protocol)
```

## The Two Interfaces
```
CEO ←→ Org:      DIRECTIVES.md (CEO → Org), BRIEFING.md + STATE.md (Org → CEO)
Org ←→ Product:  WORKBENCH.md (execution protocol), product/CLAUDE.md (conventions)
```

## The Closed Loop
```
Execution → Artifacts → State Update → Learnings → Planning → Execution
    ↑                                                              |
    └──────────────────────────────────────────────────────────────┘
```
Every piece of work must:
1. Start by reading STATE.md (orientation)
2. Produce or modify artifacts (execution)
3. Update STATE.md (state legibility)
4. Add to LEARNINGS.md if anything was learned (knowledge capture)
5. Feed into next planning cycle (continuous improvement)

**If the loop breaks — if artifacts go stale, if learnings aren't captured, if state isn't updated — the org loses self-understanding. Maintaining the loop is everyone's job.**

## Authority Rules
- **CEO** (human) owns direction, priorities, and final go/no-go
- **CTO-Agent** owns tech/product execution within Charter constraints
- **Specialist Agents** execute scoped work under CTO-Agent direction
- Risk thresholds requiring CEO approval are listed in CHARTER.md

## Core Commitments
1. Never ship without integrity checks and rollback path
2. Log every material decision with reasoning
3. Update STATE.md after every meaningful action
4. Contribute to LEARNINGS.md — the org must get smarter
5. Escalate when in doubt — see PB-004

---
*Update protocol: This file must be updated whenever CHARTER.md changes (per PB-008) or when the knowledge architecture changes (per PB-007). Reviewed during PB-010 (Quarterly Self-Audit). If you change this file, all active agents must re-read it.*
