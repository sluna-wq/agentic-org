# CEO.md

> **Your single async interface to the org.**
> What needs you → what's happening → what's been done.
> _Last updated: 2026-02-18 (Autonomous cycle #18 — WT-05 scaffolded and ready)_

---

## Your Queue — Needs You

**WT-05 is ready.** Open `walkthroughs/wt05_slow_query/README.md` and run it. No setup required — seed data loaded, investigation queries written, reference solution included. The scenario: revenue dashboard showing 3x actual revenue, trace the fan-out bug through the DAG, fix it, verify it.

_Research tracks (BL-023/024/026) still pending — daemon continues next cycle._

---

## Where Things Stand

**Phase**: `DISCOVERY` — learning what agent DEs actually need. Form factor is crystallizing.

| # | Walkthrough | Status |
|---|------------|--------|
| 1 | The Data You Inherit | Done |
| 2 | The Dashboard Is Wrong | Done |
| 3 | New Data Source Onboarding | Done |
| 4 | The Schema Migration | Done (agent lens) |
| 5 | Why Is This Query So Slow? | **Ready** |
| 6–10 | ... | Pending |

**Form factor breakthrough**: Human is the copilot. Agent drives (queries, investigates, drafts), human watches in real time and redirects — like Claude Code. SDKification (direct API access to data stack) is the right architecture, not computer use.

---

## Last 10 Cycles

| Cycle | Type | What Happened |
|-------|------|--------------|
| 14 | Autonomous | Monitoring + CI cleanup (node_modules) |
| 15 | Autonomous | Monitoring only |
| 16 | Autonomous | Process audit — identified bloat, recommendations written |
| 17 | Autonomous | WT-04 scenario scaffolded |
| **18** | **Autonomous** | **WT-05 scenario scaffolded — fan-out bug, grain discipline, materialization** |
| WT-01 | CEO session | "The Data You Inherit" — dbt Guardian caught nothing; general agent found everything → DEC-012 pivot |
| WT-02 | CEO session | "The Dashboard Is Wrong" — 3 bugs found (NULL semantics, duplicates, multi-currency) |
| WT-03 | CEO session | "New Data Source Onboarding" — HubSpot pipeline, entity resolution boundary |
| — | CEO session | Org simplification — CEO.md, pruned to 5 playbooks, deleted 6 dead files |
| WT-04 | CEO session | "The Schema Migration" — agent lens only. Detection latency insight. Form factor breakthrough: human as copilot. SDKification direction set. Daemon tasked at full speed (BL-023–026). |

---

## How to React

Open Claude Code in `agentic-org/` and talk to the CTO. That's it.
