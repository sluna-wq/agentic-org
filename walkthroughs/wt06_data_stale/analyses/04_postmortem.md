# WT-06 Postmortem: The Phantom Success

## Incident Summary

| Field | Detail |
|-------|--------|
| **Symptom** | Revenue and signups dashboards showing data as of Feb 8; today is Feb 12 |
| **Duration** | 60+ hours of stale data (Fri evening through Mon morning) |
| **Root cause** | Orchestrator dbt command used `--select staging.*`, silently excluding all mart models |
| **Why it was hidden** | dbt exited 0, orchestrator marked job green — no error, no warning |
| **Impact** | 3 days of revenue and growth data missing from exec dashboards |
| **Time to detect** | ~60 hours (detected Monday when CEO opened the dashboard) |
| **Time to fix** | ~20 min once root cause identified |
| **Prevented recurrence?** | Yes — freshness test added, orchestrator command corrected |

---

## Timeline

| Time | Event |
|------|-------|
| Feb 8, 6:15 PM | Last full pipeline run completes (run_011). All models including marts refresh correctly. |
| Feb 9, 6:00 AM | Pipeline runs with new `--select staging.*` command. Staging refreshes. Marts skipped. dbt exits 0. Orchestrator: green. |
| Feb 9–11 | Three more runs. All staging-only. All green. Marts frozen. Nobody notices. |
| Feb 12, 9:00 AM | CEO opens revenue dashboard. Data shows Feb 8. "Why is this from last week?" |
| Feb 12, 9:05 AM | Data team alerted. Investigation begins. |
| Feb 12, 9:20 AM | Investigation Step 4 reveals: Feb 9-11 runs all show `models_run = staging.*` |
| Feb 12, 9:25 AM | Root cause confirmed: orchestrator config was changed (--select flag added). |
| Feb 12, 9:35 AM | Fix deployed: orchestrator config corrected, `dbt run --select marts.*` triggered manually. |
| Feb 12, 9:40 AM | Marts refreshed. Dashboard shows current data. |
| Feb 12, 9:45 AM | Freshness test added to dbt project. Postmortem filed. |

---

## What Happened

On Feb 9, someone (or an automated process) changed the orchestrator's dbt command from `dbt run` to `dbt run --select staging.*`.

The intent was likely performance optimization — staging-only runs are ~4x faster than full runs. Or the change may have been a configuration mistake during a maintenance window.

The consequence: all mart models (`fct_revenue_daily`, `fct_daily_signups`) were excluded from every subsequent run. dbt ran the staging models successfully, exited with code 0, and the orchestrator declared success. The mart tables, being materialized as physical tables, held their Feb 8 state indefinitely — waiting for a refresh that never came.

This is the "phantom success" failure mode: everything looks green, nothing looks wrong, and your data silently ages.

---

## Root Cause

**Partial selector without downstream coverage.** The command `dbt run --select staging.*` is a valid, useful command — but only when you intend to refresh staging models exclusively. When used as the *only* pipeline command, it creates a persistent gap between staging data (fresh, because views re-execute) and mart data (frozen, because tables don't refresh themselves).

**Contributing factors:**
1. No freshness monitoring on mart tables — no automated check on MAX(updated_at) vs. current time
2. Orchestrator success criteria too narrow — exit code 0 was the only health signal, with no mart-layer validation
3. No duration anomaly detection — full runs take ~145s, staging-only runs take ~40s. The drop was observable but unmonitored.
4. Config change had no review — the orchestrator command was modified without a PR or review gate
5. Weekend timing — the change took effect Friday evening, accumulating 60+ hours of staleness before business hours Monday

---

## The Silent Skip Failure Mode

This incident illustrates a class of failure distinct from errors and crashes: the **silent skip**.

| Failure type | What you see | What you investigate |
|---|---|---|
| Hard error | Pipeline shows FAILED, error message | Fix the error |
| Soft error | Pipeline shows FAILED, vague warning | Dig into logs |
| **Silent skip** | **Pipeline shows SUCCESS** | **Nothing — you don't know to investigate** |

Silent skips are the most dangerous because they generate no alert. The system behaved exactly as configured — it just wasn't configured correctly. Detection requires external validation: checking the data itself, not just the process that produced it.

**Data freshness monitoring is the only defense against silent skips.**

---

## Changes Made

### Immediate
- [x] Orchestrator config corrected: `dbt run --select staging.*` → `dbt run`
- [x] Manual `dbt run --select marts.*` triggered to refresh stale tables
- [x] Dashboards confirmed healthy (Feb 11 data now visible)

### Short-term (this sprint)
- [ ] Add `tests/assert_freshness.sql` to dbt project (already done in this walkthrough)
- [ ] Add mart freshness check to orchestrator post-run step: if MAX(order_date) < yesterday → fail the job
- [ ] Add duration monitoring: alert if a "successful" run completes in <60 seconds (staging-only signal)
- [ ] Require dbt source freshness to pass before marking pipeline job as complete

### Medium-term (next sprint)
- [ ] Add `_loaded_at` timestamp column to raw tables (ingestion layer responsibility)
- [ ] Configure `dbt source freshness` with warn/error thresholds in src_acme.yml
- [ ] Pipeline config changes require PR review and explicit staging/mart coverage checklist
- [ ] Add Slack alert: if fct_revenue_daily hasn't updated by 7 AM → page data on-call

### Long-term (next quarter)
- [ ] Automated DAG coverage validation: given a dbt --select argument, enumerate which mart models are included. Fail CI if coverage < 100%.
- [ ] Data contracts: marts publish their SLA; orchestrator enforces it as a health gate
- [ ] Observability layer: data freshness dashboard separate from pipeline status dashboard

---

## What Went Well

- Investigation query sequence traced the problem in under 20 minutes once started
- Pipeline audit log (`raw_pipeline_runs`) provided a clean evidence trail
- The fix was non-destructive — mart refresh from staging was instant and complete
- No data was lost — raw and staging always held the correct data, marts just needed a refresh

## What Could Be Better

- 60 hours is too long to go undetected for a CEO-visible metric
- "Pipeline is green" and "data is fresh" should be two separate health signals, not one
- The configuration change should have been reviewed — any change to the dbt run command affects the entire mart layer
- Weekend coverage was blind — no alert fired over two days of accumulating staleness

---

## Agent Perspective

**What an agent could have caught automatically:**

1. **Staleness detection (5 min after the Feb 9 run)**: A scheduled check running `MAX(order_date) vs NOW()` on fct_revenue_daily would have caught 24h staleness on Feb 10 morning — 50 hours before the CEO noticed.

2. **Duration anomaly (immediately)**: Monitoring run duration against a rolling average. Feb 9 run: 41s vs. 7-day avg of 145s. Ratio = 0.28. Auto-alert: "This run was unusually fast — possible scope reduction."

3. **Log parsing (immediately)**: Parse the `models_run` column from pipeline audit logs. If `models_run` doesn't include mart models → immediate warning, regardless of exit code.

4. **Blast radius (on detection)**: Enumerate all mart models + downstream dashboards affected. Quantify estimated missing revenue. Draft remediation plan.

**What needs human judgment:**

- Is 24h staleness acceptable for this metric? (Business SLA question — varies by metric)
- Who changed the orchestrator config and why? (Organizational accountability)
- Should we approve the config change or revert it? (Intent clarification)
- How do we communicate this to the CEO? (Relationship management)
- What's the acceptable SLA for future incidents? (Business priority decision)

**Form factor insight:**

The full investigation in this walkthrough takes an experienced data engineer 20-60 minutes. An agent with `db_query` access and pipeline log access runs all 6 investigation steps in under 60 seconds and surfaces the root cause immediately. The human's job: review the evidence, decide the SLA thresholds, approve the config fix, handle stakeholder communication.

The agent saves the investigation. The human makes the decisions.

---

## Key Lesson

> **Orchestrator success ≠ data freshness.**
>
> These are two separate health signals that must be monitored independently. A pipeline job can run successfully, exit cleanly, and report green — while the data it's supposed to refresh sits frozen and aging.
>
> Never trust exit code 0 alone. Always validate the data.
