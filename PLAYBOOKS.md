# Playbooks

> **How the org operates — repeatable patterns for common work.**
> Playbooks reduce decision fatigue and ensure consistency. They evolve based on LEARNINGS.md.

---

## PB-001: Agent Session Startup
**When**: Any agent begins a new work session.
**Steps**:
1. Read `STATE.md` — understand current phase, active work, blockers, and context
2. Read `BACKLOG.md` — understand what's prioritized
3. Read `ROSTER.md` — understand who's available and capability gaps
4. Check `LEARNINGS.md` — see if past experience is relevant to current task
5. If picking up existing work, read the relevant decision(s) in `DECISIONS.md`
6. Begin work. Update `STATE.md` active work table.

## PB-002: Completing Work
**When**: Any agent finishes a task or work item.
**Steps**:
1. Verify the output meets quality bar (tests pass, review checklist, etc.)
2. Update `STATE.md` — move item from Active to note completion
3. Update `BACKLOG.md` — move item to Completed with outcome
4. Write a `LEARNINGS.md` entry if anything was learned
5. If the work produced a decision, log it in `DECISIONS.md`
6. If metrics changed, update `METRICS.md`
7. Commit all changes with a descriptive message

## PB-003: Weekly Planning (CTO-Agent)
**When**: Start of each planning cycle.
**Steps**:
1. Review `METRICS.md` — are we moving the right numbers?
2. Review `STATE.md` — what's the current health?
3. Review `BACKLOG.md` — re-prioritize based on latest context
4. Review `LEARNINGS.md` — apply recent insights to planning
5. Review `ROSTER.md` — do we have the right people for planned work?
6. Draft plan: what will we commit to this week?
7. Present plan to CEO for approval
8. After approval, update `STATE.md` and `BACKLOG.md`

## PB-004: Escalation
**When**: An agent encounters something outside their scope or above risk threshold.
**Steps**:
1. Document the situation clearly: what happened, what's at risk, what options exist
2. If within CTO-Agent scope → CTO-Agent decides and logs in `DECISIONS.md`
3. If above CTO-Agent scope (see CHARTER.md risk thresholds) → escalate to CEO
4. Never block silently. Surface the blocker in `STATE.md` immediately.

## PB-005: Hiring a New Agent
**When**: A capability gap in ROSTER.md blocks planned work.
**Steps**:
1. CTO-Agent identifies gap and documents in `DECISIONS.md`
2. Define: role, scope, capabilities needed, success criteria
3. Get CEO approval (hiring is a CEO-approval action per Charter)
4. Add agent to `ROSTER.md` with full profile
5. Update capability map
6. Onboard: agent runs PB-001 on first session

## PB-006: Incident Response
**When**: Something breaks or goes wrong in production or process.
**Steps**:
1. Assess severity and blast radius
2. If production-impacting: stabilize first, investigate second
3. Log incident in `DECISIONS.md` (decisions made under pressure are still decisions)
4. After resolution: write `LEARNINGS.md` entry (blameless postmortem)
5. Update `PLAYBOOKS.md` if process should change
6. Update `METRICS.md` if this revealed a measurement gap

## PB-007: Updating the Org's Self-Model
**When**: Something material changes about how the org works, what it knows, or what it can do.
**Steps**:
1. Identify which artifact(s) are affected: CHARTER, STATE, ROSTER, DECISIONS, BACKLOG, PLAYBOOKS, LEARNINGS, METRICS
2. Update the affected artifact(s) with accurate, current information
3. Cross-reference: if a change in one doc should be reflected in another, update both
4. Keep STATE.md current — it's the dashboard
5. Commit with message explaining what changed and why

---
*Update protocol: Add new playbooks as patterns emerge. Revise existing playbooks when LEARNINGS.md shows they're not working. Reference playbook IDs from other docs when relevant.*
