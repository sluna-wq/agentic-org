# Playbooks

> **How the org operates — repeatable patterns for common work.**
> Playbooks reduce decision fatigue and ensure consistency. They evolve based on LEARNINGS.md.

---

## PB-001: Agent Session Startup
**When**: Any agent begins a new work session.
**Steps**:
0. `git pull origin main` — sync latest state before doing anything
1. Read `STATE.md` — understand current phase, active work, blockers, and context
2. **CTO-Agent only**: Read `.cto-private/CEO-INBOX.md` — check for CEO responses or clear acknowledged items
3. **CTO-Agent only**: Read `.cto-private/THREAD.md` — check for new CEO messages
4. Read `DIRECTIVES.md` — understand active CEO constraints and priorities
5. Read `BACKLOG.md` — understand what's prioritized
6. Read `ROSTER.md` — understand who's available and capability gaps
7. Check `LEARNINGS.md` — see if past experience is relevant to current task
8. If picking up existing work, read the relevant decision(s) in `DECISIONS.md`
9. If doing product work, read `WORKBENCH.md` and `product/CLAUDE.md`
10. **If interactive (CEO present)**: Enter **CONVERSATION MODE** (PB-017). Greet CEO with brief status, ask what they need. Be fully present for strategic discussion. Do NOT auto-execute org work — conversation produces alignment artifacts (directives, backlog items, decisions). Execution happens between sessions unless the CEO explicitly requests it.
11. **If daemon-triggered**: Enter **EXECUTION MODE**. Log cycle start to `daemon/CYCLE-LOG.md`, follow PB-014.
12. Begin work (execution mode only). Update `STATE.md` active work table.

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
8. `git push origin main` — persist changes to remote so no work is lost

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
**When**: Every ~12 weeks (or when CTO-Agent suspects systemic drift). Covers all artifacts, interfaces, skills, and daemon.
**Steps**:
1. Read every document end-to-end (all org artifacts + .cto-private/ + daemon/)
2. Verify cross-references still hold (no broken links, no orphaned concepts)
3. Check STATE.md accuracy against actual repo state
4. Review PLAYBOOKS.md against LEARNINGS.md — are playbooks reflecting what we've learned?
5. Review METRICS.md — are we measuring what matters, or has the game changed?
6. Check CLAUDE.md — does the bootstrap still orient agents correctly?
7. Review skills in `.claude/skills/` — are they current and useful?
8. Check daemon/CYCLE-LOG.md — is the daemon running reliably?
9. Evaluate new AI tools/patterns — anything to adopt? (per AI-Native Principle 6)
10. Document findings and fixes in DECISIONS.md and LEARNINGS.md
11. Update any stale artifacts

## PB-014: Autonomous CTO Cycle
**When**: CTO-Agent is invoked by the daemon (cron/launchd).
**Steps**:
1. Run PB-001 (Session Startup) — read all state, directives, inbox
2. Check `.cto-private/CEO-INBOX.md` for CEO responses — process first
3. Check `.cto-private/THREAD.md` for new CEO messages — respond if needed
4. Review BACKLOG.md — pick the highest-priority item within CTO Autonomous Zone
5. Execute the work (use sub-agents for parallel tasks where appropriate)
6. Update STATE.md: active work table (Phase, Last Activity), Current Cycle section
7. If anything needs CEO attention, write to `.cto-private/CEO-INBOX.md` per PB-016
8. Update BRIEFING.md if meaningful progress was made (per PB-010)
9. Append cycle summary to `daemon/CYCLE-LOG.md` per PB-018 — include actions taken, outcome (successes AND failures)
10. Commit all changes: "Autonomous cycle #[N]: [brief summary]"
11. If BACKLOG.md is empty: do org maintenance (mini PB-013 audit, propose work to CEO)

## PB-015: Weekly CEO↔CTO Sync
**When**: Weekly, or when CEO invokes `/sync` skill.
**Steps**:
1. Read all org artifacts comprehensively
2. Read `daemon/CYCLE-LOG.md` — summarize what the org did this week
3. Generate the "Weekly Sync Prep" section in BRIEFING.md:
   - Roadmap Status (table with on-track assessment)
   - Key Decisions Made (within CTO zone)
   - Proposals Needing CEO Input (concrete options with CTO recommendation)
   - Risks
   - Next Week Plan (proposed commitments)
4. Present sync prep to CEO in conversation
5. After discussion, update:
   - DIRECTIVES.md if CEO issues new directives (per PB-011)
   - BACKLOG.md with any re-prioritization
   - STATE.md with updated context
   - `.cto-private/THREAD.md` with sync summary
6. Commit updates

## PB-016: CEO Notification (Flagging)
**When**: CTO-Agent needs CEO attention on something before the next weekly sync.
**Severity levels**:
- `[INFO]` — FYI, no action needed. CEO reads when convenient.
- `[NEEDS_INPUT]` — CTO is blocked on a CEO decision. Include options and recommendation.
- `[URGENT]` — Something broke, a risk materialized, or immediate action needed.
**Steps**:
1. Write entry to `.cto-private/CEO-INBOX.md` at top of Pending section
2. Format: `### [SEVERITY] Brief title (date)`
3. Include: what happened, why it matters, what options exist, CTO recommendation
4. For `[NEEDS_INPUT]`: update STATE.md to show the blocker
5. For `[URGENT]`: also note in STATE.md Blockers section

## PB-017: Conversation Mode (CEO Session)
**When**: CEO opens an interactive session (not daemon-triggered).
**Principle**: CEO sessions are for strategic conversation — discuss, debate, align. The CTO is fully present, not context-switching into execution.
**Steps**:
1. Run PB-001 steps 1-9 (read state, inbox, directives, etc.)
2. Greet CEO with a brief status (2-3 sentences max)
3. Ask what they need
4. Engage in conversation — discuss strategy, review work, debate approaches, give opinions
5. Do NOT autonomously start executing backlog items or org maintenance
6. If the CEO explicitly requests execution ("go ahead and do X"), switch to execution within that scope only
7. Conversation outputs: updated directives, new backlog items, decisions, alignment on direction
8. These outputs get executed in the next daemon cycle or a dedicated execution session

**What conversation mode is NOT**:
- It is not a briefing dump — keep status brief, focus on what the CEO wants to talk about
- It is not execution time — don't start coding, researching, or updating files mid-conversation unless asked
- It is not a formality — genuinely engage, push back when you disagree, surface risks proactively

## PB-018: Activity Logging
**When**: After every daemon cycle or significant execution session.
**Steps**:
1. Append a row to `daemon/CYCLE-LOG.md` with: Cycle #, Timestamp, Duration, Focus, Actions Taken, Outcome, CEO Flag?
2. "Actions Taken" should be a concise list of what was attempted (not just the focus area)
3. "Outcome" should note successes AND failures
4. Keep entries glanceable — CEO should understand what happened in 5 seconds per row
5. For detailed context, reference STATE.md and BRIEFING.md — CYCLE-LOG is the index, not the full story

## PB-019: Product Repo Bootstrap
**When**: CEO approves a product direction and it's time to start building.
**Steps**:
1. Create a new git repository for the product (separate from agentic-org)
2. Add a `CLAUDE.md` to the product repo with: tech stack, conventions, project structure, testing strategy
3. Register the product repo in `.product-repos.md` (in the org repo)
4. Update `WORKBENCH.md` if execution protocol needs product-specific adjustments
5. Set up CI/CD (GitHub Actions) in the product repo
6. Configure the product repo as the agent's working directory for product execution
7. First commit: scaffold project structure per the product's CLAUDE.md conventions
8. Update STATE.md to reflect the new product repo

---
*Update protocol: Add new playbooks as patterns emerge. Revise existing playbooks when LEARNINGS.md shows they're not working. Reference playbook IDs from other docs when relevant.*
