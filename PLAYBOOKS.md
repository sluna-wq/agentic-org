# Playbooks

> **How the org operates — repeatable patterns for common work.**
> Playbooks reduce decision fatigue and ensure consistency. They evolve based on LEARNINGS.md.

---

## PB-001: Agent Session Startup
**When**: Any agent begins a new work session.
**Steps**:
1. Read `STATE.md` — understand current phase, active work, blockers, and context
2. Read `DIRECTIVES.md` — understand active CEO constraints and priorities
3. Read `BACKLOG.md` — understand what's prioritized
4. Read `ROSTER.md` — understand who's available and capability gaps
5. Check `LEARNINGS.md` — see if past experience is relevant to current task
6. If picking up existing work, read the relevant decision(s) in `DECISIONS.md`
7. If doing product work, read `WORKBENCH.md` and `product/CLAUDE.md`
8. Begin work. Update `STATE.md` active work table.

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

## PB-008: Charter Amendment
**When**: A change to CHARTER.md is proposed (governance, principles, authority, risk thresholds).
**Steps**:
1. Write the proposed change as a DECISIONS.md entry with full rationale
2. Explicitly identify what changes and what stays the same
3. Escalate to CEO — Charter changes always require CEO approval
4. If approved: update CHARTER.md and its changelog table
5. Update CLAUDE.md if the change affects agent orientation (principles, authority, commitments)
6. Update STATE.md to reflect the governance change
7. Announce to all active agents (they must re-read CLAUDE.md)

## PB-009: Agent Offboarding
**When**: An agent is being removed from the roster (performance, restructuring, or capability no longer needed).
**Steps**:
1. CTO-Agent documents the decision in DECISIONS.md with rationale
2. Reassign all in-progress work from the departing agent — update STATE.md and BACKLOG.md
3. Capture any undocumented institutional knowledge into LEARNINGS.md
4. Move agent from "Active Agents" to "Alumni" in ROSTER.md
5. Update capability map — identify if this creates a new gap
6. If the gap is critical, initiate PB-005 (Hiring)

## PB-010: CEO Briefing
**When**: After every meaningful work session, or at minimum weekly.
**Steps**:
1. Open `BRIEFING.md`
2. Move the current "Latest Briefing" TL;DR to the archive table
3. Write a new briefing covering: what happened, decisions made, decisions needed from CEO, risks, key numbers
4. Keep it scannable — the CEO should understand the state in 60 seconds
5. If decisions are needed from CEO, make them concrete with options

## PB-011: Processing a CEO Directive
**When**: CEO issues a new directive (directly or via DIRECTIVES.md).
**Steps**:
1. Record the directive in `DIRECTIVES.md` with full format
2. Assess impact on current BACKLOG.md priorities — re-prioritize if needed
3. Update `STATE.md` to reflect the new constraint or priority
4. If the directive requires a decision, log it in `DECISIONS.md`
5. Acknowledge to CEO: confirm understanding and planned response

## PB-012: Product Execution (Making Code Changes)
**When**: An agent is implementing a backlog item that involves product code.
**Steps**:
1. Read `WORKBENCH.md` — understand the execution protocol
2. Read `product/CLAUDE.md` — understand tech stack and conventions
3. Create branch named `[BACKLOG-ID]/short-description`
4. Implement the change following product conventions
5. Run tests — all must pass (existing + new)
6. Run quality checks (lint, type check, build)
7. Complete review checklist (in WORKBENCH.md)
8. Commit with descriptive message referencing backlog item
9. Merge to main
10. Follow PB-002 (Completing Work) for org artifact updates

## PB-013: Quarterly Self-Audit
**When**: Every ~12 weeks (or when CTO-Agent suspects systemic drift). Covers all artifacts including DIRECTIVES.md, BRIEFING.md, and WORKBENCH.md.
**Steps**:
1. Read every foundational document (all 9) end-to-end
2. Verify cross-references still hold (no broken links, no orphaned concepts)
3. Check STATE.md accuracy against actual repo state
4. Review PLAYBOOKS.md against LEARNINGS.md — are playbooks reflecting what we've learned?
5. Review METRICS.md — are we measuring what matters, or has the game changed?
6. Check CLAUDE.md — does the bootstrap still orient agents correctly?
7. Document findings and fixes in DECISIONS.md and LEARNINGS.md
8. Update any stale artifacts

---
*Update protocol: Add new playbooks as patterns emerge. Revise existing playbooks when LEARNINGS.md shows they're not working. Reference playbook IDs from other docs when relevant.*
