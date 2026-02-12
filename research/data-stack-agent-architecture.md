# Agent Architecture for Data Stack Management
## Research & Design Document

**Status**: Architecture Exploration
**Author**: Research Analyst / CTO Architecture Review
**Date**: 2025-02 (with patterns current through early 2025)

---

## Table of Contents

1. [Agent Architecture Patterns (State of the Art)](#1-agent-architecture-patterns-state-of-the-art)
2. [Proposed Specialist Agents for Data Stack](#2-proposed-specialist-agents-for-data-stack)
3. [Coordination & Safety Model](#3-coordination--safety-model)
4. [Technical Integration Points](#4-technical-integration-points)
5. [Build Considerations](#5-build-considerations)

---

## 1. Agent Architecture Patterns (State of the Art)

### 1.1 The Landscape of Multi-Agent Frameworks

The multi-agent ecosystem has converged around a few dominant patterns. Here is how the major players approach it:

#### Anthropic — Claude Agent SDK / Claude Code Architecture

Anthropic's approach centers on a **single powerful agent with tool use** rather than many small agents. The key ideas:

- **Agentic loop**: A single Claude instance runs in a loop — it receives context, decides on a tool call (or multiple), observes results, and decides next steps. The loop continues until the task is complete.
- **Tool use as the extension mechanism**: Rather than spawning sub-agents, Claude uses tools (bash, file operations, MCP servers, web search, etc.) to interact with the world. Each tool is a typed function with a JSON schema.
- **Sub-agents via the Task tool**: Claude Code supports spawning sub-agents using a `Task` tool. These are scoped Claude instances with their own system prompts that execute independently and return results. This is used for parallelism — not for persistent specialist agents.
- **MCP (Model Context Protocol)**: Anthropic's open protocol for connecting LLMs to external tools and data sources. An MCP server exposes tools (functions) and resources (data) over a standard transport (stdio or HTTP/SSE). This is the primary integration pattern — you don't build custom API clients, you build MCP servers.
- **Extended thinking**: For complex reasoning (e.g., analyzing a schema change's blast radius), Claude can use extended thinking to reason through multi-step problems before acting.
- **System prompts as identity**: Agent behavior is shaped by system prompts (like CLAUDE.md files). A "Schema Guardian" agent would be a Claude instance with a system prompt that gives it its role, tools, and constraints.

**Relevance to us**: The Claude model is the strongest at agentic coding tasks. Our agents will likely be Claude instances with role-specific system prompts and tool sets, not a custom agent framework.

#### OpenAI — Agents SDK (formerly Swarm)

OpenAI's Agents SDK (open-sourced March 2025) introduces:

- **Agents as the primitive**: An Agent is defined by a name, instructions (system prompt), tools, and optionally a model. Agents are lightweight — they're configuration, not processes.
- **Handoffs**: The key multi-agent concept. An agent can "hand off" to another agent, transferring the conversation context. This is modeled as a tool call — `transfer_to_triage_agent()`. The new agent takes over the thread.
- **Guardrails**: Input and output validators that run in parallel with the agent. They can reject inputs or flag outputs. Modeled as separate lightweight LLM calls.
- **Tracing**: Built-in tracing for debugging agent behavior. Every tool call, LLM call, and handoff is logged.
- **Runner**: The orchestration loop. `Runner.run()` drives the agent through its loop until it produces a final output or hands off.

**Relevance to us**: The handoff pattern is useful for escalation flows. A Pipeline Doctor could hand off to a human or to a Schema Guardian when it detects the root cause is a schema change. The guardrails pattern is important for our safety model.

#### LangGraph (LangChain)

LangGraph models agent workflows as **state machines** (directed graphs):

- **Nodes**: Each node is a function (could be an LLM call, a tool invocation, or pure logic). Nodes can be individual agents.
- **Edges**: Connections between nodes, which can be conditional. "If the pipeline is failing due to a schema change, route to Schema Guardian; if it's an infra issue, route to Pipeline Doctor."
- **State**: A typed state object that flows through the graph. Each node can read and modify state. This is how agents share context.
- **Persistence**: LangGraph supports checkpointing state, so long-running workflows can be paused and resumed.
- **Human-in-the-loop**: Built-in support for "interrupt" nodes that pause execution and wait for human input.

**Relevance to us**: The graph-based workflow model is well-suited for complex diagnostic flows. A pipeline failure investigation might follow a diagnostic tree — check scheduler, check source, check transformations, check schema — with branches and convergences. However, LangGraph adds significant complexity and coupling to the LangChain ecosystem.

#### CrewAI

CrewAI takes an **organizational metaphor**:

- **Agents**: Have a role, goal, backstory (system prompt), and tools. "You are a Senior Data Quality Analyst..."
- **Tasks**: Discrete units of work assigned to agents. Tasks have descriptions, expected outputs, and assigned agents.
- **Crew**: A collection of agents and tasks with a process (sequential, hierarchical, or consensual).
- **Hierarchical process**: A manager agent delegates to worker agents — closest to our orchestrator pattern.
- **Memory**: Shared memory (across agents), short-term (within a task), and long-term (across crew executions).

**Relevance to us**: The organizational metaphor is intuitive but the framework is opinionated and may limit us. The memory model is interesting — our agents need shared context (e.g., "Pipeline X failed 3 times this week") and long-term learning.

#### Google — A2A (Agent-to-Agent Protocol)

Google's A2A protocol (announced April 2025) standardizes inter-agent communication:

- **Agent Cards**: JSON metadata describing an agent's capabilities, endpoint, and authentication. Agents discover each other via agent cards.
- **Tasks**: The unit of work. A client agent sends a task to a server agent. Tasks have states (submitted, working, completed, failed).
- **Streaming**: Agents can stream partial results via Server-Sent Events.
- **Push notifications**: Agents can notify clients of task completion asynchronously.
- **Multi-modal artifacts**: Task results can include text, files, structured data, or other media.
- **Enterprise-ready**: Supports OAuth2, API keys, and other auth mechanisms.

**Relevance to us**: A2A could be the protocol between our agents if we need true inter-agent communication. However, for an MVP, shared state (a database or file system) is simpler than a message-passing protocol.

### 1.2 Convergent Patterns

Across all frameworks, the following patterns emerge:

| Pattern | Description | Used By |
|---------|-------------|---------|
| **Single-agent + tools** | One powerful agent with many tools. Simple, debuggable. | Anthropic (primary) |
| **Handoff / routing** | A triage agent routes to specialists based on the task. | OpenAI, CrewAI |
| **Graph-based workflow** | Agents are nodes in a DAG; state flows through edges. | LangGraph |
| **Shared state** | Agents coordinate via a shared state object or database. | LangGraph, CrewAI |
| **Message passing** | Agents send structured messages to each other. | A2A, custom |
| **Hierarchical orchestration** | A manager agent delegates and aggregates. | CrewAI, custom |
| **Human-in-the-loop interrupt** | Workflow pauses at designated points for human review. | All |

### 1.3 Tool-Use Patterns for Data Infrastructure

For data stack management specifically, agents need these tool categories:

```
┌─────────────────────────────────────────────────────────────┐
│                    TOOL CATEGORIES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SQL Execution                                              │
│  ├── Read-only queries (INFORMATION_SCHEMA, data profiling) │
│  ├── DDL (ALTER TABLE, CREATE VIEW) — requires approval     │
│  └── DML (INSERT, UPDATE, DELETE) — restricted              │
│                                                             │
│  dbt Interaction                                            │
│  ├── dbt parse / compile (read-only, safe)                  │
│  ├── dbt test (read-only, safe)                             │
│  ├── dbt run (mutating — approval required)                 │
│  ├── dbt source freshness                                   │
│  ├── Model/test file editing via git                        │
│  └── Manifest/catalog introspection                         │
│                                                             │
│  Git Operations                                             │
│  ├── Clone, pull, branch, diff (read-only, safe)            │
│  ├── Commit, push (controlled)                              │
│  ├── PR creation (controlled, human review)                 │
│  └── PR merge (requires human approval)                     │
│                                                             │
│  Orchestrator APIs                                          │
│  ├── Airflow: trigger DAG, get task status, read logs       │
│  ├── Dagster: launch run, get run status, read logs         │
│  ├── Prefect: create flow run, read logs                    │
│  └── dbt Cloud: trigger job, get run status, read artifacts │
│                                                             │
│  Warehouse Admin                                            │
│  ├── Query history / ACCOUNT_USAGE (Snowflake)              │
│  ├── Cost/usage dashboards                                  │
│  ├── Warehouse scaling                                      │
│  └── User/role management (restricted)                      │
│                                                             │
│  Notification / Communication                               │
│  ├── Slack messages                                         │
│  ├── Email                                                  │
│  ├── PagerDuty / OpsGenie                                   │
│  └── Ticket creation (Jira, Linear, GitHub Issues)          │
│                                                             │
│  Observability                                              │
│  ├── Datadog, Monte Carlo, or custom monitoring             │
│  ├── Log aggregation (CloudWatch, Datadog Logs)             │
│  └── Custom metadata store (our own)                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.4 Recommended Architecture: Orchestrator + Specialists

Based on the landscape, the recommended pattern is:

```
                    ┌──────────────┐
                    │   Triggers   │
                    │ (cron, event,│
                    │  webhook)    │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Orchestrator │
                    │   Agent      │
                    │ (Router +    │
                    │  Coordinator)│
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼────┐ ┌────▼─────┐ ┌────▼─────┐
        │Specialist│ │Specialist│ │Specialist│
        │ Agent 1  │ │ Agent 2  │ │ Agent N  │
        └─────┬────┘ └────┬─────┘ └────┬─────┘
              │            │            │
        ┌─────▼────────────▼────────────▼─────┐
        │          Shared State Store          │
        │  (task status, agent context,        │
        │   locks, audit log)                  │
        └─────────────────┬────────────────────┘
                          │
        ┌─────────────────▼────────────────────┐
        │     Tool Layer (MCP Servers)         │
        │  ┌─────┐ ┌─────┐ ┌──────┐ ┌──────┐  │
        │  │ SQL │ │ dbt │ │ Git  │ │Slack │  │
        │  └─────┘ └─────┘ └──────┘ └──────┘  │
        └──────────────────────────────────────┘
```

**Why this over pure message-passing**: Data stack management tasks are typically **triggered externally** (a pipeline fails, a schema changes, a scheduled audit runs) and **require coordination but not conversation** between agents. Agents don't need to chat with each other — they need to share state (e.g., "I'm working on model X, don't touch it") and route tasks. A shared state store with an orchestrator is simpler, more debuggable, and more reliable than a peer-to-peer message passing system.

**Why Orchestrator + Specialists over Single Agent**: A single agent with all tools would work for small deployments but breaks down because:
1. Context window limits — a single agent can't hold all the context for all domains
2. Prompt specialization — a Schema Guardian needs different instructions than a Cost Optimizer
3. Parallelism — multiple issues may need attention simultaneously
4. Blast radius — a bug in cost optimization logic shouldn't affect pipeline monitoring

---

## 2. Proposed Specialist Agents for Data Stack

### 2.0 Agent Template

Every specialist agent is defined by:

```yaml
agent:
  name: string
  role: string                    # one-sentence purpose
  system_prompt: string           # full role definition, constraints, tools
  triggers:
    - type: cron | event | manual
      config: ...
  tools:                          # MCP servers + built-in tools
    - name: string
      access_level: read | write | admin
  autonomous_actions:             # what it can do without human approval
    - ...
  escalation_actions:             # what requires human approval
    - ...
  shared_state_keys:              # what state it reads/writes
    - ...
```

### 2.1 Schema Guardian

| Attribute | Detail |
|-----------|--------|
| **Role** | Monitors source system schema changes, assesses downstream impact, proposes or applies fixes to dbt models and tests. |
| **Triggers** | (1) Scheduled: runs every N hours to diff source schemas. (2) Event: webhook from source system (e.g., Fivetran sync completion). (3) Event: dbt test failure that indicates schema drift. |
| **Tools Needed** | SQL read access to warehouse INFORMATION_SCHEMA; dbt project via git; dbt compile/parse; PR creation via GitHub API; Slack notifications. |
| **Autonomous Actions** | Detect schema changes (new columns, type changes, dropped columns). Assess impact via dbt manifest lineage. Create a PR with proposed fixes for additive changes (new nullable column). Post Slack notification with impact summary. |
| **Escalation Actions** | Breaking changes (dropped column, type change on used column). Changes that affect >N downstream models. Any DDL execution. PR merge. |

**Example Workflows**:

**Scenario 1: New column added to source table**
1. Scheduled scan detects `users` table has a new column `phone_verified_at TIMESTAMP`.
2. Agent queries dbt manifest to find `stg_users` model and all downstream models.
3. Determines: additive change, no downstream breakage.
4. Creates a git branch, adds the column to `stg_users.sql`, adds a `not_null` test if the column appears populated, updates `schema.yml` with a description.
5. Opens PR. Posts Slack message: "New column `phone_verified_at` detected in source `users`. PR #42 adds it to staging. No downstream impact."

**Scenario 2: Column type change (breaking)**
1. Scheduled scan detects `orders.amount` changed from `DECIMAL(10,2)` to `VARCHAR`.
2. Agent traces downstream: 5 models use this column, including `fct_revenue`.
3. Agent determines this is high-risk. Posts Slack alert with full impact tree.
4. Agent proposes a fix PR: adds a `CAST` in staging with a `-- TODO: investigate source type change` comment.
5. Marks task as "awaiting human review" in shared state.

**Scenario 3: Source table dropped**
1. Scheduled scan detects `legacy_events` table no longer exists.
2. Agent traces downstream: `stg_legacy_events` and 2 downstream models.
3. Agent immediately alerts via Slack and PagerDuty (configurable severity).
4. Agent does NOT auto-fix — this requires human investigation. Creates a ticket with full context.

---

### 2.2 Pipeline Doctor

| Attribute | Detail |
|-----------|--------|
| **Role** | Monitors pipeline/orchestrator health, diagnoses failures, applies fixes or escalates. First responder for data pipeline incidents. |
| **Triggers** | (1) Event: pipeline failure webhook from Airflow/Dagster/dbt Cloud. (2) Event: SLA miss detected. (3) Scheduled: periodic health check of all pipelines. |
| **Tools Needed** | Orchestrator API (Airflow, Dagster, Prefect, dbt Cloud); SQL read access for data validation; dbt compile/run/test; git for model inspection; Slack; PagerDuty; log access. |
| **Autonomous Actions** | Read failure logs and error messages. Run diagnostic queries (source freshness, row counts). Retry transient failures (network timeouts, warehouse busy). Clear stuck tasks. Post diagnostic summary to Slack. |
| **Escalation Actions** | Root cause requires code change. Failure affects SLA-critical pipelines. Retry limit exceeded. Cascading failures detected. |

**Example Workflows**:

**Scenario 1: Transient warehouse error**
1. Airflow task `dbt_run_staging` fails with `WAREHOUSE_TIMEOUT`.
2. Agent receives webhook, reads the error log.
3. Classifies as transient (warehouse timeout = retryable).
4. Checks: has this task failed in the last 3 runs? No — first occurrence.
5. Retries the task via Airflow API. Posts Slack message: "Transient timeout on `dbt_run_staging`, retrying."
6. Task succeeds on retry. Agent marks resolved, logs the incident.

**Scenario 2: dbt model compilation error after merge**
1. dbt Cloud job fails with `Compilation Error in model fct_orders`.
2. Agent reads the error: `column "user_id" does not exist`.
3. Agent checks recent git commits — finds PR #38 renamed `user_id` to `customer_id` in `stg_orders` but didn't update downstream.
4. Agent creates a fix PR updating `fct_orders` to use `customer_id`.
5. Posts to Slack: "Pipeline failure caused by column rename in PR #38. Fix PR #43 created. Awaiting review."
6. Hands off to human for PR review and merge.

**Scenario 3: Source freshness degradation**
1. Scheduled health check runs `dbt source freshness`.
2. Detects `source.stripe.payments` is 6 hours stale (threshold: 3 hours).
3. Agent checks Fivetran sync status via API — connector is in `broken` state.
4. Agent posts Slack alert with context: "Stripe payments source is 6h stale. Fivetran connector is broken. Error: API rate limit exceeded."
5. If Fivetran API allows: triggers a re-sync. Otherwise: creates a ticket for the data engineering team.

---

### 2.3 Quality Sentinel

| Attribute | Detail |
|-----------|--------|
| **Role** | Proactively monitors data quality. Runs existing tests, generates new tests from data profiling, catches anomalies using statistical methods. |
| **Triggers** | (1) Scheduled: after each dbt run completes. (2) Event: new model or source added. (3) Scheduled: periodic deep profiling (daily/weekly). |
| **Tools Needed** | SQL read access; dbt test/compile; dbt manifest/catalog; git for test file creation; statistical analysis (can be done in SQL or Python). |
| **Autonomous Actions** | Run dbt tests and report results. Profile data distributions (nulls, cardinality, min/max, percentiles). Detect anomalies (row count drops >X%, null rate spikes, value distribution shifts). Auto-generate basic tests for untested columns (not_null, unique, accepted_values). Create PRs for new tests. |
| **Escalation Actions** | Data quality issue in a business-critical model. Anomaly exceeding severity threshold. Test failure in production. |

**Example Workflows**:

**Scenario 1: Automatic test generation for new model**
1. Agent detects a new model `dim_products` was added in the latest commit.
2. Agent profiles the model: queries row counts, null rates, cardinality for each column.
3. Generates appropriate tests: `unique` and `not_null` on `product_id`, `not_null` on `product_name`, `accepted_values` on `category` (based on current distinct values).
4. Creates a PR with the tests in `schema.yml`. Posts to Slack: "Generated 6 tests for new model `dim_products`. PR #44."

**Scenario 2: Anomaly detection on row counts**
1. After the daily dbt run, agent queries row counts for key fact tables.
2. `fct_orders` has 12,000 rows today vs a 30-day average of 45,000 (73% drop).
3. Agent runs diagnostic queries: checks source freshness (OK), checks for filtering issues (finds a new `WHERE` clause added yesterday in a PR).
4. Posts alert: "fct_orders row count dropped 73%. Root cause: PR #40 added a filter on `status != 'draft'`. Was this intentional?"
5. Links the PR and the data comparison in the alert.

**Scenario 3: Distribution shift detection**
1. Weekly deep profiling runs on `dim_customers`.
2. Agent detects that `country` column now has 40% `NULL` values, up from 2% last week.
3. Agent investigates: traces to source table, finds the NULL spike started on Tuesday.
4. Cross-references with Schema Guardian's change log: no schema changes detected.
5. Escalates to Slack: "Data quality alert: `dim_customers.country` null rate spiked from 2% to 40% starting Tuesday. No schema change detected — possible source data issue."

---

### 2.4 Documentation Agent

| Attribute | Detail |
|-----------|--------|
| **Role** | Keeps data documentation current: column descriptions, model descriptions, lineage documentation, data catalog entries. Fights documentation decay. |
| **Triggers** | (1) Event: PR merged that modifies dbt models. (2) Scheduled: weekly audit of documentation coverage. (3) Manual: user requests documentation for a model. |
| **Tools Needed** | dbt manifest/catalog; git for schema.yml editing; SQL read access for column inspection; existing catalog API (if any — Atlan, DataHub, etc.); LLM for description generation. |
| **Autonomous Actions** | Generate column descriptions from column names, types, and sample values. Update descriptions when columns change. Calculate documentation coverage metrics. Create PRs with documentation additions. Sync dbt docs to external catalog. |
| **Escalation Actions** | Descriptions for business-critical models (should be human-reviewed). Changes to existing human-written descriptions. |

**Example Workflows**:

**Scenario 1: Auto-document a new model**
1. PR #45 merges, adding `fct_subscription_events`.
2. Agent reads the model SQL, understands the transformations.
3. Agent queries sample data to understand column semantics.
4. Generates: model description ("Fact table tracking subscription lifecycle events: creation, upgrade, downgrade, cancellation, and renewal"), column descriptions for all 12 columns.
5. Creates PR with `schema.yml` updates. Flags business-logic columns for human review.

**Scenario 2: Documentation coverage audit**
1. Weekly scan of all models in the dbt project.
2. Finds: 45/120 models have descriptions (37.5%), 234/890 columns have descriptions (26.3%).
3. Prioritizes by downstream usage (models with more dependents first).
4. Generates descriptions for the top 10 most-used undocumented models.
5. Creates a PR and posts a coverage report to Slack.

---

### 2.5 Cost Optimizer

| Attribute | Detail |
|-----------|--------|
| **Role** | Analyzes warehouse spend, identifies wasteful queries and patterns, recommends and implements optimizations. |
| **Triggers** | (1) Scheduled: daily cost analysis. (2) Event: spend threshold exceeded. (3) Manual: optimization review requested. |
| **Tools Needed** | Warehouse admin/usage views (Snowflake ACCOUNT_USAGE, BigQuery INFORMATION_SCHEMA.JOBS, Redshift STL_QUERY); dbt manifest for model analysis; git for model changes; Slack. |
| **Autonomous Actions** | Query cost attribution (by model, user, warehouse). Identify expensive queries and suggest optimizations (clustering keys, materialization changes, query rewrites). Detect unused models/tables. Report cost trends. |
| **Escalation Actions** | Warehouse resizing. Materialization changes on production models. Dropping unused tables. Any DDL changes. |

**Example Workflows**:

**Scenario 1: Expensive query identification**
1. Daily analysis of Snowflake QUERY_HISTORY.
2. Identifies `fct_user_sessions` model costs $45/run and runs 4x/day ($180/day, $5,400/month).
3. Analyzes the model: it's a full table scan on a 2B-row table with no clustering.
4. Recommends: (a) add clustering key on `session_date`, (b) change to incremental materialization.
5. Posts Slack report with cost impact estimate: "Changing `fct_user_sessions` to incremental with date clustering could save ~$4,500/month."

**Scenario 2: Unused model detection**
1. Cross-references dbt manifest with Snowflake QUERY_HISTORY (30-day lookback).
2. Finds 15 models that are built daily but never queried by any user or downstream model.
3. Estimates cost: these 15 models cost $800/month to build.
4. Creates a report with the list and recommends disabling or removing them.
5. For models with no downstream dependencies: proposes a PR to change materialization to `ephemeral` or add a `-- disabled` tag.

**Scenario 3: Warehouse right-sizing**
1. Analyzes warehouse utilization patterns: `ANALYTICS_WH` is XL but averages 15% utilization.
2. Analyzes query queue times: no queuing detected.
3. Recommends downsizing to Medium with auto-suspend after 60 seconds.
4. Estimates savings: $2,000/month.
5. Creates a runbook for the change (not auto-applied — infrastructure change requires human approval).

---

### 2.6 Test Engineer

| Attribute | Detail |
|-----------|--------|
| **Role** | Generates, maintains, and optimizes the dbt test suite. Ensures comprehensive coverage and meaningful assertions. |
| **Triggers** | (1) Event: new model added or modified. (2) Scheduled: weekly coverage analysis. (3) Event: production incident (generates regression tests). |
| **Tools Needed** | dbt manifest/catalog; SQL read access; git; dbt test/compile. |
| **Autonomous Actions** | Generate tests based on data profiling. Identify coverage gaps. Create regression tests from incidents. Optimize slow tests. Detect redundant tests. |
| **Escalation Actions** | Tests on business-critical models. Tests that encode business logic (need human validation of the assertion). |

**Example Workflows**:

**Scenario 1: Coverage gap analysis and remediation**
1. Weekly scan: analyzes all models vs test coverage.
2. Finds `fct_payments` has 0 tests despite being queried 500x/day.
3. Profiles the data, generates: `unique` on `payment_id`, `not_null` on key columns, `relationships` test to `dim_customers`, `accepted_values` on `payment_status`, custom test asserting `amount > 0`.
4. Creates PR with tests and coverage report.

**Scenario 2: Regression test from incident**
1. A production incident occurred: `fct_revenue` was double-counting due to a duplicate join.
2. After the fix is merged, the Test Engineer agent generates a regression test: a custom dbt test that asserts `fct_revenue` row count equals `stg_orders` row count (the invariant that was violated).
3. Creates PR with the test and links it to the incident ticket.

---

### 2.7 Migration Agent

| Attribute | Detail |
|-----------|--------|
| **Role** | Assists with data stack migrations: warehouse migrations, orchestrator migrations, dbt version upgrades. |
| **Triggers** | (1) Manual: migration project initiated. (2) Event: new dbt version released. |
| **Tools Needed** | SQL access to source and target warehouses; git; dbt compile/run/test; orchestrator APIs (source and target); diff tools. |
| **Autonomous Actions** | Generate migration plans. Convert SQL dialects. Run parallel validation queries. Compare outputs between old and new. Track migration progress. |
| **Escalation Actions** | All destructive operations. Cutover decisions. Any data discrepancy found during validation. |

**Example Workflows**:

**Scenario 1: dbt version upgrade (e.g., 1.7 to 1.9)**
1. Agent reads the dbt changelog and identifies breaking changes.
2. Scans the project for affected patterns (deprecated macros, changed configs).
3. Creates a branch, applies fixes, runs `dbt compile` to validate.
4. Runs full test suite on the new version.
5. Creates a PR with all changes and a migration checklist.

**Scenario 2: Warehouse migration (Redshift to Snowflake)**
1. Agent catalogs all tables, views, UDFs in Redshift.
2. Generates Snowflake-compatible DDL for each object.
3. For dbt models: identifies Redshift-specific SQL and proposes Snowflake equivalents.
4. Runs models in Snowflake, compares output row counts and checksums against Redshift.
5. Generates a validation report with any discrepancies flagged.

---

## 3. Coordination & Safety Model

### 3.1 How Agents Coordinate

The coordination model uses **shared state + orchestrator routing**, not peer-to-peer messaging.

```
┌──────────────────────────────────────────────────┐
│              Shared State Store                  │
│                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │  Locks   │ │  Tasks   │ │  Agent Context   │ │
│  │          │ │          │ │                  │ │
│  │model:X → │ │task:123  │ │schema_changes:   │ │
│  │agent:PD  │ │status:wip│ │[{table:users,    │ │
│  │until:T+1h│ │agent:SG  │ │ col:phone,...}]  │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
│                                                  │
│  ┌──────────┐ ┌──────────────────────────────┐   │
│  │  Audit   │ │  Incident History            │   │
│  │   Log    │ │                              │   │
│  │          │ │  [pipeline failures,         │   │
│  │who did   │ │   schema changes,            │   │
│  │what when │ │   anomalies detected, ...]   │   │
│  └──────────┘ └──────────────────────────────┘   │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Implementation**: A PostgreSQL database (or similar) with tables for:

- **`locks`**: Advisory locks on resources (dbt models, git branches, warehouse objects). Prevents two agents from modifying the same model simultaneously.
- **`tasks`**: Work items with status, assigned agent, priority, created/updated timestamps.
- **`agent_context`**: Key-value store for cross-agent information sharing. Schema Guardian writes schema changes here; Pipeline Doctor reads them when diagnosing failures.
- **`audit_log`**: Append-only log of every action taken by every agent. Critical for debugging and trust-building with customers.
- **`incident_history`**: Record of past incidents, resolutions, and learnings. Agents query this to avoid repeating past mistakes.

### 3.2 Preventing Agent Conflicts

**Problem**: Two agents could try to modify the same dbt model at the same time (e.g., Schema Guardian adding a column while Documentation Agent updates descriptions).

**Solution: Resource Locking Protocol**

```
1. Before modifying any file, agent must acquire a lock:
   INSERT INTO locks (resource, agent, expires_at)
   VALUES ('models/stg_users.sql', 'schema_guardian', NOW() + INTERVAL '30 min')
   ON CONFLICT (resource) DO NOTHING
   RETURNING *;

2. If lock acquired (row returned): proceed with modification.

3. If lock NOT acquired: check who holds it and when it expires.
   - If expired: steal the lock (previous agent may have crashed).
   - If active: queue the task and retry after lock release.

4. After modification: release the lock.
   DELETE FROM locks WHERE resource = 'models/stg_users.sql' AND agent = 'schema_guardian';
```

**Additional conflict prevention**:

- **Git branch naming convention**: Each agent uses a prefix: `schema-guardian/`, `pipeline-doctor/`, etc. No two agents will create conflicting branches.
- **PR review before merge**: All agent-created PRs require human approval (or at minimum, another agent's review) before merging. This is a natural serialization point.
- **Orchestrator-level deconfliction**: The orchestrator can refuse to dispatch two tasks that touch the same resource simultaneously.

### 3.3 Human-in-the-Loop Model

The system uses a **tiered autonomy model** based on risk:

```
┌─────────────────────────────────────────────────────┐
│                AUTONOMY TIERS                       │
├─────────────┬───────────────────────────────────────┤
│             │                                       │
│  TIER 1     │  FULLY AUTONOMOUS                     │
│  (Auto-fix) │  - Read-only operations               │
│             │  - Retry transient failures            │
│             │  - Send notifications                  │
│             │  - Create PRs (not merge)              │
│             │  - Profile data                        │
│             │  - Run existing tests                  │
│             │  - Generate reports                    │
│             │                                       │
├─────────────┼───────────────────────────────────────┤
│             │                                       │
│  TIER 2     │  AUTO-FIX + NOTIFY                    │
│  (Fix +     │  - Apply additive schema changes      │
│   notify)   │  - Generate and add new dbt tests     │
│             │  - Generate documentation              │
│             │  - Retry failed pipelines (with limit) │
│             │  - Create tickets                      │
│             │                                       │
├─────────────┼───────────────────────────────────────┤
│             │                                       │
│  TIER 3     │  PROPOSE + WAIT FOR APPROVAL          │
│  (Propose)  │  - Merge PRs                          │
│             │  - Modify production dbt models        │
│             │  - Change materializations             │
│             │  - Alter warehouse objects (DDL)        │
│             │  - Change orchestrator schedules       │
│             │                                       │
├─────────────┼───────────────────────────────────────┤
│             │                                       │
│  TIER 4     │  ALERT ONLY (Never auto-fix)          │
│  (Alert)    │  - Breaking schema changes             │
│             │  - Data loss scenarios                  │
│             │  - Permission/access changes           │
│             │  - Warehouse resizing                  │
│             │  - Anything touching PII columns       │
│             │                                       │
└─────────────┴───────────────────────────────────────┘
```

**Approval flow for Tier 3+**:

```
Agent detects issue
  → Agent creates PR / proposal
    → Agent posts to Slack with context and ask
      → Human reviews and approves (Slack reaction, PR approval, or dashboard click)
        → Agent executes the approved action
          → Agent confirms completion
```

**Configurable per customer**: Some customers want everything in Tier 3+ (cautious). Others want agents to be more autonomous. The tier configuration is a per-customer setting.

### 3.4 Permissions & Access to Customer Infrastructure

```
┌─────────────────────────────────────────────────────┐
│           ACCESS MODEL                              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Principle: LEAST PRIVILEGE + AUDIT EVERYTHING      │
│                                                     │
│  Warehouse Access:                                  │
│  ├── Read-only role for all agents by default       │
│  ├── Write role for Schema Guardian (staging only)  │
│  ├── Admin role: NEVER granted to agents            │
│  └── All queries logged and attributable            │
│                                                     │
│  Git Access:                                        │
│  ├── Read access to dbt project repo                │
│  ├── Write access: branch + PR (not main)           │
│  ├── Merge: requires human approval                 │
│  └── Bot user with clear attribution                │
│                                                     │
│  Orchestrator Access:                               │
│  ├── Read: job status, logs, run history            │
│  ├── Write: trigger re-runs (with limits)           │
│  └── Admin: NEVER (no schedule changes w/o human)   │
│                                                     │
│  Credential Management:                             │
│  ├── Customer provides credentials via secure vault │
│  ├── Credentials scoped to minimum required access  │
│  ├── Rotated on customer-defined schedule           │
│  └── Never logged, never in agent context/prompts   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 4. Technical Integration Points

### 4.1 Connecting to a Customer's Data Stack

The integration surface is defined by **connectors** — each connector is an MCP server that wraps a specific system:

```
┌──────────────────────────────────────────────────────────────┐
│                    CONNECTOR LAYER                           │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │  Warehouse     │  │  dbt Project   │  │ Orchestrator  │  │
│  │  Connector     │  │  Connector     │  │ Connector     │  │
│  │                │  │                │  │               │  │
│  │ - Snowflake    │  │ - Git clone    │  │ - Airflow API │  │
│  │ - BigQuery     │  │ - dbt CLI      │  │ - Dagster API │  │
│  │ - Redshift     │  │ - Manifest     │  │ - Prefect API │  │
│  │ - Databricks   │  │   parsing      │  │ - dbt Cloud   │  │
│  │ - Postgres     │  │ - Schema.yml   │  │   API         │  │
│  │                │  │   editing      │  │               │  │
│  └────────────────┘  └────────────────┘  └───────────────┘  │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │  Notification  │  │  Catalog       │  │ Ingestion     │  │
│  │  Connector     │  │  Connector     │  │ Connector     │  │
│  │                │  │                │  │               │  │
│  │ - Slack        │  │ - Atlan        │  │ - Fivetran    │  │
│  │ - PagerDuty    │  │ - DataHub      │  │ - Airbyte     │  │
│  │ - Email        │  │ - OpenMetadata │  │ - Stitch      │  │
│  │ - Jira/Linear  │  │ - Alation     │  │ - Meltano     │  │
│  └────────────────┘  └────────────────┘  └───────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Each connector provides MCP tools like**:

```
# Warehouse Connector (Snowflake example)
- snowflake_query(sql: str, warehouse: str) -> ResultSet
- snowflake_get_schemas() -> List[Schema]
- snowflake_get_tables(schema: str) -> List[Table]
- snowflake_get_columns(table: str) -> List[Column]
- snowflake_get_query_history(hours: int) -> List[QueryRecord]
- snowflake_get_warehouse_usage() -> UsageReport

# dbt Connector
- dbt_compile(models: str) -> CompileResult
- dbt_test(models: str) -> TestResult
- dbt_run(models: str) -> RunResult  # Tier 3 — requires approval
- dbt_parse() -> Manifest
- dbt_source_freshness() -> FreshnessResult
- dbt_list(resource_type: str) -> List[str]
- dbt_get_manifest() -> Manifest  # parsed manifest.json
- dbt_get_catalog() -> Catalog   # parsed catalog.json

# Git Connector
- git_diff(branch: str) -> Diff
- git_create_branch(name: str) -> Branch
- git_commit(files: List[str], message: str) -> Commit
- git_create_pr(title: str, body: str, branch: str) -> PR
- git_get_recent_commits(n: int) -> List[Commit]
```

### 4.2 Deployment Model

Three options, with a recommended path:

#### Option A: Fully Managed SaaS (Recommended for MVP)

```
┌─────────────────────────────────────────────────┐
│              OUR INFRASTRUCTURE                 │
│                                                 │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐ │
│  │Orchestr- │  │Specialist │  │Shared State  │ │
│  │ator      │  │Agents     │  │Store         │ │
│  └────┬─────┘  └─────┬─────┘  └──────────────┘ │
│       │               │                         │
│  ┌────▼───────────────▼──────────────────────┐  │
│  │         Connector Layer (MCP)             │  │
│  └────────────────┬──────────────────────────┘  │
│                   │                             │
└───────────────────┼─────────────────────────────┘
                    │ Secure tunnel (SSH / mTLS / VPN)
┌───────────────────▼─────────────────────────────┐
│          CUSTOMER INFRASTRUCTURE                │
│                                                 │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐ │
│  │Snowflake │  │GitHub/    │  │Airflow/      │ │
│  │/BigQuery │  │GitLab     │  │Dagster       │ │
│  └──────────┘  └───────────┘  └──────────────┘ │
└─────────────────────────────────────────────────┘
```

**Pros**: Fastest to build and deploy. No customer infrastructure management. Easy updates.
**Cons**: Customers must trust us with credentials. Latency for queries. May not meet compliance requirements.

#### Option B: Hybrid (Agent in Customer VPC)

A lightweight agent runner deploys in the customer's cloud (as a container). The agent runner executes tools locally (SQL queries, dbt commands) but reports to our control plane.

**Pros**: Data never leaves customer infrastructure. Lower latency. Meets compliance requirements.
**Cons**: More complex deployment. Customer must run our container. Updates require re-deployment.

#### Option C: Fully On-Prem

Everything runs in customer infrastructure.

**Pros**: Maximum security. Full control.
**Cons**: Extremely complex to support. Every customer is a snowflake. Not viable for a startup.

**Recommendation**: Start with **Option A (SaaS)** for MVP. Build **Option B (Hybrid)** for enterprise customers who need it. Never build Option C.

### 4.3 Security Considerations

```
┌─────────────────────────────────────────────────┐
│            SECURITY REQUIREMENTS                │
├─────────────────────────────────────────────────┤
│                                                 │
│  Credential Management                          │
│  ├── All creds in a secrets manager (Vault/AWS) │
│  ├── Short-lived tokens where possible           │
│  ├── Service accounts with minimum privileges    │
│  ├── Credential rotation support                 │
│  └── Never in logs, prompts, or agent memory     │
│                                                 │
│  Data Access                                     │
│  ├── Agents NEVER read actual customer data rows │
│  │   unless specifically profiling with approval │
│  ├── Metadata-only by default (schemas, counts)  │
│  ├── Configurable data access policies per table │
│  ├── PII columns auto-detected and excluded      │
│  └── Query result size limits                    │
│                                                 │
│  Audit & Compliance                              │
│  ├── Every agent action logged with timestamp    │
│  ├── Every SQL query logged                       │
│  ├── Every git operation logged                   │
│  ├── Audit logs immutable and exportable          │
│  ├── SOC 2 Type II target                        │
│  └── Customer can review all agent actions        │
│                                                 │
│  Network Security                                │
│  ├── All connections TLS 1.3                      │
│  ├── IP allowlisting for warehouse connections   │
│  ├── Private Link / VPC peering for enterprise   │
│  └── No inbound connections required             │
│                                                 │
│  LLM Security                                    │
│  ├── Customer data not used for model training   │
│  ├── Prompt injection defense on all inputs      │
│  ├── Output filtering for credential leaks       │
│  └── Model API calls don't include raw data      │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 5. Build Considerations

### 5.1 MVP Definition

**MVP Scope: Pipeline Doctor + Quality Sentinel for dbt + Snowflake**

Why these two agents:
1. **Pipeline Doctor** is the highest-urgency pain point — pipeline failures wake people up at 3am. Immediate value.
2. **Quality Sentinel** is the highest-frequency value — data quality issues are constant and under-addressed.
3. **dbt + Snowflake** is the most common modern data stack. Largest addressable market.

**MVP Feature Set**:

```
Pipeline Doctor (MVP)
├── Monitor dbt Cloud job failures via API
├── Read error logs and classify failure type
├── For transient failures: auto-retry (up to 2x)
├── For code errors: diagnose and create a GitHub issue with context
├── Post summary to Slack
└── Dashboard showing pipeline health over time

Quality Sentinel (MVP)
├── After each dbt run: query row counts for key models
├── Compare against 7-day trailing average
├── Flag anomalies (>30% deviation) in Slack
├── Weekly: scan for models with 0 tests
├── Generate basic tests for untested models
└── Create PR with proposed tests
```

**MVP Tech Stack**:

```
Agent Runtime:    Claude API (claude-sonnet-4-20250514)
Orchestration:    Simple cron (no need for a framework yet)
State Store:      PostgreSQL (single table for tasks, locks, logs)
Tool Layer:       3 MCP servers (Snowflake, dbt Cloud, GitHub)
Notification:     Slack webhook
Frontend:         Simple dashboard (Next.js) showing agent activity
Auth:             OAuth2 for customer connections
Hosting:          AWS (ECS for agent runtime, RDS for state)
```

**MVP Timeline Estimate**: 6-8 weeks for a working prototype with a design partner.

### 5.2 What's Hardest Technically

In descending order of difficulty:

#### 1. Reliable diagnosis of pipeline failures

Pipeline failures have infinite variety. The agent needs to:
- Parse diverse error messages (dbt compilation errors, SQL runtime errors, Python exceptions, infra errors)
- Distinguish between root cause and symptom (a downstream model fails because an upstream source is stale — the root cause is the source, not the model)
- Know when it doesn't know and escalate rather than hallucinate a fix

**Mitigation**: Start with a small set of well-understood failure patterns. Build a growing library of diagnostic playbooks. Use few-shot examples in the prompt. Log every diagnosis for human review and feedback.

#### 2. Safe autonomous action in production

The blast radius of a wrong action in a production data pipeline is large. The agent could:
- Retry a job that's failing because of bad data, amplifying the problem
- Create a "fix" PR that introduces a new bug
- Overwhelm Slack with false positive alerts

**Mitigation**: Start with everything in Tier 1 (read-only). Graduate actions to Tier 2+ only after confidence is established. Every action is reversible or approvable. Rate limiting on all write operations.

#### 3. Understanding customer-specific context

Every dbt project is different. Column names, business logic, conventions, and expectations vary wildly. The agent needs to understand:
- What "normal" looks like for this customer's data
- Which models are business-critical vs experimental
- Customer-specific naming conventions and patterns

**Mitigation**: Onboarding process that profiles the project. Customer-configurable settings (critical models, SLA thresholds, naming conventions). Learning loop where the agent improves over time based on human feedback.

#### 4. Multi-warehouse, multi-tool support

Supporting Snowflake + dbt Cloud is one thing. Supporting Snowflake + BigQuery + Redshift + Databricks, and Airflow + Dagster + Prefect + dbt Cloud + custom orchestrators, creates a combinatorial explosion.

**Mitigation**: Start with ONE warehouse (Snowflake) and ONE orchestrator (dbt Cloud). Add others only when customer demand justifies it. Use the MCP connector abstraction to keep the agent logic warehouse-agnostic.

### 5.3 Existing Building Blocks to Leverage

| Building Block | What It Gives Us | Maturity |
|---|---|---|
| **Claude API (Sonnet/Opus)** | The agent brain. Best-in-class for code understanding, tool use, and complex reasoning. | Production-ready |
| **MCP Protocol** | Standard for tool integration. Growing ecosystem of community MCP servers. | Production-ready, ecosystem growing |
| **Existing MCP Servers** | Community servers for PostgreSQL, GitHub, Slack, filesystem. May have Snowflake. | Varies; many are early-stage |
| **Claude Agent SDK** | Python SDK for building agents with tool use, sub-agents, guardrails. | Early but usable |
| **dbt artifacts** | `manifest.json` and `catalog.json` contain rich metadata about the project: models, tests, columns, lineage, SQL. This is the single most valuable data source for our agents. | Mature |
| **dbt Cloud API** | Job management, run status, artifact retrieval. | Mature |
| **Snowflake ACCOUNT_USAGE** | Query history, warehouse usage, storage usage. Rich data for Cost Optimizer. | Mature |
| **GitHub API** | PR creation, branch management, file operations. | Mature |
| **Slack API** | Messaging, threads, reactions (can be used for approval flows). | Mature |

### 5.4 Architecture Decision: Framework vs. Raw SDK

**Option A: Use a multi-agent framework (LangGraph, CrewAI)**

Pros: Pre-built orchestration, state management, human-in-the-loop patterns.
Cons: Added dependency, opinionated abstractions that may not fit, slower to iterate, harder to debug, tied to their roadmap.

**Option B: Build on raw Claude API + MCP (Recommended)**

Pros: Full control, simpler debugging, no framework lock-in, can adopt best patterns from multiple frameworks.
Cons: Must build orchestration ourselves.

**Recommendation**: Option B. The orchestration logic for our use case is not complex enough to justify a framework. Our orchestrator is essentially: (1) receive trigger, (2) determine which agent should handle it, (3) spawn agent with appropriate system prompt and tools, (4) agent runs to completion, (5) update state. This is straightforward to build with the Claude API.

We should study the patterns from LangGraph (state machines), OpenAI Agents SDK (handoffs, guardrails), and CrewAI (memory) and implement the ones we need directly. This gives us the flexibility to evolve our architecture without being constrained by someone else's abstractions.

### 5.5 Phased Roadmap

```
Phase 0: Foundation (Weeks 1-3)
├── Build MCP servers: Snowflake connector, dbt Cloud connector, GitHub connector
├── Build shared state store (Postgres)
├── Build agent runner (spawn Claude with system prompt + tools, run to completion)
├── Build Slack notification integration
└── Set up logging, monitoring, audit trail

Phase 1: Pipeline Doctor MVP (Weeks 4-6)
├── Implement failure detection (poll dbt Cloud API for failed runs)
├── Implement failure classification (parse error messages, categorize)
├── Implement auto-retry for transient failures
├── Implement diagnostic report generation (Slack message with context)
├── Test with design partner's dbt Cloud project
└── Iterate based on feedback

Phase 2: Quality Sentinel MVP (Weeks 7-9)
├── Implement post-run row count monitoring
├── Implement anomaly detection (statistical baseline + threshold)
├── Implement test coverage analysis
├── Implement test generation (schema.yml PRs)
├── Test with design partner
└── Iterate based on feedback

Phase 3: Schema Guardian + Hardening (Weeks 10-14)
├── Implement schema change detection (INFORMATION_SCHEMA diffing)
├── Implement impact analysis (dbt manifest lineage traversal)
├── Implement auto-PR for additive changes
├── Build customer dashboard (agent activity, actions taken, approvals pending)
├── Implement approval workflow (Slack reactions or dashboard)
├── Security hardening, audit log export, SOC 2 prep
└── Onboard 3-5 design partners

Phase 4: Scale (Weeks 15+)
├── Add Cost Optimizer
├── Add Documentation Agent
├── Support BigQuery
├── Support Airflow
├── Multi-tenant infrastructure
└── Self-serve onboarding
```

---

## Appendix A: Competitive Landscape

The data observability / data reliability space has several players. Our differentiation is **autonomous action** vs. passive monitoring.

| Company | What They Do | Gap We Fill |
|---------|-------------|-------------|
| **Monte Carlo** | Data observability — detects anomalies, provides lineage | Alerts but doesn't fix. No autonomous action. |
| **Elementary** | dbt-native data observability | Monitoring only. No remediation. |
| **Datafold** | Data diffing, CI/CD for data | Focused on CI. No production monitoring or auto-fix. |
| **Metaplane** | Data observability | Monitoring + alerting. No autonomous action. |
| **Atlan** | Data catalog + governance | Documentation, not operational. No auto-fix. |
| **Great Expectations / Soda** | Data quality testing frameworks | Tools, not agents. Require humans to write and run tests. |

**Our positioning**: These tools tell you something is wrong. We fix it. The shift from "observability" to "autonomous operations" is the category we're creating.

---

## Appendix B: Key Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Agent hallucinates a fix that breaks production | Critical | Medium | Tier system, PR review requirement, no auto-merge in MVP |
| LLM API costs are too high for continuous monitoring | High | Medium | Use Haiku for simple classification, Sonnet for complex diagnosis. Cache common patterns. |
| Customer reluctant to grant warehouse credentials | High | High | Start with read-only. Offer hybrid deployment. SOC 2. |
| False positive alerts cause alert fatigue | High | High | Tunable thresholds per customer. Track alert-to-action ratio. Suppress repeated alerts. |
| dbt project complexity exceeds agent understanding | Medium | Medium | Start with simple projects. Build complexity tolerance iteratively. |
| MCP server reliability issues | Medium | Low-Medium | Build our own critical MCP servers (don't rely on community). Retry logic. Circuit breakers. |

---

## Appendix C: Cost Model Estimate (Per Customer)

Assuming a medium-sized dbt project (200 models, 4 pipeline runs/day):

| Component | Monthly Cost |
|-----------|-------------|
| Claude API (Sonnet) — agent reasoning | $150-400 (depends on incident volume) |
| Claude API (Haiku) — classification, simple tasks | $20-50 |
| Infrastructure (ECS, RDS, networking) | $100-200 (amortized across customers) |
| Snowflake queries (INFORMATION_SCHEMA, profiling) | $10-30 (read-only, small queries) |
| GitHub API | Free (within rate limits) |
| Slack API | Free |
| **Total per customer** | **~$300-700/month** |

At a price point of $2,000-5,000/month per customer, margins are healthy. The primary cost driver is LLM API calls, which will decrease over time as model costs drop and we cache/optimize.
