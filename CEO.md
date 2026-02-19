# CEO.md

## Your Queue

Four walkthroughs are ready — pick any one to start:

- **WT-05**: `walkthroughs/wt05_slow_query/README.md` — Revenue dashboard 3x inflated. Fan-out bug in staging grain. ~45 min.
- **WT-06**: `walkthroughs/wt06_data_stale/README.md` — 60h of missing data, orchestrator shows all green. Silent selector bug. ~45 min.
- **WT-07**: `walkthroughs/wt07_pii_everywhere/README.md` — Security audit flags PII in BI and vendor exports. Lineage trace + compliance incident. ~45 min.
- **WT-08**: `walkthroughs/wt08_duplicate_records/README.md` — Finance raises ticket: dashboard shows $847K, bank rec shows $603K. ETL retry duplicates evade standard dbt tests. ~45 min. *(new this cycle)*

Each has: full scenario narrative, seed data, dbt models with the bug in place, investigation queries, solution, verification, and postmortem. The agent lens section at the end of each README is where the real product insight lives.

Research tracks **done** — BL-023, BL-024, BL-026 completed this session while daemon was down. See research/ for artifacts. Daemon needs credits to resume WT-09/10 scaffolding (BL-025).

## Status

Phase: DISCOVERY. WT-01 through WT-04 done (with you). WT-05–08 ready. WT-09–10 pending scaffold (blocked on daemon credits). Research foundation complete: sdkification.md, product-thesis-v1.md, agent-toolset-spec.md all done.

**Daemon**: DOWN (credits exhausted, 5 consecutive failures). Top up credits to restore.

## Last 10 Cycles

| Cycle | Date | Work |
|-------|------|------|
| #12 | 2026-02-16 | Monitoring (discovery pivot) |
| #13 | 2026-02-16 | Monitoring (discovery pivot) |
| #14 | 2026-02-16 | Monitoring (discovery pivot) |
| #15 | 2026-02-16 | Monitoring (discovery pivot) |
| #16 | 2026-02-17 | Process bloat audit |
| #17 | 2026-02-17 | Scaffolded WT-04 scenario |
| #18 | 2026-02-17 | Scaffolded WT-05 (slow query fan-out) |
| #19 | 2026-02-18 | Scaffolded WT-06 (data staleness) |
| #20 | 2026-02-18 | Scaffolded WT-07 (PII everywhere) |
| #21 | 2026-02-18 | Scaffolded WT-08 (The Duplicate Problem) |
| CEO | 2026-02-19 | BL-023 (sdkification), BL-024 (product thesis v1), BL-026 (agent toolset spec) — all done |
