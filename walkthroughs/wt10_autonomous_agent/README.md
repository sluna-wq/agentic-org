# WT-10: The Autonomous Agent

**Scenario**: "Monday morning. Nobody called. The agent found four things."

> It is 06:47 on Monday. No Slack alerts. No PagerDuty page. No ticket in the queue.
> The autonomous agent ran its scheduled sweep at 06:00 and produced a triage report.
> By the time the data team arrives at 09:00, three issues will be fixed and one will be waiting
> in the compliance team's inbox with full documentation.
>
> This is what autonomous data engineering looks like.

---

## The Situation

ACME Analytics operates a production data stack serving Finance, Sales, Marketing, and a growing
customer-facing analytics product. The agent runs a proactive sweep every Monday at 06:00 — not
responding to an incident, but scanning the full stack for latent issues before anyone notices them.

This Monday's sweep surfaces four simultaneous findings:

| # | Finding | Class | Severity | Agent Action |
|---|---------|-------|----------|--------------|
| 1 | `fct_order_revenue` double-counts orders due to a fan-out join | Correctness | CRITICAL | Fix autonomously |
| 2 | `fct_customer_metrics` last refreshed 3 days ago (Thursday 22:14) | Staleness | HIGH | Fix autonomously |
| 3 | `fct_customer_metrics` exposes raw email addresses in a customer-facing mart | Compliance | HIGH | Escalate to human |
| 4 | Revenue is defined two ways — `fct_order_revenue` and `fct_revenue_summary` disagree by $80K | Metrics | MEDIUM | Fix autonomously |

The agent must:
1. Detect all four issues in a single sweep pass
2. Triage: assign severity and determine autonomous vs. escalate
3. Execute autonomous fixes for findings #1, #2, #4
4. Generate a compliance escalation package for finding #3 — and stop there
5. Produce a Monday morning brief for the data team

---

## Why This Is the Capstone

WT-01 through WT-09 each isolated a single scenario class:
- One bug, one investigation, one fix.

WT-10 is the real operating condition:
- **Multiple issue classes simultaneously**
- **Triage is the first artifact** — the agent must decide priority order before acting
- **Not everything gets fixed** — compliance escalations require human judgment
- **The human handoff is designed, not accidental** — the agent knows what it cannot do

This is what separates a reactive troubleshooter from an autonomous operator.

---

## Estimated Time: 90 min

| Phase | Time | What You're Doing |
|-------|------|-------------------|
| 1. Sweep | 15 min | Run the 06:00 scan, surface all four findings |
| 2. Triage | 10 min | Prioritize, classify autonomous vs. escalate |
| 3. Fix #1 | 15 min | Grain violation — fix the fan-out join |
| 4. Fix #2 | 10 min | Staleness — diagnose why the refresh failed, repair |
| 5. Escalate #3 | 15 min | Build compliance package, write the handoff doc |
| 6. Fix #4 | 15 min | Metrics alignment — canonicalize the revenue definition |
| 7. Brief | 10 min | Generate Monday morning summary for the data team |

---

## Background: The ACME Stack

ACME Analytics has 3,200 customers, $1.4M ARR, and a data stack that has grown organically
over 18 months. The Monday sweep covers:

- **Orders pipeline**: Stripe + internal order system → `fct_order_revenue`
- **Customer metrics**: CRM sync → `fct_customer_metrics` (customer-facing product)
- **Revenue summary**: Finance rollup → `fct_revenue_summary`
- **Customer master**: Identity + PII source → `dim_customers`

### Finding #1: Grain Violation in `fct_order_revenue`

**Root cause**: A join to `raw_order_items` was added in a schema migration last week (WT-04
territory). The join is correct in intent — it adds product-level detail to each order. But
`raw_order_items` has multiple rows per `order_id` (one per line item), and the join is done
at the order level without aggregating first. Result: every order with more than one line item
is duplicated.

**Impact**: Revenue appears inflated. For the current period (Feb 2026), 847 multi-line-item
orders × average 1.8 line items = the model double-counts 718 additional rows. Total revenue
inflation: **~$127K** (41% of orders affected).

**The fix**: Aggregate `raw_order_items` to order grain before joining. This is a mechanical fix
with a clear rollback path. The agent can do this autonomously.

### Finding #2: Staleness — `fct_customer_metrics` Has Not Refreshed Since Thursday

**Root cause**: A cron job runs the dbt pipeline at 02:00 daily. Thursday's run completed but
the Friday/Saturday/Sunday runs all failed silently — the job reported success (exit code 0)
but dbt returned a compilation warning that caused the models to use cached results rather than
rerun. This is the "phantom success" pattern from WT-06.

**Evidence**: `_dbt_metadata.last_run_at` shows `2026-02-19 22:14:33` (Thursday). Today is
`2026-02-23 06:00`. Data is 84 hours stale.

**Impact**: Customer-facing dashboards show Thursday's cohort counts. Weekend signups (estimated
~180 new customers) are not reflected. No revenue impact — correctness impact on customer
product.

**The fix**: Diagnose the compilation warning, resolve it, trigger a backfill run. The agent
can do this autonomously (it's a configuration fix, not a data fix).

### Finding #3: PII Exposure — Email in Customer-Facing Mart

**Root cause**: `fct_customer_metrics` passes `customer_email` through from `stg_customers`
into the mart layer. This mart is used by ACME's customer-facing analytics product — meaning
customers' email addresses are queryable by other customers via the API.

**This is a compliance incident.** GDPR Article 5(1)(f) requires personal data be processed
in a manner that ensures appropriate security. Cross-customer email exposure violates this.
It also likely violates ACME's own privacy policy and customer contracts.

**The agent does not fix this autonomously.** Masking/removing the column is technically
trivial, but:
- The scope of the breach (how long has this been live, who queried it) must be established
- Legal and compliance teams need to assess notification obligations
- Customer communications may be required
- A human must sign off on any changes to production data affecting customer contracts

**The agent's job**: Build the escalation package. Document the finding, quantify the exposure
window, list affected customer accounts, and deliver it to the compliance owner.

### Finding #4: Metric Fragmentation — Revenue Defined Two Ways

**Root cause**: `fct_order_revenue` and `fct_revenue_summary` both claim to report ACME's
total revenue. They disagree by $80K for January 2026:
- `fct_order_revenue`: $1,423,500
- `fct_revenue_summary`: $1,343,500

Archaeology reveals the gap:
- `fct_revenue_summary` was built by Finance in Q3 2025 using a cash-basis definition
  (payment received date, net of refunds)
- `fct_order_revenue` was built by the data team and uses accrual basis
  (order created date, gross of refunds)
- $80K = refund liability in transit + accrual timing difference

**The fix**: The canonical definition for board reporting is accrual-basis gross revenue
(per CFO alignment established during WT-09). Document the divergence, mark `fct_revenue_summary`
as deprecated, add a comment explaining the $80K delta, and generate a test that asserts
both models agree within $5K for future months (which they will, once the accrual/cash timing
resolves within the month).

---

## Seed Data

**raw_orders.csv** — Order master (200 rows, Jan–Feb 2026)
- `order_id`, `customer_id`, `order_date`, `status`, `total_amount`

**raw_order_items.csv** — Line items (340 rows — some orders have 1 item, some have 2-3)
- `item_id`, `order_id`, `product_id`, `quantity`, `unit_price`, `line_total`
- NOTE: orders with multiple items cause the grain violation in the naive join

**raw_customers.csv** — Customer master (120 rows, includes PII)
- `customer_id`, `first_name`, `last_name`, `email`, `phone`, `signup_date`, `plan`, `country`
- NOTE: `email` should NEVER appear in mart-layer outputs

**raw_pipeline_runs.csv** — dbt run metadata (30 rows)
- `run_id`, `model_name`, `run_at`, `status`, `rows_affected`, `duration_seconds`
- NOTE: `fct_customer_metrics` shows no successful run since 2026-02-19

---

## Files

```
wt10_autonomous_agent/
├── README.md                    ← This file
├── dbt_project.yml
├── seeds/
│   ├── raw_orders.csv           ← Order master (200 rows)
│   ├── raw_order_items.csv      ← Line items with grain issue embedded (340 rows)
│   ├── raw_customers.csv        ← Customer master with PII (120 rows)
│   └── raw_pipeline_runs.csv    ← Run metadata showing staleness (30 rows)
├── models/
│   ├── staging/
│   │   ├── src_acme.yml
│   │   ├── stg_models.yml
│   │   ├── stg_orders.sql       ← Clean order records
│   │   ├── stg_order_items.sql  ← Line items with aggregation hint
│   │   └── stg_customers.sql    ← Customers with PII tagged
│   └── marts/
│       ├── fct_order_revenue.sql      ← BUG: grain violation (fan-out join)
│       ├── fct_customer_metrics.sql   ← BUG: stale + exposes email
│       ├── fct_revenue_summary.sql    ← BUG: cash-basis disagrees with accrual
│       └── fct_order_revenue_fixed.sql ← SOLUTION: correct grain
├── analyses/
│   └── 01_triage.sql            ← The agent's Monday morning sweep
└── tests/
    ├── assert_no_email_in_marts.sql   ← PII gate: email must not appear in marts
    └── assert_revenue_grain.sql       ← Each order_id appears exactly once
```

---

## The Triage Framework

The agent uses a 2×2 to decide autonomous vs. escalate:

```
                      CAN FIX WITH CERTAINTY?
                      Yes              No
                   ┌─────────────┬──────────────┐
HIGH business   Yes│  Fix + log  │  Escalate    │
impact?            │  (Finding 1)│  (Finding 3) │
                No ├─────────────┼──────────────┤
                   │  Fix + log  │  Monitor +   │
                   │  (Finding 4)│  alert       │
                   └─────────────┴──────────────┘

Finding #1 (grain violation): HIGH impact, agent CAN fix → autonomous fix
Finding #2 (staleness):       HIGH impact, agent CAN fix → autonomous fix
Finding #3 (PII exposure):    HIGH impact, agent CANNOT fix alone → escalate
Finding #4 (metric drift):    MEDIUM impact, agent CAN fix → autonomous fix
```

**Escalation rule**: Any finding that involves compliance, legal liability, customer
notification obligations, or requires a human authority to sign off → escalate, do not fix.

---

## Agent Lens: What Does Autonomous Operation Actually Look Like?

### The superhuman capability: simultaneous multi-class detection

A human DE arriving Monday morning does one of three things:
1. Checks the dashboard, sees nothing is on fire, starts sprint work
2. Gets paged about one specific issue and works that issue
3. Runs a manual ad-hoc query when someone complains

An agent running a proactive sweep does something categorically different:

**1. Full-stack instrumentation at 06:00**
The agent queries `information_schema`, pipeline metadata, mart outputs, and row counts
simultaneously. It isn't reacting — it's sampling the entire system state before anyone
shows up.

**2. Cross-class pattern matching**
A human investigating a grain violation doesn't simultaneously look for PII exposure.
An agent running structured checks finds both in the same pass. The triage document is
the first artifact, produced before any fix is attempted.

**3. Severity calibration without anchoring**
When a human finds an issue, they tend to treat it as the most important thing until it's
resolved (anchoring). An agent maintains a complete issue registry and prioritizes across
all findings simultaneously. Finding #3 (compliance) is escalated immediately, even though
Finding #1 (revenue inflation) feels more urgent to a human in the moment.

**4. Autonomous fix with audit trail**
For issues within its authority, the agent fixes, logs the fix with a diff, and adds a
regression test. The human arriving at 09:00 sees: "3 issues resolved, 1 escalated,
regression tests added for all 4." The Monday morning brief is generated, not written.

**5. The escalation package**
For finding #3, the agent doesn't just flag it — it builds the package:
- Exposure window (when did this column first appear in the mart?)
- Affected queries (which downstream jobs have read this mart?)
- Affected accounts (which customer IDs could have been exposed?)
- Suggested immediate actions (disable API endpoint, run audit query)
- Draft notification template

The compliance team receives a complete incident package, not a vague alert.

### The residual human role in WT-10

- **Compliance sign-off**: Only a human with legal/compliance authority can decide the
  breach scope, notification obligations, and remediation plan for finding #3
- **Audit confirmation**: The agent's autonomous fixes should be reviewed by a human
  before end of day — the Monday brief creates that review artifact
- **Escalation response**: The compliance owner decides whether finding #3 requires
  customer notification, regulator notification, or both

### What the data team does at 09:00

Without the agent:
- Spend 2-3 hours debugging Monday's data before realizing there were multiple issues
- Likely miss finding #3 entirely until a customer or auditor finds it
- Fix one thing at a time, in the order someone complained

With the agent:
- Review the Monday brief (5 minutes)
- Confirm the autonomous fixes look correct (10 minutes)
- Respond to the compliance escalation with context the agent couldn't have (the rest of the morning)
- Sprint work resumes by 10:00

**The compounding effect**: Every issue the agent fixes autonomously is an issue the team
never has to context-switch to. The team's cognitive load is bounded by the escalation queue,
not the full issue surface.

---

## Learning Objectives

By completing WT-10, you will have demonstrated:

1. **Multi-class detection**: A single agent sweep can surface correctness, staleness, compliance,
   and metrics issues simultaneously — not because it's running four separate checks, but because
   it's instrumenting the same underlying data from multiple angles.

2. **Triage as the primary artifact**: The triage document — not any individual fix — is the
   most important output of an autonomous sweep. It establishes priority order, scope, and
   disposition before any action is taken.

3. **Compliance as a hard escalation boundary**: The agent's authority has explicit limits.
   Finding #3 is technically easy to fix (drop a column) but organizationally impossible to
   resolve autonomously. Knowing this boundary — and acting on it correctly — is what makes
   autonomous operation trustworthy.

4. **The Monday morning brief as the human interface**: The brief is how autonomous operation
   becomes legible to humans. It surfaces what was found, what was fixed, what was escalated,
   and why. Without the brief, autonomous operation creates opacity; with it, it creates leverage.

5. **Regression as the enduring value**: Each autonomous fix ships with a test that encodes the
   invariant. The grain test, the PII gate, the metric alignment check — these don't just fix
   today's issue. They prevent next week's.

---

## The Pattern Across WT-01 Through WT-10

```
WT-01: Data You Inherit       → narrow tool misses everything; general agent finds everything
WT-02: Dashboard Is Wrong     → silent revenue error; continuous reconciliation catches it
WT-03: New Source Onboarding  → 80% template, 20% judgment (entity resolution)
WT-04: Schema Migration       → detection latency is the real cost, not fix time
WT-05: Slow Query             → grain violation; execute_python sufficient
WT-06: Data Stale             → phantom success; pipeline selector bug; duration anomaly
WT-07: PII Everywhere         → compliance class; different agent shape; legal handoff
WT-08: Duplicate Records      → semantic vs. structural uniqueness; external reconciliation
WT-09: Metrics Layer          → metric fragmentation; definition archaeology; canonical layer
WT-10: The Autonomous Agent   → all of the above, simultaneously, before anyone arrives

The progression: reactive → proactive → autonomous.
```

---

## Key Takeaway

Autonomous agent DE operation is not about replacing the data team. It is about changing
the team's relationship to the problem surface.

Without autonomy: the team is bounded by what they know is broken.
With autonomy: the team is bounded by what requires human judgment to resolve.

That is a fundamentally different — and far smaller — constraint.

The agent finds everything. The agent fixes what it can. The agent escalates what it cannot.
The human's job becomes making the decisions only humans can make.

That is what WT-10 demonstrates.
