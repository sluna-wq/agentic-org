# WT-09: Building the Metrics Layer

**Scenario**: "Building the Metrics Layer" — The CFO wants a single source of truth for revenue. Three teams each query the warehouse differently and get different numbers. The hidden problem: their definitions are semantically incompatible.

**The key learning**: Metrics layers fail on semantic conflict, not infrastructure. An agent can auto-detect that "revenue" means three different things across teams, map each to its SQL root cause, and surface exactly the decisions a human must make. The build is template work; the value is conflict detection and facilitation.

**Estimated Time**: ~50 min

| Phase | Time | What You're Doing |
|-------|------|-------------------|
| 1. Reproduce | 10 min | Run all three team definitions, confirm the three different totals |
| 2. Map to SQL | 10 min | Trace each total back to its WHERE clause / date field / JOIN |
| 3. Detect conflicts | 10 min | Name the three conflicts and quantify the dollar impact of each |
| 4. Surface decisions | 5 min | Document the three choices the CFO must make |
| 5. Build canonical | 15 min | Implement the unified metrics layer after decisions are locked |

---

## The Ticket

> **From**: Sarah Chen, CFO
> **To**: Data Team
> **Subject**: Revenue numbers don't match — board presentation tomorrow
>
> I'm preparing for the board presentation tomorrow and I'm getting three different numbers for monthly revenue from January 2026:
>
> - **Sales (Liam)**: $1.2M
> - **Finance (me / Priya)**: $980K
> - **Product (Dev team)**: $1.05M
>
> I need ONE number. I don't care which methodology we pick as long as we all agree on it and it's defensible. The board will ask follow-up questions and we can't have Sales and Finance contradicting each other in the same room.
>
> Please figure out why the numbers are different, tell me what I need to decide, and build something that makes this impossible next quarter.
>
> — Sarah

This is a real CFO email. Some version of it gets sent at every company that has grown past ~20 employees without a shared semantic layer. The numbers aren't wrong. Each team is correct by their own logic. The problem is that three analysts independently encoded three different business definitions into SQL and nobody wrote down what "revenue" means.

---

## Setup

```bash
cd walkthroughs/wt09_metrics_layer
dbt seed
dbt run
dbt test
```

Note: `dbt test` will pass. That is the point — standard schema tests do not catch semantic conflicts. There are no broken pipelines here, no null primary keys, no referential integrity failures. The data is clean. The problem is in the definitions.

---

## The Situation

### Three Teams, Three Dashboards, Three Numbers

ACME Analytics has three business teams who each built their own revenue reporting:

**Sales team** — Built by Liam (RevOps) during a Salesforce integration project 14 months ago. Queries the warehouse directly from Tableau. Uses the order's creation date because sales reps are measured on deals closed (created). Counts only 'completed' orders because that is what Salesforce marks as "Won." The dashboard was built when all customers were US-based; currency conversion was never added.

**Finance team** — Built by Priya (Senior Analyst) in coordination with the original data team. Built for the monthly P&L close. Uses recognized_at because Finance runs on accrual accounting and the ERP sets recognized_at when an invoice is approved. Includes both 'completed' and 'invoiced' orders because an approved invoice is accounts receivable — Finance recognizes that revenue even before cash arrives. Uses face-value USD because the ERP books foreign currency transactions at face value and handles FX gains/losses as a separate line item.

**Product team** — Built by Dev (Data Analyst, Product) to measure "successful purchase events." Uses paid_at because a completed checkout is the product event they care about. FX-converts to USD because Dev correctly noted that a GBP order for 6,200 GBP is not "$6,200" — at 1.27 rate it is $7,874. Excludes 'invoiced' orders because from a product perspective an unpaid invoice is not a successful checkout.

All three query the same underlying data. All three produce different numbers. None of them are wrong — they are each answering a slightly different question. The crisis is that they are all calling their answer "monthly revenue" and using it interchangeably in executive communications.

### What Makes This Hard

- There is no broken pipeline to fix. dbt tests pass.
- Each team's definition is internally consistent and defensible.
- The gap between definitions is not visible until you put all three in the same query.
- The root cause requires understanding both SQL and business context (accrual accounting, FX treatment) — it's not a pure engineering problem.
- Resolving it requires organizational alignment, not just a schema change. Engineering cannot unilaterally pick the canonical definition.

---

## Files

| File | Purpose |
|------|---------|
| `seeds/raw_orders.csv` | 28 orders across Jan 2026 and adjacent months, multiple currencies and statuses |
| `seeds/raw_fx_rates.csv` | GBP and EUR to USD spot rates, Jan–Feb 2026 |
| `models/staging/stg_orders.sql` | Light cleaning, preserves all three date fields |
| `models/staging/schema.yml` | Column docs — the three date fields' semantic differences documented |
| `models/marts/fct_orders.sql` | Fact table with FX conversion, all three date fields, boolean revenue flags |
| `models/marts/metrics_conflicted.yml` | Bug artifact: three conflicting metric definitions from three teams |
| `models/marts/metrics_canonical.yml` | Solution: CFO-approved canonical definition with rationale |
| `analyses/01_detect_conflicts.sql` | Run three definitions side by side, reproduce the three different totals |
| `analyses/02_trace_conflicts.sql` | Order-by-order breakdown of which orders cause each gap |
| `analyses/03_canonical_metrics.sql` | Canonical query after decisions are locked |
| `tests/assert_no_revenue_without_date.sql` | CI gate: no recognized revenue without a recognized_at date |

---

## Investigation Path

### Phase 1: Reproduce the Discrepancy (10 min)

Before trying to solve anything, run all three definitions against the same data and confirm you can reproduce the three different totals. This is a sanity check: if you cannot reproduce the discrepancy analytically, you do not understand the problem yet.

Run `analyses/01_detect_conflicts.sql`. You will get a result set with three rows, one per team, showing:
- Which status values are included
- Which date field is used for the month filter
- How currency is handled
- The order count
- The total revenue

Expected output for January 2026:

```
team     | status_filter         | date_field    | currency_method         | orders | total_revenue_usd
---------|----------------------|---------------|-------------------------|--------|------------------
finance  | completed + invoiced | recognized_at | USD face value (no FX)  |   11   |   $246,800
product  | completed (paid)     | paid_at       | FX-converted            |    9   |   $148,450
sales    | completed only       | created_at    | USD face value (no FX)  |   10   |   $143,200
```

If your numbers match approximately, you have reproduced the discrepancy. Proceed to Phase 2.

Note: The exact totals depend on which orders fall within each date window. The important observation is:
- Finance reports nearly 2x what Sales reports. This is not rounding — there is a structural gap.
- Product and Sales report similar numbers but not identical, even though they both only count 'completed' orders.

### Phase 2: Map to SQL Roots (10 min)

Now read `models/marts/fct_orders.sql`. Look at the boolean flag columns:
- `is_sales_revenue` — reflects the Sales definition filter
- `is_finance_revenue` — reflects the Finance definition filter
- `is_product_revenue` — reflects the Product definition filter

Each flag encodes exactly one team's status filter logic. The difference between the flags is the SQL root cause of Conflict #1.

Then look at the three date columns: `created_at`, `paid_at`, `recognized_at`. Read `models/staging/schema.yml` for the description of each. The choice of which column to use in `date_trunc('month', ?)` is the SQL root cause of Conflict #2.

Finally look at the two amount columns: `amount_usd_face` (no FX conversion) and `amount_usd_converted` (FX spot rate applied). The choice between these is the SQL root cause of Conflict #3.

You can now state each conflict as a specific SQL decision:

```
Conflict #1 (Status): WHERE status = 'completed'
                  vs. WHERE status IN ('completed', 'invoiced')

Conflict #2 (Date):   date_trunc('month', created_at) = target_month
                  vs. date_trunc('month', paid_at) = target_month
                  vs. date_trunc('month', recognized_at) = target_month

Conflict #3 (FX):     SUM(amount_usd_face)        -- face value, no conversion
                  vs. SUM(amount_usd_converted)    -- spot rate at transaction date
```

### Phase 3: Detect the Conflicts (10 min)

Run `analyses/02_trace_conflicts.sql`. This breaks down the delta between definitions order by order. The output shows three conflict buckets:

**Conflict #1 — Status filter**
Orders that Finance includes but Sales excludes. These are all `status = 'invoiced'` orders with a valid `recognized_at` in January 2026. You will see orders like ORD-003, ORD-007, ORD-012, ORD-016, ORD-020 — each is an invoice sent in January but not yet paid. Finance recognizes this revenue in January. Sales doesn't see these at all.

Dollar impact: The invoiced orders in January total approximately $85,800 in face-value USD. This accounts for most of the Finance vs. Sales gap.

**Conflict #2 — Date field shift**
Orders that fall in different months depending on which date field you use. These are "boundary orders" — created in December but paid or recognized in January (e.g., ORD-026, ORD-027), or created in January but recognized in February (e.g., ORD-025). These orders cross month boundaries.

Dollar impact: Smaller than Conflict #1 but material for month-end close. Orders crossing the Dec/Jan boundary affect both months' totals simultaneously — January is overstated in Sales (because created_at is in January for some orders paid in February) and understated in Finance (because recognized_at falls in February).

**Conflict #3 — FX conversion**
Non-USD orders where the face value differs from the FX-converted USD amount. For January 2026, GBP is trading at approximately 1.27–1.30 USD/GBP, so a 6,200 GBP order has a face value of "$6,200" (as Sales and Finance report it) but a converted value of approximately $7,900 (as Product reports it). EUR orders have a smaller gap since EUR is near parity with USD.

Dollar impact: For the January dataset with 5 non-USD orders (3 GBP, 2 EUR), the FX conversion adds approximately $5,250 to Product's total vs. face value. This is the Product vs. Sales gap.

### Phase 4: Surface the Decisions (5 min)

The work so far was detective work. Phase 4 is about facilitation. You now know exactly what the CFO needs to decide. Your job is to format those three decisions as a clear escalation — not a technical ticket, but a business decision memo.

The three decisions are:

**Decision 1 — Status filter**

> Should monthly revenue include orders that have been invoiced but not yet paid?
>
> - YES (Finance approach): Revenue is recognized when the invoice is approved (accrual basis). An approved invoice is an asset — the company is owed that money and GAAP permits recognizing it as earned.
> - NO (Sales approach): Revenue requires a completed transaction. An unpaid invoice is not revenue — it is a receivable.
>
> Dollar impact: ~$85,800 for January 2026.
> Recommended: YES (accrual basis). Standard for board reporting. Finance and auditors will require this.

**Decision 2 — Date field**

> When does revenue "happen" for monthly reporting purposes?
>
> - Deal date (created_at): When Sales closes the deal. Good for sales team performance metrics.
> - Payment date (paid_at): When cash arrives. Good for cash flow reporting.
> - Recognition date (recognized_at): When the obligation is fulfilled under accounting standards. Required for GAAP/IFRS reporting.
>
> Dollar impact: Affects which orders land in which month (boundary orders). For consistent monthly close and board reporting, exactly one date must be chosen.
> Recommended: recognized_at. This is the only GAAP-correct basis for the board number.

**Decision 3 — Currency handling**

> Should non-USD orders be converted to USD at the spot rate, or reported at face value?
>
> - Face value (Sales/Finance current approach): Report GBP and EUR amounts as if they were USD. Simple, no FX rate dependency. Acceptable when non-USD revenue is immaterial (<2% of total).
> - FX-converted (Product approach): Convert at the spot rate on the transaction date. Correct when non-USD revenue is material.
>
> Dollar impact: ~$5,250 for January 2026 (non-USD orders are ~15% of volume and growing).
> Recommended: FX-converted. At 15% non-USD volume, face value treatment materially misrepresents USD revenue. Use the rate on recognized_at for consistency with Decision 2.

These three decisions go to the CFO. Not to engineering, not to the data team. The data team's job is to present the decisions with full information and let the CFO choose. Engineering cannot make a semantic decision — they can only implement one once it is made.

### Phase 5: Build the Canonical Metrics Layer (15 min)

Once the CFO signs off, the build is straightforward. Read `models/marts/metrics_canonical.yml` for the canonical definition. The CFO chose:
- Decision 1: completed + invoiced (accrual)
- Decision 2: recognized_at
- Decision 3: FX-converted at spot rate on recognized_at

Run `analyses/03_canonical_metrics.sql` to validate the canonical total.

The canonical metric is already implemented in `fct_orders.sql` via `is_revenue_recognized` and `amount_usd_converted`. The `metrics_canonical.yml` file encodes the business definition in the metrics layer so it is version-controlled and visible to all downstream tools.

To complete the transition:
1. Add deprecation comments to the three team-specific dashboards pointing to the canonical metric.
2. Add `tests/assert_no_revenue_without_date.sql` to the CI pipeline.
3. Schedule a 30-min sync with each team lead to walk through the new definition and explain the delta from their old number.

---

## Solution

### Canonical Definitions (CFO-Approved 2026-01-31)

| Dimension | Chosen Approach | Rationale |
|-----------|----------------|-----------|
| Status filter | completed + invoiced | Accrual basis; GAAP-required for board reporting |
| Date field | recognized_at | GAAP recognition date; only defensible basis for P&L |
| Currency | FX-converted at recognized_at spot rate | Non-USD at 15% of volume; face value now material |

### Canonical Metrics YAML

See `models/marts/metrics_canonical.yml` for the full implementation. The core metric:

```yaml
- name: monthly_revenue
  label: Monthly Revenue (Canonical)
  model: ref('fct_orders')
  calculation_method: sum
  expression: amount_usd_converted
  timestamp: recognized_at
  time_grains: [month, quarter, year]
  filters:
    - field: is_revenue_recognized
      operator: '='
      value: "true"
    - field: recognized_at
      operator: 'is not'
      value: "null"
```

### Canonical SQL (from analyses/03_canonical_metrics.sql)

```sql
select
    date_trunc('month', recognized_at)  as revenue_month,
    count(*)                            as order_count,
    round(sum(amount_usd_converted), 2) as total_revenue_usd
from fct_orders
where
    is_revenue_recognized = true
    and recognized_at is not null
    and date_trunc('month', recognized_at) = '2026-01-01'
group by 1
```

---

## Verification

Run these queries in order to confirm the solution is correct:

**Step 1 — Canonical total is between Finance and Sales+Product combined:**
The canonical total should be higher than Sales (because it adds invoiced orders) and the FX conversion should shift it slightly vs. Finance. If the canonical total is $0 or equal to Sales' total, the filter is broken.

**Step 2 — The is_revenue_recognized flag is consistent:**
```sql
select status, is_revenue_recognized, count(*), sum(amount_usd_converted)
from fct_orders
group by 1, 2
order by 1, 2
```
Expected: pending and refunded orders have `is_revenue_recognized = false`. Completed and invoiced with a non-null recognized_at have `is_revenue_recognized = true`.

**Step 3 — FX orders convert correctly:**
```sql
select order_id, currency, amount_local, amount_usd_converted, fx_conversion_date
from fct_orders
where currency != 'USD'
order by order_id
```
Expected: all non-USD orders have a non-null `amount_usd_converted` that is clearly different from `amount_local` (GBP amounts should be ~1.27x larger in USD).

**Step 4 — Test passes:**
```bash
dbt test --select assert_no_revenue_without_date
```
Expected: zero rows returned (test passes). Any row returned means an order has `is_revenue_recognized = true` but a null `recognized_at` — that order would silently drop from monthly revenue queries.

**Step 5 — Reconciliation (confirm the delta makes sense):**
The gap between the canonical total and the old Sales total should be approximately equal to the sum of Conflict #1 + Conflict #3 impacts from `02_trace_conflicts.sql`. If the gap is significantly larger or smaller, there is an unexpected filtering issue.

---

## Postmortem

### Why Did This Happen?

**Siloed analysts without a shared semantic layer.** Three analysts each built a dashboard for their team's use case. None of them were wrong. Each was solving the right problem for their audience:
- Sales wants to know: "How much business did we close this month?" → created_at + completed
- Finance wants to know: "What revenue did we recognize this month?" → recognized_at + accrual
- Product wants to know: "How much did customers spend on purchases this month?" → paid_at + completed + FX

The problem is not that three definitions exist — it is that none of them were documented, no single definition was designated canonical, and all three were presented to executives as "monthly revenue" without qualification.

**Pressure to report wins.** When every team wants to show their number in a positive light, the incentive is to use the definition that maximizes the metric for your context. Sales uses created_at because attribution to the sales team is clearest. Product uses paid_at and FX conversion because it shows the highest absolute number for their international user base. Finance uses accrual because that's what GAAP requires. Nobody is gaming the number — but the effect is that "monthly revenue" means three different things.

**No owner of the business definition.** Engineering owns the pipeline. Analytics owns the models. But nobody owns the definition. The CFO is the implicit owner of revenue definitions but was never asked to weigh in until the board presentation forced the issue.

**What Should Have Happened**

At the first sign of a new team needing a revenue metric, the data team should have:
1. Written down the existing canonical definition (or created one if none existed)
2. Reviewed the new team's requirements against the canonical definition
3. If the new team's requirements diverged, escalated to Finance/CFO to adjudicate
4. Documented the decision — is this a new metric (e.g., "cash collections") or a modification of the canonical?

The semantic layer forces this discipline by making definitions explicit and version-controlled. Without it, each new dashboard is an opportunity for definitional drift.

### Prevention

1. **Define before building**: Before any new revenue metric is built, the definition must be reviewed against the canonical definition in `metrics_canonical.yml`.
2. **Naming discipline**: "Revenue" without qualification means the canonical metric. Any variant must be explicitly named: `revenue_cash_basis`, `revenue_sales_attribution`, `revenue_recognized`.
3. **The CI test as guardrail**: `tests/assert_no_revenue_without_date.sql` catches the most common class of data quality issue that causes silent revenue loss.
4. **Quarterly metrics review**: Every quarter, query the BI tool usage logs to find dashboards using revenue metrics that are not pointing to `metrics_canonical`. Reach out to the owners.

---

## Agent Lens

This is the most important section of the walkthrough. The scenario above reads like a project a senior data engineer handles in a few days of focused work. An agent does the same work in one session — and does some parts of it better than a human would. Understanding the difference matters for designing agent workflows.

### The Detective Work: What an Agent Does That Humans Struggle With

**1. Complete divergence enumeration, not selective sampling**

When a human data engineer is told "three teams have different revenue numbers," they typically:
- Pull the most recently updated model they trust
- Manually check a few obvious differences (status filter, maybe date field)
- Produce a reconciliation that explains most but not all of the gap
- Declare victory when the gap closes to something "within rounding"

An agent does something structurally different: it performs a *complete* enumeration of all possible divergence dimensions before forming any hypothesis. It does not start with a favorite. It asks: "For every Boolean or categorical column in this table, does each team's definition make a different choice? For every date column, does each team use the same one? For every numeric column, does each team apply the same transformation?"

This is the `01_detect_conflicts.sql` approach: enumerate all team definitions in parallel first, then compare. A human who trusts the Finance model skips the enumeration step and goes straight to reconciliation, potentially missing Conflict #3 (FX) entirely because it's small relative to Conflict #1 (status).

**2. Mapping from "three different numbers" to "three SQL root causes"**

The agent's conflict detection algorithm is:

```
For each team definition T:
  1. Extract the filter predicates (WHERE clauses)
  2. Extract the date field used for grouping
  3. Extract the aggregation expression (SUM of which column?)
  4. Extract any JOIN conditions that may affect row count (fan-out or filtering)

For each pair of team definitions (T1, T2):
  5. Diff the predicates: which rows are in T1 but not T2?
  6. Diff the date field: which orders land in different months under T1 vs T2?
  7. Diff the aggregation: for the same set of rows, does T1 produce a different number than T2?

For each divergence found:
  8. Quantify the dollar impact: how much revenue shifts between teams' totals due to this divergence?
  9. Identify the SQL line that encodes each divergence
  10. Map the SQL decision to a business question that must be answered
```

This algorithm runs in `01_detect_conflicts.sql` and `02_trace_conflicts.sql`. It is mechanical once you know to do it. The human equivalent is running each model, exporting to a spreadsheet, doing a VLOOKUP, and manually inspecting rows. The agent does the same conceptual work without the spreadsheet detour.

**3. Quantifying the dollar impact of each decision before asking the human**

When the agent surfaces the three decisions to the CFO, it does not say "there are some differences in how the teams define revenue." It says:

> Decision 1 (Status filter): If you include invoiced orders (Finance approach), January 2026 revenue increases by approximately $85,800 vs. the Sales definition. This affects 5 orders.
>
> Decision 2 (Date field): If you use recognized_at instead of created_at, 3 orders shift from December 2025 to January 2026, adding $38,500 to January. 1 order shifts from January to February 2026, removing $7,500 from January.
>
> Decision 3 (FX): If you apply spot-rate FX conversion to non-USD orders, January 2026 revenue increases by approximately $5,250 vs. face value.

The CFO can now make three informed decisions with full knowledge of the financial stakes of each. A human analyst producing this same memo would take 2–4 hours; the agent produces it in the time it takes to execute `02_trace_conflicts.sql`.

**4. Surfacing the decision owner, not just the decision**

The agent does not just identify that three decisions need to be made — it identifies *who must make them*. This is a non-trivial inference:

- The status filter decision (Conflict #1) is a GAAP vs. cash-basis accounting decision. Owner: CFO/Finance. Not data team, not Sales.
- The date field decision (Conflict #2) is a revenue recognition policy decision. Owner: CFO in consultation with external auditors if the company is audited.
- The FX decision (Conflict #3) is a financial reporting policy decision. Owner: CFO in consultation with Treasury.

An agent that surfaces these decisions to the wrong stakeholder adds friction. If it escalates the FX decision to Engineering, Engineering will implement the "technically cleaner" solution without understanding the accounting implications. The agent should say: "These three decisions require CFO sign-off. Here is the structured memo for that conversation."

**5. Template generation: the build is the easy part**

Once decisions are made, generating the canonical metrics YAML, the canonical SQL, and the CI tests is template work. The agent can generate all of `metrics_canonical.yml`, `03_canonical_metrics.sql`, and `tests/assert_no_revenue_without_date.sql` in seconds given the decisions. There is nothing creative about it — it is applying the decisions to a standard dbt metrics template.

This is the key asymmetry between human and agent effort in metrics work:
- Human: 80% of effort is on the build (writing SQL, YAML, documentation)
- Agent: 80% of value is in the investigation (conflict detection, decision facilitation)

For the agent, the build is instantaneous. For the human, the investigation is the bottleneck because it is tedious to enumerate all divergences systematically.

### The Conflict Detection Algorithm in Detail

Here is a more precise specification of the algorithm the agent runs mentally when given "three teams have different revenue numbers":

```
INPUT: N metric definitions that are supposed to measure the same thing
OUTPUT: A structured conflict report with:
  - K distinct conflicts (where K is the number of dimensions where definitions diverge)
  - For each conflict: which teams are affected, the SQL root cause, the dollar impact

ALGORITHM:
1. PARSE each definition into a normalized form:
   {
     status_filter: list of included status values,
     date_field: which timestamp column used for period assignment,
     aggregation: which column is summed (and what transformation if any),
     join_conditions: any joins that filter or multiply rows
   }

2. ENUMERATE dimensions to compare:
   [status_filter, date_field, aggregation, join_conditions]

3. For each dimension D:
   a. Check if all N definitions make the same choice for D
   b. If yes: no conflict on D, move to next dimension
   c. If no: record a conflict:
      - Which teams make which choice
      - What SQL encodes each choice
      - Run a query that isolates rows where this dimension causes divergence
      - Compute dollar impact of each choice vs. a reference definition

4. For each conflict found:
   a. Map the SQL choice to the business question it answers
   b. Identify the appropriate decision maker (not just "someone needs to decide")
   c. Format the decision as a binary or multiple-choice with dollar impacts

5. OUTPUT: Ordered by dollar impact (highest impact conflict first)
```

The three conflicts in this walkthrough map to this algorithm:

| Dimension | Sales choice | Finance choice | Product choice | Conflict? |
|-----------|-------------|----------------|----------------|-----------|
| status_filter | ['completed'] | ['completed','invoiced'] | ['completed'] | YES → Conflict #1 |
| date_field | created_at | recognized_at | paid_at | YES → Conflict #2 |
| aggregation column | amount_usd_face | amount_usd_face | amount_usd_converted | YES → Conflict #3 |
| join conditions | none | none | join to fx_rates | YES (same as #3) |

Step 3 of the algorithm produces `02_trace_conflicts.sql`. Step 4 produces the "three decisions" section of the CFO memo.

### What Decisions Must Go to Humans?

The agent can detect conflicts, quantify impacts, identify decision owners, and implement any choice once made. The one thing it cannot do is make the semantic choices. Here is why each decision requires a human:

**Decision 1 (Status filter) — semantic authority over accounting policy**

Whether to use cash basis or accrual basis for revenue recognition is not a technical question. It depends on:
- Whether the company is audited (audited companies must use GAAP/IFRS accrual for financial statements)
- Whether the metric is for internal management or external reporting (board vs. operations may use different bases)
- Whether accounts receivable aging affects the decision (if DSO is high and bad debt is material, accrued revenue may overstate expected collections)

An agent does not know these facts without being told. Even if it did, the sign-off on an accounting policy decision must come from a human with legal/fiduciary authority. This is not a capability gap — it is an authority gap.

**Decision 2 (Date field) — semantic authority over period definition**

Choosing between created_at, paid_at, and recognized_at is a decision about what "monthly revenue" means for the business. This is a definitional choice that determines how the company's performance story is told. A month with a lot of deals signed but few recognized is a strong sales month (Sales number is high) but a weak recognized revenue month (Finance number is low). These tell different stories to the board about company health. The CFO must choose which story the board hears — and be prepared to answer follow-up questions.

**Decision 3 (FX handling) — semantic authority over reporting currency conventions**

FX treatment affects how international growth is represented. If ACME's UK business is growing faster than the US business, face-value USD treatment hides that growth (because GBP is valued at face, not at the $1.27+ rate). FX-converted treatment correctly shows the USD value of UK revenue. But it also introduces FX volatility into the revenue line — a weakening GBP reduces reported revenue even if UK order volume is flat. The CFO must decide whether to show "FX-impacted revenue" (the economically accurate number) or "constant-currency equivalent" (a different metric) or to show both. This is a sophisticated financial reporting decision.

In all three cases, the agent's role is to surface the decision with full information. The human's role is to make the call. This is semantic authority — the irreducible human role in metrics work.

### The Residual Human Role: Semantic Authority

The core insight of this walkthrough is that the hard part of building a metrics layer is not the engineering — it is establishing semantic authority.

Semantic authority means: the power to say definitively what a word means for the purposes of business reporting. "Revenue," "monthly," "customer," "active user" — these words have precise technical meanings in the database and vague shared meanings in the business. The metrics layer is the system that bridges them. But someone must decide what the bridge looks like.

An agent dramatically accelerates the technical preparation for semantic decisions:
- It detects that the word "revenue" is used in three incompatible ways across the codebase
- It maps each usage to a specific SQL expression
- It quantifies the financial stakes of each interpretation
- It generates the candidate canonical definition based on industry standards
- It implements the chosen definition once authority is exercised

But the agent cannot exercise authority it doesn't have. A CFO who says "use Finance's definition" is exercising semantic authority. The agent implements the instruction. Without that exercise of authority, the agent cannot resolve the conflict — it can only document it.

This is a fundamentally different failure mode than a typical data pipeline failure. A broken JOIN, a null primary key, a stale partition — these are fixable by an engineer with sufficient access and knowledge. A semantic conflict is not fixable by anyone without authority over the business definition. An agent that attempts to resolve a semantic conflict by picking one definition unilaterally creates liability (what if it picks wrong?) and undermines trust (the other teams will continue using their definitions and the conflict persists).

The correct agent behavior in this scenario:
1. Detect and document all conflicts systematically
2. Quantify the financial stakes of each conflict
3. Identify the decision owner for each conflict
4. Format a decision memo and wait
5. When decisions come back: implement, document, add tests, notify stakeholders

Steps 1, 2, 3, and 5 are agent-native. Step 4 (wait) is the acknowledgment that semantic authority cannot be automated. Step 3 (identify the decision owner) is the highest-leverage action the agent takes — routing to the wrong decision maker delays resolution by days or weeks.

### Product Design Implications

For teams building AI-powered data tooling, this walkthrough surfaces several design requirements:

**1. Conflict detection should be proactive, not reactive.** An agent embedded in the dbt workflow should automatically flag when a new metric definition conflicts with an existing one. The alert fires at PR time, not at board presentation time.

**2. Impact quantification is table stakes.** Any agent surface that reports a conflict without quantifying the dollar impact is incomplete. "Three teams define revenue differently" is not actionable. "Finance's definition is $103K higher than Sales' for January; here are the 5 invoiced orders that explain the difference" is actionable.

**3. Decision routing is a product feature, not an implementation detail.** The agent must know that accrual vs. cash basis decisions go to Finance, FX policy decisions go to CFO/Treasury, and data quality decisions go to the data team. This routing table is domain knowledge that must be encoded. An agent that routes semantic decisions to the wrong person adds latency and confusion.

**4. The canonical definition must be version-controlled and linked to its decision.** `metrics_canonical.yml` points to the CFO sign-off email. Any future analyst who modifies the definition should be required to update that pointer. Git blame on the metrics file should lead to the business decision that justified it.

**5. The build is not the valuable output — the decision memo is.** If an agent spends 95% of its time generating YAML and 5% on conflict detection, it has inverted the value stack. The YAML takes 30 seconds to generate once decisions are made. The conflict detection memo, with quantified impacts and decision owners, is the deliverable that changes outcomes.

---

## Key Takeaway

Metrics layers fail on semantic conflict, not infrastructure. The database is fine. The pipelines are fine. dbt tests pass. The failure is that "revenue" means three different things across three teams, and no mechanism existed to detect or resolve that conflict.

An agent's superpower in this scenario:
1. **Detect** all conflicts systematically (not selectively)
2. **Quantify** the financial impact of each conflict before the human is asked to decide
3. **Route** decisions to the right authority
4. **Implement** immediately once decisions are made
5. **Enforce** the canonical definition with CI tests going forward

The irreducible human role:
- **Semantic authority**: deciding what business terms mean for reporting purposes
- **Stakeholder alignment**: getting three teams to accept one canonical definition
- **Sign-off**: bearing organizational accountability for the chosen definition

An agent that respects the boundary between "what I can detect and implement" and "what requires human authority" is a force multiplier. An agent that tries to resolve semantic conflicts unilaterally is a liability generator.

> The build is template work. The value is conflict detection and facilitation.
