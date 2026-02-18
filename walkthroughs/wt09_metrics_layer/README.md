# WT-09: Building the Metrics Layer

**Scenario**: "Three teams, three MRRs — none of them agree."

> The CEO just sent a message in Slack: *"Finance says MRR is $1.2M. Sales says it's $1.4M. Marketing says $1.1M. I'm presenting to the board in 2 hours. Someone tell me which number is right."*

## The Situation

ACME Analytics has grown fast. Three teams independently built their own revenue metrics over 18 months:

- **Finance** queries `fct_revenue_monthly` — built by the data team, uses invoiced amounts
- **Sales** queries `fct_arr_by_account` — built by a RevOps contractor, uses contracted ARR
- **Marketing** queries `fct_marketing_revenue` — built by the growth team, uses payment receipts

All three models query the same underlying source data. All three produce different numbers. Nobody knows which is "right" — or even what "right" means.

The real bug isn't a pipeline failure. It's **metric fragmentation**: three teams encoded three different business definitions into SQL, and none of those definitions were ever written down or agreed upon.

**Your job**: Trace each metric back to its assumptions, identify where they diverge, align with stakeholders on a canonical definition, and build a metrics layer that makes future disagreements impossible.

---

## Estimated Time: 60 min

| Phase | Time | What You're Doing |
|-------|------|-------------------|
| 1. Orient | 10 min | Map the three metrics — what does each actually compute? |
| 2. Diverge | 15 min | Find the 3-4 decision points where definitions split |
| 3. Align | 10 min | Propose canonical MRR definition, get stakeholder sign-off |
| 4. Build | 20 min | Implement unified metrics layer, deprecate the three orphans |
| 5. Verify | 5 min | Confirm board-ready number + regression tests |

---

## Background: The Three Metrics

### Finance: `fct_revenue_monthly`
Built by the original data team. Uses invoice creation date and invoiced amount. Includes:
- One-time setup fees
- Annual contracts prorated monthly
- Credits and adjustments (as negative rows)

### Sales (RevOps): `fct_arr_by_account`
Built by a RevOps contractor during a Salesforce integration project. Uses contract start/end dates and contract value. Includes:
- Only active (non-churned) contracts
- Expansion MRR when a customer upgrades mid-period
- **Excludes** pilot/trial contracts (tagged in Salesforce)

### Marketing (Growth team): `fct_marketing_revenue`
Built during a paid acquisition analysis. Uses payment received date and Stripe payment amounts. Includes:
- Cash-basis (payment date, not invoice date)
- Net of refunds
- **Includes** one-time professional services revenue

None of these are wrong — they're each answering a slightly different question. The problem is that the teams are using them interchangeably as if they're all answering "what is MRR?"

---

## Seed Data

**raw_contracts.csv** — Source of truth for contracted ARR
- `contract_id`, `account_id`, `start_date`, `end_date`, `annual_value`, `type` (recurring/pilot/one-time), `status` (active/churned/pending)

**raw_invoices.csv** — Finance/billing records
- `invoice_id`, `account_id`, `contract_id`, `invoice_date`, `amount`, `type` (subscription/setup/credit), `status` (paid/pending/void)

**raw_payments.csv** — Stripe payment receipts
- `payment_id`, `account_id`, `invoice_id`, `payment_date`, `amount`, `refunded` (boolean)

**raw_accounts.csv** — Account master
- `account_id`, `name`, `segment` (enterprise/mid-market/smb), `industry`, `sales_rep`, `created_at`

---

## The Bug: Divergent Metric Definitions

```
                         raw_contracts + raw_invoices + raw_payments
                                            │
                    ┌───────────────────────┼──────────────────────┐
                    ▼                       ▼                      ▼
          fct_revenue_monthly      fct_arr_by_account    fct_marketing_revenue
          (Finance)                (Sales/RevOps)        (Marketing/Growth)

          ┌─────────────────┐      ┌──────────────────┐  ┌───────────────────┐
          │ Invoice date     │      │ Contract date    │  │ Payment date      │
          │ Includes setup   │      │ Excludes pilots  │  │ Cash basis        │
          │ Includes credits │      │ Includes expand. │  │ Includes pro svc  │
          │ Prorated annual  │      │ Active only      │  │ Net of refunds    │
          └────────┬────────┘      └────────┬─────────┘  └─────────┬─────────┘
                   │                        │                       │
                  $1.2M                   $1.4M                  $1.1M

           Which is right? None. They're answering different questions.

           Canonical MRR = recurring subscription revenue recognized in period
                         = contracts WHERE type = 'recurring' AND status = 'active'
                           normalized to monthly, recognition date = invoice_date
                         = $1.26M  ← the board number
```

---

## Files

```
wt09_metrics_layer/
├── README.md                  ← This file
├── dbt_project.yml
├── seeds/
│   ├── raw_contracts.csv      ← Contract master (120 rows)
│   ├── raw_invoices.csv       ← Invoice records (480 rows, 18 months)
│   ├── raw_payments.csv       ← Stripe payments (460 rows)
│   └── raw_accounts.csv       ← Account master (85 rows)
├── models/
│   ├── staging/
│   │   ├── src_acme.yml
│   │   ├── stg_models.yml
│   │   ├── stg_contracts.sql  ← Clean contracts with type/status filters
│   │   ├── stg_invoices.sql   ← Invoices with type classification
│   │   └── stg_payments.sql   ← Payments net of refunds
│   └── marts/
│       ├── fct_revenue_monthly.sql     ← Finance version (has bugs)
│       ├── fct_arr_by_account.sql      ← Sales version (has bugs)
│       ├── fct_marketing_revenue.sql   ← Marketing version (has bugs)
│       └── fct_mrr_canonical.sql       ← SOLUTION: unified metrics layer
├── analyses/
│   ├── 01_investigation.sql   ← Map the three metrics, find divergence points
│   ├── 02_alignment.sql       ← Canonical definition queries
│   ├── 03_solution.sql        ← Build and validate fct_mrr_canonical
│   ├── 04_verification.sql    ← Regression + board number confirmation
│   └── 05_postmortem.md       ← What went wrong, how metrics layers prevent this
└── tests/
    ├── assert_mrr_no_pilots.sql        ← Canonical MRR never includes pilot contracts
    ├── assert_mrr_no_one_time.sql      ← No setup fees / professional services
    └── assert_mrr_matches_finance.sql  ← Finance agrees with canonical (post-fix)
```

---

## Investigation Guide

### Phase 1: Orient (10 min)
Pull all three metrics for the current month. Don't try to reconcile yet — just understand what each is computing.

```sql
-- See analyses/01_investigation.sql
-- Key questions:
--   What date field does each model use?
--   What revenue types are included/excluded?
--   What's the count of accounts in each?
```

### Phase 2: Find the Divergence Points (15 min)
Three decision points drive all the divergence:

1. **Date basis**: Invoice date vs. contract date vs. payment date
2. **Revenue type**: Recurring only vs. all revenue vs. cash receipts
3. **Contract status**: Active only vs. all non-void vs. all payments

```sql
-- See analyses/01_investigation.sql
-- Walk through each divergence point
-- Quantify the dollar impact of each decision
```

### Phase 3: Align on Canonical Definition (10 min)
For SaaS MRR reporting to a board, the standard is:
- **Recognition basis**: Invoice date (accrual, not cash)
- **Type**: Recurring subscription only (no setup, no pro services)
- **Status**: Active contracts only (no pilots, no churned)
- **Normalization**: Annual contracts ÷ 12

Get sign-off from Finance (they own the definition for board reporting).

### Phase 4: Build the Metrics Layer (20 min)
Build `fct_mrr_canonical` that:
1. Uses the agreed canonical definition
2. Has columns that make the definition explicit (`is_recurring`, `recognition_month`, `is_pilot`)
3. Deprecates the three divergent models with a `-- DEPRECATED: use fct_mrr_canonical` comment
4. Adds metric-level documentation to schema YAML

```sql
-- See analyses/03_solution.sql
```

### Phase 5: Verify (5 min)
```sql
-- See analyses/04_verification.sql
-- Confirm: fct_mrr_canonical for current month = $1,260,000
-- Confirm: three tests pass
-- Confirm: Finance model now agrees (after their cleanup)
```

---

## Solution

The canonical MRR definition:
```sql
-- fct_mrr_canonical.sql (simplified)
SELECT
    date_trunc('month', i.invoice_date) AS revenue_month,
    c.account_id,
    a.segment,
    SUM(
        CASE
            WHEN c.type = 'recurring' AND c.status = 'active'
            THEN i.amount
            ELSE 0
        END
    ) AS mrr
FROM stg_invoices i
JOIN stg_contracts c ON i.contract_id = c.contract_id
JOIN stg_accounts a ON c.account_id = a.account_id
WHERE i.type = 'subscription'  -- no setup fees, no credits
  AND i.status = 'paid'        -- no pending/void
  AND c.type = 'recurring'     -- no pilots, no one-time
  AND c.status = 'active'      -- no churned
GROUP BY 1, 2, 3
```

Board number: **$1,260,000 MRR** for current month.

---

## Agent Lens: What Does an Agent Do That a Human Struggles to Do?

### The superhuman move: systematic definition archaeology

When a human DE encounters three conflicting MRR numbers, they typically:
1. Pick the model they trust most (usually the one they built)
2. Manually reconcile the obvious differences
3. Produce a number and move on

An agent does something different:

**1. Complete divergence enumeration**
The agent doesn't pick a favorite. It systematically diffs every column, every filter, every join across all three models simultaneously. It finds *all* decision points, not just the obvious ones. The dollar impact of each divergence is quantified automatically.

**2. Definition archaeology**
The agent traces each decision back to git history (when was this added?), comments, and ticket references. It can say: "The pilot exclusion in `fct_arr_by_account` was added in commit `a3f2b1` by the RevOps contractor with the comment 'per Mike's request' — but there's no ticket and Mike left 6 months ago."

**3. Stakeholder mapping without politics**
The agent identifies who uses each metric (by querying BI tool usage logs, Slack mentions, dashboard refs) without caring about org politics. It can say: "Finance queries `fct_revenue_monthly` 847 times/month. Sales queries `fct_arr_by_account` 23 times/month. Marketing hasn't queried `fct_marketing_revenue` in 90 days." This changes the negotiation.

**4. Canonical definition proposal with precedent**
The agent has read every SaaS metrics framework (OpenMRR, Stripe's definitions, SaaStr standards). It proposes a canonical definition with a citation: "Per OpenMRR v2, MRR should be [X]. Your Finance model is closest. Here's what needs to change to make it fully compliant."

**5. Test generation for the new contract**
Once the definition is agreed, the agent immediately generates tests that *encode the business rule*: `assert_mrr_no_pilots`, `assert_mrr_recognition_basis`, `assert_mrr_no_setup_fees`. These aren't schema tests — they're *definition contracts* that will catch any future drift.

### The residual human role

- **Business judgment call**: "Should expansion MRR be in the canonical number?" — This is a board/CFO decision, not a technical one.
- **Stakeholder alignment**: Getting Finance, Sales, and Marketing to agree on a definition requires negotiation that depends on org dynamics and history the agent doesn't have.
- **Definition sign-off**: The agent proposes; a human with authority signs off.

### The product insight

The metrics layer problem is the highest-leverage agent use case in data engineering. Every company has this problem. The agent can:

1. **Audit existing metrics** in hours (what every metric is, how it's computed, who uses it)
2. **Flag divergence** automatically ("MRR is defined 3 ways across 7 models")
3. **Propose canonicalization** with industry precedent
4. **Build the layer** once definitions are agreed
5. **Enforce it** with tests that encode the business contract

This is work that currently takes a senior DE 2-4 weeks of politically careful work. An agent does the technical parts in an hour and reduces the human's job to signing off on a proposal.

**The form factor**: The agent drives an investigation in real time, surfaces findings, proposes the canonical definition, and waits for a single "ship it" before building. The human never writes SQL — they just make the one business decision the agent can't make alone.

---

## Key Takeaway

Metrics fragmentation is a governance problem masquerading as a technical problem. The technical fix (unified metrics layer) is straightforward. The hard part is:

1. Finding all the divergent definitions (agent excels here)
2. Understanding why they diverged (agent excels here)
3. Agreeing on what's canonical (human required here)
4. Enforcing the canonical definition going forward (agent excels here)

An agent dramatically compresses steps 1, 2, and 4 — leaving the human to focus on the one step only humans can do.
