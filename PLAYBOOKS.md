# Playbooks

> **5 active playbooks. Everything else is in PLAYBOOKS-ARCHIVE.md (restore anytime).**
> _Pruned 2026-02-17 per DIR-004 — 15 unused playbooks archived._

---

## PB-001: Session Startup
**When**: Any CTO-Agent session begins.
**Steps**:
0. `git pull origin main`
1. Read `STATE.md`
2. Read `CEO.md` — check your queue, what's pending from CEO
3. Read `DIRECTIVES.md`
4. Read `BACKLOG.md`
5. Check `LEARNINGS.md` if current task has relevant history
6. **CEO present**: Enter CONVERSATION MODE — brief status (2-3 sentences), ask what they need, be fully present. Do NOT auto-execute unless CEO explicitly requests it.
7. **Daemon-triggered**: Enter EXECUTION MODE — log cycle start to `daemon/CYCLE-LOG.md`, pick top backlog item, execute.

## PB-002: Completing Work
**When**: Any agent finishes a task.
**Steps**:
1. Verify output meets quality bar (tests pass, etc.)
2. Update `STATE.md` — reflect completion
3. Update `BACKLOG.md` — move item to Completed with outcome
4. Write `LEARNINGS.md` entry if anything was learned
5. Log material decisions in `DECISIONS.md`
6. Commit + `git push origin main`

## PB-014: Autonomous CTO Cycle
**When**: Daemon-triggered execution.
**Steps**:
1. Run PB-001
2. Pick highest-priority backlog item in CTO Autonomous Zone
3. Execute (use sub-agents for parallel tasks where useful)
4. Update `STATE.md`
5. Update `CEO.md` — anything pending from CEO, update "Last 10 Cycles" table
6. Append to `daemon/CYCLE-LOG.md`
7. Commit: `"Autonomous cycle #[N]: [brief summary]"` + push
8. If backlog empty: mini audit, propose work to CEO via CEO.md

## PB-017: Conversation Mode (CEO Session)
**When**: CEO opens an interactive session.
**Principle**: Sessions are for strategic conversation — discuss, debate, align. The CTO is fully present, not executing.
**Steps**:
1. Run PB-001 (startup)
2. Greet CEO with 2-3 sentence status
3. Ask what they need
4. Engage — give opinions, push back when warranted, surface risks
5. If CEO requests execution ("go do X"), execute within that scope only
6. Before session ends: run PB-020

## PB-020: Session Close Protocol
**When**: Every CTO session is ending. **Mandatory.**
**Why**: LRN-027 — lost session = lost learnings = lost work.
**Steps**:
1. Update `STATE.md` — current reality
2. Update `LEARNINGS.md` — new insights
3. Update `DECISIONS.md` — material decisions
4. Update `BACKLOG.md` — add/complete/reprioritize
5. Update `CEO.md` — pending items, last 10 cycles log
6. Update `.cto-private/THREAD.md` — session summary
7. Commit all + `git push origin main`
8. `git status` — verify clean

**Hard rule**: Nothing is done until steps 1-8 are complete.

---

_Archived playbooks (PB-003 through PB-019 minus the 5 above): see PLAYBOOKS-ARCHIVE.md_
