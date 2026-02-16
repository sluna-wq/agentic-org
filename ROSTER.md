# Roster

> **Who is in the org, what can they do, and how are they performing.**
> This is both a directory and a capability map. It answers: "Do we have someone who can do X?"

## Active Agents

### CTO-Agent
- **Role**: Technical and product execution lead
- **Reports to**: CEO (Human)
- **Capabilities**: Architecture, system design, code review, agent coordination, planning, delivery management, incident response
- **Tools**: Claude Code (full toolset — bash, file ops, git, web, browser automation, sub-agents)
- **Scope**: All technical and product decisions within Charter constraints
- **Hired**: 2026-02-11
- **Status**: Active

## Capability Map
| Capability | Covered By | Gap for Next 6mo? | Notes |
|------------|-----------|-------------------|-------|
| Architecture & system design | CTO-Agent | No | ✅ CTO high-performing |
| Backend engineering (Python, APIs) | CTO-Agent | No | ✅ Through v1.0 (Month 6) |
| Data engineering (Airflow, Snowflake) | — | **Yes** (Month 6+) | First specialist hire when cross-stack work begins |
| Frontend engineering (React, Next.js) | — | **Yes** (Month 9+) | Only needed if SaaS product greenlit |
| DevOps & deployment (K8s, AWS) | — | **Yes** (Month 9+) | Only needed if SaaS product greenlit |
| QA & testing | CTO-Agent | No | ✅ 35+ unit tests, CI/CD enforced |
| Product management | CTO-Agent | No | ✅ Through pilot validation (Month 3) |
| Security & compliance | — | **Yes** (Month 9+) | Only needed if SaaS product greenlit |
| Design / UX | — | **Yes** (if needed) | CLI-first approach defers this |

**Analysis**: Per BL-003 talent plan (org/talent-capability-plan.md), NO blocking capability gaps for next 6 months. CTO-Agent can handle Test Generator pilot (Month 0-3), v0.2-0.3 PR automation (Month 1-3), and v1.0 multi-agent orchestration (Month 3-6). First specialist hire: **Data Engineer Agent at Month 6-9** when cross-stack integration (Airflow/Snowflake/Looker) begins. SaaS team (Frontend/DevOps/Security) only if greenlit at Month 9-12.

## Hiring Queue
**Next hire**: Data Engineer Agent (Month 6-9, when cross-stack work begins)

**Hiring triggers** (from talent plan):
1. Execution bottleneck — CTO can't deliver on roadmap due to lack of parallel capacity
2. Specialized expertise gap — capability requires deep domain knowledge CTO doesn't have
3. Operational scale — customer volume requires dedicated support
4. Quality/velocity trade-off — shipping speed constrained by insufficient testing/review

**Defined roles ready to hire** (see org/talent-capability-plan.md):
- Backend Specialist - Agent Orchestration (optional Month 3-6 if complexity bottlenecks delivery)
- Data Engineer Agent (MUST-HIRE Month 6-9)
- Frontend Engineer Agent (Month 9-12 if SaaS greenlit)
- DevOps Engineer Agent (Month 9-12 if SaaS greenlit)
- QA Specialist Agent (Month 9+ if quality/velocity trade-off emerges)
- Product Manager Agent (Month 12+ if customer volume scales)
- Security Engineer Agent (Month 9-12 if SaaS greenlit)

## Agent Scorecard Template
When agents are reviewed, score on:
1. **Delivery**: Did they complete committed work on time?
2. **Quality**: Did their output meet the quality bar without rework?
3. **Communication**: Did they surface blockers/risks proactively?
4. **Learning**: Did they contribute to LEARNINGS.md?
5. **Autonomy**: Did they operate within scope without unnecessary escalation?

## Alumni
None yet.

---
*Update protocol: Add new agents when hired. Update capability map. Move agents to Alumni when they leave. Keep scorecards in `/reviews/[agent-name]/` when the reviews directory exists.*
