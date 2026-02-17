# Playbooks Archive

> **Archived 2026-02-17 per DIR-004 (YAGNI).** These playbooks were never referenced in 16 daemon cycles.
> Restore any of them to PLAYBOOKS.md when they become relevant. Full content preserved.

## Why archived
Usage audit found only PB-001, PB-002, PB-014, PB-017, PB-020 were ever used.
The other 15 playbooks represent anticipated-but-not-yet-needed process.
Keeping them in the main file added cognitive overhead with no operational benefit.

---

## PB-003: Weekly Planning
**When**: Start of each planning cycle.
1. Review METRICS.md — are we moving the right numbers?
2. Review STATE.md — current health?
3. Review BACKLOG.md — re-prioritize based on latest context
4. Review LEARNINGS.md — apply recent insights
5. Review ROSTER.md — right people for planned work?
6. Draft plan, present to CEO for approval
7. After approval, update STATE.md and BACKLOG.md

## PB-004: Escalation
**When**: Agent encounters something outside their scope or above risk threshold.
1. Document: what happened, what's at risk, what options exist
2. If within CTO-Agent scope → CTO-Agent decides, logs in DECISIONS.md
3. If above CTO-Agent scope (see CHARTER.md thresholds) → escalate to CEO
4. Never block silently — surface in STATE.md immediately

## PB-005: Hiring a New Agent
**When**: Capability gap blocks planned work.
1. CTO-Agent documents gap in DECISIONS.md
2. Define role, scope, capabilities, success criteria
3. Get CEO approval
4. Add to ROSTER.md with full profile, update capability map
5. Onboard: agent runs PB-001 on first session

## PB-006: Incident Response
**When**: Something breaks in production or process.
1. Assess severity and blast radius
2. If production-impacting: stabilize first, investigate second
3. Log incident in DECISIONS.md
4. After resolution: LEARNINGS.md entry (blameless postmortem)
5. Update PLAYBOOKS.md if process should change

## PB-007: Updating the Org's Self-Model
**When**: Something material changes about how the org works.
1. Identify affected artifacts
2. Update them with accurate current information
3. Cross-reference: if change in one doc should reflect in another, update both
4. Keep STATE.md current
5. Commit with message explaining what changed and why

## PB-008: Charter Amendment
**When**: Change to CHARTER.md is proposed.
1. Write proposed change as DECISIONS.md entry with rationale
2. Identify what changes and what stays the same
3. Escalate to CEO — Charter changes always require CEO approval
4. If approved: update CHARTER.md and its changelog
5. Update CLAUDE.md if it affects agent orientation
6. Announce to all active agents

## PB-009: Agent Offboarding
**When**: Agent being removed from roster.
1. Document decision in DECISIONS.md with rationale
2. Reassign in-progress work — update STATE.md and BACKLOG.md
3. Capture undocumented institutional knowledge to LEARNINGS.md
4. Move agent to "Alumni" in ROSTER.md, update capability map
5. If gap is critical, initiate PB-005

## PB-010: CEO Briefing (Superseded by CEO.md)
**When**: After every meaningful session. Now handled by CEO.md updates.
1. Update CEO.md "Last 10 Cycles" and "Your Queue" sections
2. Keep it scannable — CEO understands state in 60 seconds
3. Concrete decisions needed with options

## PB-011: Processing a CEO Directive
**When**: CEO issues a new directive.
1. Record in DIRECTIVES.md with full format
2. Assess impact on BACKLOG.md priorities
3. Update STATE.md to reflect new constraint or priority
4. If requires a decision, log in DECISIONS.md
5. Acknowledge to CEO

## PB-012: Product Execution (Code Changes)
**When**: Implementing a backlog item involving product code.
1. Read WORKBENCH.md
2. Read product/CLAUDE.md
3. Create branch named [BACKLOG-ID]/short-description
4. Implement following product conventions
5. Run tests (all must pass) + quality checks (lint, type, build)
6. Complete review checklist (in WORKBENCH.md)
7. Commit, merge to main
8. Follow PB-002 for org artifact updates

## PB-013: Quarterly Self-Audit
**When**: Every ~12 weeks or when systemic drift is suspected.
1. Read every org artifact end-to-end
2. Verify cross-references still hold
3. Check STATE.md accuracy against actual repo state
4. Review PLAYBOOKS.md against LEARNINGS.md
5. Review METRICS.md — measuring what matters?
6. Check CLAUDE.md — does bootstrap still orient agents correctly?
7. Review .claude/skills/ — current and useful?
8. Check daemon/CYCLE-LOG.md — daemon running reliably?
9. Evaluate new AI tools/patterns — anything to adopt?
10. Document findings in DECISIONS.md and LEARNINGS.md

## PB-015: Weekly CEO↔CTO Sync
**When**: Weekly, or when CEO invokes /sync skill.
1. Read all org artifacts comprehensively
2. Read daemon/CYCLE-LOG.md — summarize what org did this week
3. Generate sync prep: roadmap status, key decisions, proposals needing CEO input, risks, next week plan
4. Present to CEO in conversation
5. After discussion, update DIRECTIVES.md, BACKLOG.md, STATE.md, THREAD.md
6. Commit updates

## PB-016: CEO Notification (Superseded by CEO.md)
**When**: CTO needs CEO attention. Now handled by CEO.md "Your Queue" section.
Severity levels: [INFO] (FYI), [NEEDS_INPUT] (blocking), [URGENT] (something broke).
Format: brief title, what happened, why it matters, options, CTO recommendation.

## PB-018: Activity Logging
**When**: After every daemon cycle.
1. Append row to daemon/CYCLE-LOG.md: Cycle #, Timestamp, Duration, Focus, Actions Taken, Outcome
2. Actions Taken: concise list of what was attempted (not just focus area)
3. Outcome: note successes AND failures
4. Keep entries glanceable — CEO understands in 5 seconds per row

## PB-019: Product Repo Bootstrap
**When**: CEO approves a product direction and it's time to build.
1. Create new git repo for the product
2. Add CLAUDE.md to product repo (tech stack, conventions, project structure, testing)
3. Register in .product-repos.md
4. Update WORKBENCH.md if execution protocol needs product-specific adjustments
5. Set up CI/CD (GitHub Actions)
6. Configure product repo as agent's working directory for product execution
7. First commit: scaffold project structure
8. Update STATE.md

---
*Restore any playbook to PLAYBOOKS.md when it becomes operationally needed.*
