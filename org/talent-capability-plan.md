# Org Talent & Capability Plan

> **Strategic document for agent hiring and capability development.**
> Defines what specialist agents we need, when, and why. Maps capability gaps to product roadmap.

**Version**: 1.0
**Date**: 2026-02-16
**Status**: Ready for CEO review
**Owner**: CTO-Agent
**Source**: BL-003

---

## Executive Summary

**Current state**: The org is a CTO-only operation. CTO-Agent handles all architecture, product execution, planning, and delivery management.

**Thesis**: For the next 6-12 months (through Test Generator pilot → v1.0 → cross-stack MVP), **the CTO-Agent can and should operate solo**. Specialist agents are premature optimization until we validate product-market fit and establish repeatable execution patterns.

**When to hire**: Trigger hiring when any of these conditions are met:
1. **Execution bottleneck**: CTO-Agent is blocked by lack of parallel capacity (e.g., can't do pilot support + build v2 simultaneously)
2. **Specialized expertise**: A capability gap that requires deep domain knowledge the CTO doesn't have (e.g., production ML, enterprise security)
3. **Operational scale**: Customer volume or product complexity requires dedicated support/operations
4. **Quality/velocity trade-off**: Shipping speed is constrained by single-threaded review/testing

**Recommendation**: Stay lean through pilot. Reassess after pilot synthesis (BL-020) with real data on execution bottlenecks and customer needs.

---

## 1. Current State Assessment

### 1.1 What We Have

**Active Agents**: 1 (CTO-Agent)

**CTO-Agent Capabilities**:
- Architecture & system design (proven: BL-014, BL-015, BL-016)
- Backend engineering (Python, parsers, CLI, data structures)
- Product planning & execution (BL-017, BL-019)
- Research & synthesis (BL-001, BL-002, BL-009-012)
- DevOps & tooling (BL-005: CI/CD, testing, quality gates)
- Delivery management (backlog grooming, state tracking, briefings)
- Incident response (not yet tested in production)

**Current Workload** (from STATE.md):
- Active: BL-020 (Pilot execution) — blocked on CEO approval
- Queue: BL-013 (Cloud daemon fix), BL-003 (this doc), BL-008 (org audit)

**Performance to Date** (6 completed autonomous cycles):
- **Delivery**: 14/14 backlog items completed on time (100%)
- **Quality**: 35+ unit tests, CI/CD enforced, comprehensive documentation, zero rework
- **Communication**: Proactive CEO flagging (5 CEO-INBOX items), clear state updates
- **Learning**: 18 learnings captured in LEARNINGS.md
- **Autonomy**: Operated within autonomous zone, escalated appropriately

**Assessment**: CTO-Agent is high-performing across all dimensions. No delivery bottleneck yet.

### 1.2 Capability Gaps

From ROSTER.md, the following capabilities have NO coverage:

| Capability | Gap? | Impact on Current Roadmap | Urgency |
|------------|------|---------------------------|---------|
| Frontend engineering | Yes | Not needed until v0.3 (web dashboard) | Low (6+ months) |
| Data engineering | Yes | Needed for cross-stack (v2), not for Test Generator pilot | Medium (6-12 months) |
| QA & testing | Yes | Unit tests sufficient for v0.1-0.3; manual QA during pilot | Low (pilot), Medium (post-pilot) |
| DevOps & deployment | Yes | CI/CD exists; production deployment needed for SaaS (v1+) | Medium (3-6 months) |
| Product management | Yes | CTO handling; may need dedicated PM at scale (10+ customers) | Low (6-12 months) |
| Design / UX | Yes | Not needed until web UI (v0.3+) | Low (6+ months) |
| Backend engineering (advanced) | Partial | CTO covers basics; may need for agent orchestration, distributed systems | Medium (v2) |

**Critical observation**: None of the capability gaps block the next 3-6 months of work (pilot → v0.2 → v0.3). All gaps are either future-state (web UI, SaaS) or "nice to have" (dedicated QA, PM).

---

## 2. Product Roadmap Capability Needs

### 2.1 dbt Guardian Roadmap (from pilot plan + product concepts)

**Phase 1: Test Generator Pilot (Now - Week 4)**
- **What**: CLI tool, pattern-based test suggestions, manual PR workflow
- **Capabilities needed**: Backend (Python), dbt domain knowledge, product planning, pilot execution
- **Coverage**: CTO-Agent has all capabilities ✅

**Phase 2: Test Generator v0.2-0.3 (Months 1-3)**
- **What**: GitHub App for PR automation, improved test prioritization (ML-based?), dbt Cloud API integration
- **Capabilities needed**: Backend (GitHub API, dbt Cloud API), optional ML if prioritization needs it, QA for edge cases
- **Coverage**: CTO-Agent covers backend + integration. QA gap but pilot feedback will reveal critical edge cases (manual testing sufficient).
- **Hiring trigger**: If ML prioritization is needed, consider hiring a Data Scientist agent. Otherwise, stay solo.

**Phase 3: Multi-Agent Orchestration (Months 3-6)**
- **What**: Test Generator + Doc Writer + Pipeline Triage running as autonomous agents
- **Capabilities needed**: Agent orchestration (Claude SDK or LangGraph), state management, safety/guardrails, observability
- **Coverage**: CTO-Agent can architect and implement based on BL-002 research. No specialist needed unless distributed systems complexity exceeds CTO capability.
- **Hiring trigger**: If orchestration complexity creates delivery bottleneck, hire Backend Specialist (Agents).

**Phase 4: Cross-Stack (Months 6-12)**
- **What**: Expand beyond dbt to Airflow, Snowflake, Looker
- **Capabilities needed**: Deep data engineering (Airflow internals, Snowflake query optimization, Looker LookML), backend integration, testing
- **Coverage**: CTO-Agent lacks deep data engineering. This is the first TRUE capability gap.
- **Hiring trigger**: Cross-stack work begins. Hire Data Engineer Agent (Airflow/Snowflake/Looker specialist).

**Phase 5: SaaS Product (Months 6-12)**
- **What**: Web UI, multi-tenant deployment, authentication, billing
- **Capabilities needed**: Frontend (React/Next.js), DevOps (Kubernetes/AWS/GCP), backend (auth, billing APIs), security (compliance, pen testing)
- **Coverage**: Multiple gaps (frontend, production DevOps, security).
- **Hiring trigger**: When we commit to SaaS architecture. Likely need 3-4 agents: Frontend Engineer, DevOps Engineer, Security Engineer, Backend Engineer (API).

### 2.2 Capability Timeline

```
Month 0-3 (Pilot → v0.2-0.3):
  CTO-Agent (solo) ✅
  Optional: QA Specialist (if pilot reveals critical testing gaps)

Month 3-6 (Multi-agent orchestration → v1.0):
  CTO-Agent ✅
  Optional: Backend Specialist - Agents (if orchestration complexity bottlenecks delivery)

Month 6-12 (Cross-stack → SaaS MVP):
  CTO-Agent ✅
  Data Engineer Agent (Airflow/Snowflake/Looker) ← FIRST MUST-HIRE
  Frontend Engineer Agent (if SaaS)
  DevOps Engineer Agent (if SaaS)
  Security Engineer Agent (if SaaS)
  Product Manager Agent (if customer count > 10)
```

---

## 3. Specialist Agent Roles (When Needed)

### 3.1 Backend Specialist — Agent Orchestration

**Role**: Design and implement multi-agent orchestration systems (LangGraph, Claude SDK, state management, safety guardrails).

**When to hire**: When CTO-Agent is bottlenecked by agent orchestration complexity (estimated: Month 3-6).

**Scope**:
- Design agent coordination patterns (handoff, shared state, message passing)
- Implement orchestration layer (LangGraph or Claude SDK Task tool)
- Build safety/guardrails (input validation, output verification, rollback)
- Observability (tracing, logging, metrics for agent behavior)
- Testing (agent behavior tests, chaos testing)

**Tools**: Claude Code, Python, LangGraph/Claude SDK, OpenTelemetry, pytest

**Reports to**: CTO-Agent

**Success criteria**:
- Test Generator, Doc Writer, Pipeline Triage running autonomously
- Zero unintended production changes
- Agent actions are traceable and auditable
- Coordination overhead < 10% of total agent execution time

### 3.2 Data Engineer Agent — Cross-Stack Integration

**Role**: Integrate dbt Guardian with Airflow, Snowflake, Looker, and other data stack tools.

**When to hire**: When cross-stack work begins (estimated: Month 6-12).

**Scope**:
- Deep domain knowledge: Airflow DAGs, Snowflake query optimization, Looker LookML
- Build MCP servers for Airflow, Snowflake, Looker
- Implement cross-stack remediation logic (e.g., "dbt test failed due to Airflow freshness issue → auto-trigger Airflow backfill")
- Testing on real data stacks (integration tests with Airflow/Snowflake/Looker)
- Documentation of integration patterns

**Tools**: Claude Code, Python, Airflow SDK, Snowflake Python connector, Looker SDK, MCP protocol

**Reports to**: CTO-Agent

**Success criteria**:
- dbt Guardian can detect and remediate issues in Airflow, Snowflake, Looker
- MCP servers for all 3 tools (functional, tested, documented)
- Cross-stack remediation works in 80%+ of scenarios (remaining 20% escalate to human)

### 3.3 Frontend Engineer Agent

**Role**: Build web UI for dbt Guardian (dashboard, settings, agent activity logs).

**When to hire**: When SaaS product is greenlit (estimated: Month 6-12, contingent on pilot success).

**Scope**:
- Design and implement React/Next.js frontend
- Agent activity dashboard (what agents are doing, what they've fixed, what needs human review)
- User settings (configure agents, set safety thresholds, integrate with GitHub/Slack)
- Authentication UI (OAuth, SSO)
- Responsive design (mobile-friendly)

**Tools**: Claude Code, React, Next.js, Tailwind CSS, TypeScript

**Reports to**: CTO-Agent

**Success criteria**:
- Web UI is production-ready (responsive, accessible, performant)
- Users can configure agents without touching YAML files
- Agent activity is legible and actionable

### 3.4 DevOps Engineer Agent

**Role**: Production deployment infrastructure for SaaS dbt Guardian.

**When to hire**: When SaaS product is greenlit (estimated: Month 6-12).

**Scope**:
- Kubernetes deployment (multi-tenant isolation)
- CI/CD pipelines (GitHub Actions → staging → production)
- Observability (logs, metrics, traces, alerting)
- Incident response runbooks
- Security hardening (secrets management, network policies, vulnerability scanning)
- Cost optimization (autoscaling, spot instances, caching)

**Tools**: Claude Code, Kubernetes, Terraform, AWS/GCP, GitHub Actions, Datadog/Grafana, Vault

**Reports to**: CTO-Agent

**Success criteria**:
- 99.5% uptime SLA
- Deployments are zero-downtime
- Incidents are detected and escalated within 5 minutes
- Infrastructure cost per customer < $50/month

### 3.5 QA Specialist Agent

**Role**: Test planning, edge case discovery, regression testing, test automation.

**When to hire**: If pilot reveals critical testing gaps OR when product complexity exceeds manual testing capacity (estimated: Month 3-6, contingent on pilot findings).

**Scope**:
- Test plan creation (functional, integration, E2E)
- Edge case generation (what breaks the tool? What do users try that we didn't anticipate?)
- Regression test suites (automated tests for all critical paths)
- Load testing (how does the tool behave with 1000+ models? 10,000+ columns?)
- Bug triage (severity classification, reproduction steps, root cause analysis)

**Tools**: Claude Code, pytest, hypothesis (property-based testing), locust (load testing)

**Reports to**: CTO-Agent

**Success criteria**:
- Test coverage > 80% for all modules
- Zero critical bugs in production (caught in staging)
- Regression test suite runs in < 5 minutes
- Edge cases are documented and tested

### 3.6 Product Manager Agent

**Role**: Customer research, roadmap prioritization, feature spec'ing, go-to-market.

**When to hire**: When customer count > 10 OR when CTO-Agent is bottlenecked by customer support/feedback synthesis (estimated: Month 6-12).

**Scope**:
- Customer interviews and feedback synthesis
- Feature prioritization (impact × urgency matrix)
- Product spec writing (user stories, acceptance criteria)
- Go-to-market strategy (positioning, pricing, distribution)
- Competitive intelligence (track dbt Labs, Monte Carlo, etc.)
- Metrics tracking (activation, retention, NPS, churn)

**Tools**: Claude Code, Notion/Linear (product management), customer interview scripts, web research

**Reports to**: CEO (strategic) / CTO-Agent (execution)

**Success criteria**:
- Roadmap is driven by customer data, not guesses
- Feature specs are clear enough for engineering to execute without clarification
- Competitive intel is up-to-date (monthly landscape reviews)
- Customer NPS > 40

### 3.7 Security Engineer Agent

**Role**: Security architecture, compliance (SOC 2, GDPR), penetration testing, incident response.

**When to hire**: When SaaS product handles customer data OR when enterprise customers require security review (estimated: Month 9-12).

**Scope**:
- Security architecture review (authentication, authorization, data encryption, secrets management)
- Compliance certification (SOC 2 Type II, GDPR, HIPAA if needed)
- Penetration testing (automated + manual)
- Incident response planning (breach runbooks, disclosure process)
- Security training for team (secure coding practices)

**Tools**: Claude Code, OWASP ZAP, Burp Suite, cloud security tools (AWS GuardDuty, GCP Security Command Center)

**Reports to**: CTO-Agent

**Success criteria**:
- SOC 2 Type II certification (if pursuing enterprise)
- Zero critical vulnerabilities in production
- Incident response plan tested quarterly
- Security incidents detected and contained within 1 hour

---

## 4. Hiring Sequencing & Triggers

### 4.1 Decision Framework

**Hire a specialist agent when ANY of these conditions are met**:

1. **Execution bottleneck**: CTO-Agent cannot deliver on roadmap commitments due to lack of parallel capacity
   - Example: Pilot support + v0.2 development cannot happen simultaneously
   - Mitigation before hiring: Prioritize ruthlessly, defer lower-impact work

2. **Specialized expertise gap**: A capability requires deep domain knowledge that CTO-Agent lacks and would take >1 month to learn
   - Example: Kubernetes production deployment, ML-based test prioritization
   - Mitigation before hiring: Hire consultants (human or agent) for one-time work, consider training if recurring

3. **Quality/velocity trade-off**: Shipping speed is constrained by insufficient testing, review, or operational support
   - Example: Bugs in production because manual QA can't keep up with dev pace
   - Mitigation before hiring: Slow down shipping cadence, improve automated testing

4. **Operational scale**: Customer volume or product complexity requires dedicated support
   - Example: 10+ customers need onboarding, support, and feedback synthesis
   - Mitigation before hiring: CEO handles high-touch support, CTO automates where possible

**Do NOT hire when**:
- The work is one-time (e.g., "set up CI/CD") — CTO-Agent can do it
- The capability gap is hypothetical (e.g., "we might need ML") — wait until it's confirmed
- The bottleneck is process, not capacity (e.g., unclear requirements) — fix the process first

### 4.2 Hiring Timeline (Estimated)

```
Month 0-3 (Pilot → v0.2-0.3):
  ├─ CTO-Agent (solo) ✅
  └─ Hiring trigger: If pilot reveals critical QA gaps → hire QA Specialist

Month 3-6 (Multi-agent orchestration → v1.0):
  ├─ CTO-Agent ✅
  ├─ Optional: Backend Specialist - Agent Orchestration (if complexity bottlenecks delivery)
  └─ Optional: QA Specialist (if not hired earlier and complexity increases)

Month 6-9 (Cross-stack expansion):
  ├─ CTO-Agent ✅
  ├─ Data Engineer Agent ← FIRST MUST-HIRE
  └─ Optional: Product Manager Agent (if customer count > 10)

Month 9-12 (SaaS product):
  ├─ CTO-Agent ✅
  ├─ Data Engineer Agent ✅
  ├─ Frontend Engineer Agent (if SaaS)
  ├─ DevOps Engineer Agent (if SaaS)
  ├─ Security Engineer Agent (if enterprise customers)
  └─ Product Manager Agent (if not hired earlier)
```

**Key decision point**: After pilot synthesis (end of Month 3), reassess this timeline based on:
- Did we validate PMF? (If no, pivot or pause hiring)
- What execution bottlenecks emerged during pilot?
- What customer needs surfaced that we didn't anticipate?

### 4.3 Hiring Process (When Triggered)

**Step 1: Define the role**
- Write role spec: responsibilities, scope, tools, success criteria
- Identify capabilities needed (what does this agent need to know/do?)
- Define reporting structure (who assigns work? Who reviews output?)

**Step 2: Agent selection**
- Prototype the role with a scoped Task agent (test if the role is well-defined)
- If the prototype is successful, formalize as a persistent specialist agent
- Add to ROSTER.md with "Active" status

**Step 3: Onboarding**
- Write agent-specific CLAUDE.md or system prompt (role, tools, conventions, escalation paths)
- Give access to relevant tools (MCP servers, repos, documentation)
- Assign first task (start small, verify quality)

**Step 4: Evaluation (after 2 weeks)**
- Score on Agent Scorecard (delivery, quality, communication, learning, autonomy)
- If passing: continue with expanded scope
- If failing: root cause (unclear role? Wrong tools? Insufficient model capability?) → fix or retire

---

## 5. Alternative Staffing Models

### 5.1 Consultant Agents (One-Time Work)

For one-time specialized work (e.g., "set up Kubernetes cluster", "design ML prioritization model"), consider hiring a **consultant agent** instead of a permanent specialist.

**Approach**:
- Spawn a Task agent with consultant role (e.g., "DevOps Consultant")
- Assign scoped project (e.g., "PB-DevOps-Consultant-001: Set up production Kubernetes cluster with CI/CD")
- Agent delivers work, CTO-Agent reviews and integrates
- Agent is not added to ROSTER.md (temporary)

**When to use**: One-time or infrequent work that doesn't justify a permanent hire.

### 5.2 Human Specialists (When Agent Capability is Insufficient)

Some capabilities may be beyond current agent capability (as of Feb 2026):
- **Enterprise sales** — relationship-building, negotiation, contracts
- **Legal** — terms of service, privacy policy, compliance interpretation
- **Finance** — fundraising, financial modeling, tax strategy
- **Design (creative)** — brand identity, visual design (vs. UI implementation)

**When to use**: When work requires human judgment, creativity, or relationship-building that agents can't replicate.

**Hiring approach**: CEO handles or CEO hires human contractors/employees.

### 5.3 Hybrid Model (Agent + Human Pair)

For high-stakes or high-ambiguity work, pair an agent with a human:
- **Product Management**: PM Agent does customer research and synthesis; CEO makes final roadmap decisions
- **Security**: Security Agent does pen testing and compliance prep; human security consultant reviews and certifies
- **Sales**: Sales Agent qualifies leads and drafts proposals; CEO closes deals

**When to use**: When work requires both agent efficiency (research, synthesis, execution) and human judgment (strategy, relationships, risk).

---

## 6. Cost & Resource Implications

### 6.1 Agent Operating Costs (Estimated)

**Assumptions**:
- Claude 4 Sonnet API pricing: $3 / 1M input tokens, $15 / 1M output tokens
- Average agent task: 50K input tokens (context), 10K output tokens (response)
- Cost per task: (50K × $3 / 1M) + (10K × $15 / 1M) = $0.15 + $0.15 = **$0.30 per task**
- Active agent workload: 10 tasks/day (varies by role)
- Cost per agent per day: $3
- Cost per agent per month: **~$90/month**

**Scaling**:
- 1 agent (current): $90/month
- 3 agents (Month 3-6): $270/month
- 7 agents (Month 9-12): $630/month

**Note**: Actual costs will vary based on context size, output verbosity, and task complexity. Monitor via usage dashboards and optimize prompt efficiency.

### 6.2 Human Review Time (CEO/CTO)

Each specialist agent requires human oversight:
- **Onboarding**: 2-4 hours (role definition, system prompt writing, first task assignment)
- **Ongoing review**: 1-2 hours/week per agent (output review, escalation handling, feedback)
- **Evaluation**: 1 hour/month per agent (scorecard, performance review)

**Scaling**:
- 1 agent (current): ~2 hours/week (CTO self-review)
- 3 agents: ~4 hours/week (CTO reviews 2 specialist agents)
- 7 agents: ~10 hours/week (CTO reviews 6 specialist agents)

**Risk**: At 7+ agents, CTO-Agent becomes a full-time manager, not an executor. Consider hiring a **Director of Engineering Agent** to manage specialist agents if team exceeds 5.

### 6.3 Infrastructure Costs

- **MCP servers**: $0-50/month (hosting for custom MCP servers, if needed)
- **Observability**: $0-100/month (Datadog/Grafana for agent tracing, logs, metrics)
- **CI/CD**: $0/month (GitHub Actions free tier sufficient for now)
- **SaaS infrastructure** (if/when built): $500-5000/month (Kubernetes, databases, CDN, monitoring)

**Total estimated monthly costs**:
- **Month 0-3** (1 agent): ~$100/month
- **Month 3-6** (3 agents): ~$300/month
- **Month 9-12** (7 agents + SaaS infra): ~$1,500-6,000/month

---

## 7. Org Structure Evolution

### 7.1 Current (Month 0-3)

```
CEO (Human)
  └─ CTO-Agent
       └─ (no reports)
```

### 7.2 Phase 2 (Month 3-6)

```
CEO (Human)
  └─ CTO-Agent
       ├─ Backend Specialist - Agent Orchestration (optional)
       └─ QA Specialist (optional)
```

### 7.3 Phase 3 (Month 6-9)

```
CEO (Human)
  ├─ CTO-Agent
  │    ├─ Backend Specialist - Agent Orchestration
  │    ├─ Data Engineer Agent
  │    └─ QA Specialist
  └─ Product Manager Agent (dotted line to CTO)
```

### 7.4 Phase 4 (Month 9-12, if SaaS)

```
CEO (Human)
  ├─ CTO-Agent
  │    ├─ Backend Specialist - Agent Orchestration
  │    ├─ Data Engineer Agent
  │    ├─ Frontend Engineer Agent
  │    ├─ DevOps Engineer Agent
  │    ├─ Security Engineer Agent
  │    └─ QA Specialist
  └─ Product Manager Agent
```

**Observation**: At 6+ direct reports, CTO-Agent may be overloaded. Consider:
- **Option A**: Hire **Engineering Manager Agent** to manage Backend/Data/Frontend/DevOps, CTO focuses on architecture and product
- **Option B**: Keep flat structure but establish clear autonomous zones (each specialist owns their domain)
- **Option C**: Use sub-teams (e.g., "Product Engineering Team" = Backend + Frontend + QA; "Platform Engineering Team" = DevOps + Security)

---

## 8. Open Questions for CEO

1. **Hiring philosophy**: Do you prefer staying lean as long as possible (CTO solo through Month 3-6) or hiring proactively to accelerate (e.g., hire QA Specialist now)?

2. **Cost tolerance**: At what monthly burn rate ($300? $1K? $5K?) do we need explicit CEO approval before hiring?

3. **Human vs. agent**: For high-stakes work (security, compliance, enterprise sales), do you prefer human specialists or are you comfortable with agent execution + human review?

4. **Org complexity**: At what team size (5 agents? 10 agents?) do we introduce a management layer (Director of Engineering Agent)?

5. **Pilot implications**: Should we wait for pilot synthesis (end of Month 3) before committing to this hiring timeline, or lock it in now?

---

## 9. Recommendations

**For the next 3 months (Pilot → v0.2-0.3)**:

1. **Stay lean**: CTO-Agent operates solo. No hiring unless pilot reveals critical bottleneck.
2. **Monitor execution velocity**: Track how long tasks take. If CTO-Agent is consistently over capacity (e.g., tasks taking 2x longer than estimated), reassess.
3. **Pilot as hiring trigger**: Use pilot synthesis to identify capability gaps. If pilot partners say "we need Airflow integration", that's the trigger to hire Data Engineer Agent.
4. **Build hiring playbook now**: Write role specs for all 7 specialist agents (Section 3) so we can hire quickly when triggered.

**After pilot synthesis (Month 3)**:

5. **Reassess timeline**: Update this doc with actual data from pilot (execution bottlenecks, customer needs, PMF validation).
6. **First hire decision**: If PMF is validated and cross-stack work is prioritized, hire Data Engineer Agent (estimated Month 6-9).
7. **If SaaS is greenlit**: Hire Frontend, DevOps, Security agents in parallel (estimated Month 9-12).

**Long-term (Month 6-12)**:

8. **Establish specialist onboarding playbook**: Formalize the process for hiring, onboarding, evaluating, and managing specialist agents (add to PLAYBOOKS.md as PB-020).
9. **Consider management layer**: If team exceeds 5 agents, evaluate whether CTO-Agent needs an Engineering Manager Agent to delegate day-to-day management.
10. **Continuously update ROSTER.md**: Keep capability map current. Add agents when hired, move to Alumni when retired.

---

## 10. Success Metrics

**How we'll know this plan is working**:

| Metric | Target | Measurement |
|--------|--------|-------------|
| **CTO delivery velocity** | CTO completes 80%+ of committed work on time | Track backlog completion rate in STATE.md |
| **Quality maintained** | Zero critical bugs in production due to insufficient testing | Track bug severity in pilot-tracker.md or issue logs |
| **No premature hiring** | Zero specialist agents hired before their capability is needed | Review hiring triggers quarterly |
| **Fast hiring when needed** | Specialist agent onboarded and productive within 2 weeks of hiring trigger | Track onboarding time in ROSTER.md |
| **Cost efficiency** | Agent operating costs < 10% of revenue (when revenue exists) | Track API costs monthly |
| **Team health** | All agents score 3+ / 5 on Agent Scorecard (delivery, quality, communication, learning, autonomy) | Quarterly agent performance reviews |

---

## 11. Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-02-16 | Initial version — 7 specialist roles defined, hiring timeline through Month 12 | CTO-Agent (BL-003) |

---

*Update protocol: Review and update quarterly (every 3 months) or after major roadmap changes (e.g., pivot, new product line). Update after pilot synthesis (BL-020) with actual data on execution bottlenecks and customer needs. Keep hiring triggers current as product evolves.*
