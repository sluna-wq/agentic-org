# WT-06: The Data Is Stale

**Theme**: Freshness monitoring, schedule debugging, orchestration failure modes
**Time**: ~45–60 minutes
**Prior walkthroughs**: WT-01–05 recommended but not required

---

## The Scenario

It's Monday morning, 9:00 AM.

The CEO opens the revenue dashboard and notices something off. The chart stops updating on Friday. Not Friday morning — Friday evening. It's now 60+ hours later and the pipeline has been running on schedule all weekend.

**Slack:**

> **@ceo** → **#data-team** (9:02 AM)
> Hey — revenue dashboard looks like it stopped updating Friday evening? Seeing data through Feb 8 but it's Feb 12 now. Is this a display issue?
>
> **@data-team** → (9:04 AM)
> On it now. Pipeline shows green all weekend — let me dig in.
>
> **@ceo** → (9:05 AM)
> Missing 3 days of data on a Monday doesn't feel great. We had a big weekend push.
>
> **@data-team** → (9:06 AM)
> Understood. I'll have a root cause in 20 minutes.

You open your laptop. The orchestrator dashboard looks clean — every job shows a green checkmark. All weekend. Exit code 0. No errors. No retries.

But the CEO is right. The data is definitely stale.

Something ran. Something looks fine. And something is wrong.

---

## Setup

1. **Navigate to this directory**: `walkthroughs/wt06_data_stale/`

2. **Load the seed data**:
   ```bash
   dbt seed
   ```
   This creates four tables in the `raw` schema:
   - `raw_orders` — 32 orders, Jan 2024 through Feb 8 2024
   - `raw_events` — 40 user events (signups, purchases, pageviews), through Feb 8
   - `raw_customers` — 20 customers, Jan–Feb 2024
   - `raw_pipeline_runs` — 15 pipeline execution records (the key evidence table)

3. **Run the models**:
   ```bash
   dbt run
   ```
   This builds the staging views and mart tables in their current (stale) state.

4. **Check the dashboard numbers**:
   ```sql
   select max(order_date) from fct_revenue_daily;
   -- Returns: 2024-02-08 — data stopped updating here
   ```

5. **Open `analyses/01_investigation.sql`** and work through the queries in order.

6. **Once you've identified the root cause**, read `analyses/02_solution.sql` for the fix and prevention strategies.

7. **Apply the fix** (correct the dbt command, re-run marts), then run `analyses/03_verification.sql` to confirm health.

---

## The Schema

```
raw_orders              raw_events              raw_customers
----------              ----------              -------------
order_id (PK)           event_id (PK)           customer_id (PK)
customer_id             customer_id             name
order_date              event_type              email
amount                  event_date              signup_date
status                  properties              plan

raw_pipeline_runs   ← THE KEY TABLE
-----------------
run_id (PK)
run_date
status              ← always 'success' (misleading)
exit_code           ← always 0 (misleading)
models_run          ← THIS IS THE SMOKING GUN
duration_seconds    ← secondary signal (shorter than expected)
```

**The trap**: `status` and `exit_code` in `raw_pipeline_runs` look fine for every run.
The anomaly is in `models_run` — and you have to know to look for it.

---

## Learning Objectives

By the end of this walkthrough you should be able to:

1. **Distinguish pipeline success from data freshness** — exit code 0 does not mean your data is current
2. **Detect staleness by querying the data** — `MAX(updated_at)` vs `NOW()` is your first check, not the orchestrator dashboard
3. **Identify the silent skip failure mode** — when a partial execution produces no error but leaves data unfreshed
4. **Read dbt selector syntax** — understand the difference between `dbt run` (all models), `dbt run --select staging.*` (staging only), and tag-based selection
5. **Trace a DAG gap** — find which models are downstream of the skipped layer and quantify the blast radius
6. **Configure dbt source freshness** — set warn/error thresholds in your source YAML
7. **Write a freshness test** — create a dbt singular test that fails when data exceeds a staleness SLA
8. **Design a freshness monitoring strategy** — separate the "pipeline health" signal from the "data health" signal

---

## Key Concepts

### Data freshness is not pipeline success

Most orchestrators (Airflow, Prefect, Dagster, GitHub Actions) measure job health via exit codes. Exit code 0 = success. This is correct as far as the orchestration layer is concerned: the job ran without crashing.

But a dbt job with `--select staging.*` exits 0 after running only staging models. The orchestrator sees success. The mart layer hasn't moved.

**Rule**: Check the data, not the process. `MAX(updated_at) > NOW() - INTERVAL '25 hours'` is the health check that matters for dashboards.

### The silent skip

A silent skip is a partial execution that looks like full success:

```
Feb 9  dbt run --select staging.*
       → stg_orders:     PASS ✓
       → stg_events:     PASS ✓
       → stg_pipeline_runs: PASS ✓
       → fct_revenue_daily: [not in scope — not run]
       → fct_daily_signups: [not in scope — not run]
       exit code: 0
       orchestrator: SUCCESS ✓
```

Nothing failed. Nothing was skipped with a warning. The excluded models simply weren't on the list.

Silent skips are scarier than errors because errors create alerts. Silent skips create nothing — until someone checks the data.

### dbt --select selectors

```bash
dbt run                         # All models in the project
dbt run --select staging.*      # Only models in staging/ folder
dbt run --select marts.*        # Only models in marts/ folder
dbt run --select stg_orders+    # stg_orders and all downstream models
dbt run --select +fct_revenue_daily  # fct_revenue_daily and all upstream models
dbt run --select tag:mart       # All models tagged 'mart'
```

The `--select staging.*` selector is useful for development and partial refreshes. It is dangerous as the sole production command because it silently excludes mart models and anything downstream of them.

### dbt source freshness

dbt has built-in freshness checking for source tables. Configure it in your source YAML:

```yaml
sources:
  - name: raw
    freshness:
      warn_after: {count: 1, period: day}
      error_after: {count: 2, period: day}
    tables:
      - name: raw_orders
        loaded_at_field: _loaded_at  # timestamp column on the source table
```

Run `dbt source freshness` after `dbt run` to validate your sources are within SLA. If they're not, fail the job before the mart layer even runs.

### Materialized tables vs views

| Type | Behavior when pipeline skips |
|------|-------------------------------|
| `view` | Re-executes on every query — always shows current raw data |
| `table` | Frozen until explicitly re-run — holds last-refresh snapshot |

Staging models as views means they're never stale (they query raw directly). Mart models as tables means they're only as fresh as their last `dbt run`. This is usually what you want — until the `dbt run` stops including them.

---

## Step-by-Step Guide

### Phase 1: Detect staleness — check the data, not the dashboard (10 min)
- Run `analyses/01_investigation.sql` Steps 1–2
- Goal: confirm MAX(order_date) in mart tables is Feb 8
- Goal: verify that staging views show the same raw data cutoff (establishing that raw data is the baseline)
- Key question: are staging and mart tables aligned? If marts are older than staging data, the pipeline stopped refreshing them.

### Phase 2: Check pipeline logs — read carefully (10 min)
- Run Steps 3–4 of the investigation queries
- Goal: find the `models_run` column in the pipeline audit log
- The initial read looks clean: success, exit_code=0, all weekend
- The second look reveals the anomaly: every run since Feb 9 shows `models_run = staging.*`
- Key insight: the orchestrator is telling the truth — it just doesn't know what you need to know

### Phase 3: Identify the phantom successes (5 min)
- Run Step 4's phantom success query
- Goal: quantify how many consecutive runs failed to refresh the mart layer
- Notice the duration signal: full runs ~145s, staging-only runs ~40s
- Ask: when did this change? What happened between run_011 (Feb 8, full) and run_012 (Feb 9, staging-only)?

### Phase 4: Assess blast radius (5 min)
- Run Step 6 of the investigation queries
- Goal: list every mart table affected and estimate the missing data volume
- For this walkthrough: fct_revenue_daily and fct_daily_signups, both frozen since Feb 8
- In production: run `dbt ls --select staging.*+` to find all downstream models

### Phase 5: Fix and prevent (15 min)
- Follow `analyses/02_solution.sql`
- Fix 1: Correct the orchestrator command (`dbt run`, no --select)
- Fix 2: Manually trigger `dbt run --select marts.*` to catch up immediately
- Fix 3: Add the freshness monitoring query as a scheduled check
- Fix 4: Add `tests/assert_freshness.sql` to dbt test suite
- Confirm with `analyses/03_verification.sql`

---

## Agent Lens

*This section is for the second pass: run the walkthrough as an agent.*

**What could an agent do automatically?**

- **Detect staleness proactively**: Run `MAX(order_date) vs. NOW()` on every mart table on a schedule. Alert within 25 hours of staleness — not 60. The CEO never sees the problem.
- **Parse pipeline audit logs**: Query `raw_pipeline_runs`, flag any run where `models_run` doesn't cover the full DAG. Immediate alert on first phantom success.
- **Duration anomaly detection**: Track run duration against rolling average. A run that completes in 40s when the norm is 145s is a signal — fire an alert, don't wait for data to get stale.
- **Blast radius enumeration**: Given `stg_pipeline_runs` identifying which runs were staging-only, compute exactly which mart models are affected and for how many days.
- **Draft the fix**: Generate the corrected orchestrator command, the manual remediation `dbt run --select marts.*`, and the freshness test.

**What needs human judgment?**

- **SLA definition**: Is 24-hour staleness acceptable for the revenue dashboard? What about 6 hours? 1 hour? This is a business decision, not a technical one. Different metrics have different tolerances.
- **Configuration review**: Who changed `--select staging.*` and why? Was it intentional optimization or a mistake? That changes the response.
- **Orchestrator approval**: Changing the orchestrator config is infrastructure — it needs human review, a PR, and a deployment gate. An agent can draft the change, but a human approves it.
- **Stakeholder communication**: How do we tell the CEO that we had 60 hours of stale data and here's why? The agent can draft the message; a human sends it.
- **SLA threshold negotiation**: The freshness test uses 25 hours. Is that right? Finance might want 6 hours for revenue. Marketing might accept 48 hours for cohort data. Setting thresholds is a business conversation.

**Form factor insight:**

The investigation in this walkthrough compresses from 20-60 minutes of manual query-running to under 60 seconds for an agent with `db_query` and log access. But more importantly: an agent running freshness checks on a schedule would have caught this on Feb 10 morning — 47 hours earlier than the CEO did. The value isn't faster investigation. It's earlier detection. This is the difference between a proactive data platform and a reactive one.

---

## Key Takeaways

1. **Orchestrator green ≠ data fresh** — these are different signals and must be monitored separately
2. **Silent skips are the hardest failure** — no alert fires, everything looks fine, data ages quietly
3. **`dbt run` with no selector is safer than `dbt run --select staging.*`** — partial selectors in production need explicit mart coverage
4. **Check the data to validate the pipeline** — `MAX(order_date)` is the health check, not exit code
5. **Duration is a signal** — a 40-second "full pipeline success" warrants investigation when your norm is 145 seconds
6. **Freshness monitoring is a separate system** — your orchestrator monitors job health; you need something separate monitoring data health
7. **dbt source freshness + singular tests = two-layer defense** — source freshness catches upstream delays; assertion tests catch mart-layer staleness

---

## Files in This Walkthrough

```
wt06_data_stale/
├── README.md                           ← You are here
├── dbt_project.yml
├── seeds/
│   ├── raw_orders.csv                  ← 32 orders (Jan–Feb 8 2024)
│   ├── raw_events.csv                  ← 40 user events (through Feb 8)
│   ├── raw_customers.csv               ← 20 customers
│   └── raw_pipeline_runs.csv           ← 15 pipeline runs (THE KEY TABLE)
├── models/
│   ├── staging/
│   │   ├── src_acme.yml                ← Source defs with freshness thresholds
│   │   ├── stg_models.yml              ← Column docs and tests
│   │   ├── stg_orders.sql              ← Clean (view — always current)
│   │   ├── stg_events.sql              ← Clean (view — always current)
│   │   └── stg_pipeline_runs.sql       ← Parsed audit log with diagnostic fields
│   └── marts/
│       ├── fct_revenue_daily.sql       ← STALE (correct SQL, never re-run after Feb 8)
│       └── fct_daily_signups.sql       ← STALE (same reason)
├── analyses/
│   ├── 01_investigation.sql            ← Work through this first (6 phases)
│   ├── 02_solution.sql                 ← Fix + freshness monitoring patterns
│   ├── 03_verification.sql             ← Run after applying the fix
│   └── 04_postmortem.md               ← Retrospective + agent perspective
└── tests/
    └── assert_freshness.sql            ← dbt singular test: fails if mart > 25h stale
```
