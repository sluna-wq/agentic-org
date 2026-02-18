# Backlog

> Prioritized work queue. Active work moves to STATE.md. Done items are logged in DECISIONS.md or LEARNINGS.md — not here.

## Active
| ID | Work | Owner |
|----|------|-------|
| BL-022 | DE Walkthroughs WT-05 through WT-10 | CEO + CTO |
| BL-023 | SDKification research: map APIs/SDKs across full data stack | Daemon |
| BL-024 | Product thesis v1: synthesize WT-01-04 + form factor into "what are we building" | Daemon |
| BL-025 | Scaffold WT-05, WT-06, WT-07 scenarios (parallel, one per sub-agent) | Daemon |
| BL-026 | Agent toolset spec: define exact tool signatures for agent DE (feeds from BL-023) | Daemon |

### BL-023 detail — SDKification research
Map programmatic access across the data stack. For each layer, answer: what's accessible, what depth, what gaps, where computer use would still be needed.
- **Warehouses**: Snowflake (Python connector, Snowpark, information_schema), BigQuery (client lib, INFORMATION_SCHEMA), DuckDB (native Python, in-process), Redshift
- **dbt**: artifacts (manifest.json, catalog.json, run_results.json — machine-readable DAG + results), dbt Core CLI (subprocess), dbt Cloud REST API (job triggers, run logs), dbt Semantic Layer (GraphQL)
- **Orchestration**: Airflow REST API v2, Dagster (Python-native, GraphQL), Prefect (Python-native REST)
- **BI tools**: Looker SDK + REST API (system__activity for usage data, LookML), Tableau Server REST API, Metabase REST API, Mode REST API
- **Deliverable**: `research/sdkification.md` — coverage map, depth ratings, gaps, recommended agent tool primitives

### BL-024 detail — Product thesis v1
One document answering: what are we building, for whom, how does it work, what's the form factor?
- **Form factor**: Session interface (Claude Code analogue) — agent drives, human watches + redirects. Plus always-on autonomous monitoring layer.
- **Core capabilities**: continuous reconciliation (LRN-030), schema drift detection (LRN-036), investigation + draft-fix (LRN-032), source onboarding scaffold (LRN-033)
- **What stays human**: business context, org standing, final go/no-go
- **Tool access**: SDKified (BL-023 feeds this)
- **Deliverable**: `research/product-thesis-v1.md`

### BL-025 detail — Scaffold WT-05, WT-06, WT-07
Build three scenario environments like WT-04: seeds with realistic broken/starting state, analysis SQL files, agent lens section, postmortem template. Use sub-agents in parallel.
- WT-05: "Why Is This Query So Slow?" — performance investigation, query profiling, materialization decisions
- WT-06: "The Data Is Stale" — freshness monitoring, schedule debugging, orchestration failure modes
- WT-07: "PII Everywhere" — compliance discovery, column classification, masking strategy

### BL-026 detail — Agent toolset spec
Based on BL-023 research. Define exact tool signatures an agent DE would need — not theoretical, scoped to what the SDKs actually support.
- `db_query(sql, warehouse)` → results
- `read_manifest(project_path)` → DAG graph
- `schema_diff(source_name, registered_columns)` → drift report
- `dbt_run(models, project_path)` → run results
- `read_run_results(project_path)` → parsed failures
- `dbt_ls(select, project_path)` → model list (blast radius)
- **Deliverable**: `research/agent-toolset-spec.md`

## When Needed
| ID | Work | Why Waiting |
|----|------|-------------|
| BL-013 | Fix cloud daemon (credits + PAT) | Low urgency while doing walkthroughs |

## Icebox
- BL-020: dbt Guardian pilot — on hold, may revive in different form post-WT-10
