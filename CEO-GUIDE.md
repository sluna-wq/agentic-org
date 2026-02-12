# CEO Guide

> **Your quick reference for interacting with the org.**
> Bookmark this file. It's always up to date.

## Commands

Type these in any Claude Code session inside `agentic-org/`:

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/cto` | CTO gives you a 30-second status briefing and asks what you need | Quick check-in, give ad-hoc direction, ask questions |
| `/status` | Renders an org dashboard (phase, active work, team, health, blockers) | See what's happening at a glance |
| `/sync` | CTO preps and presents the weekly sync (roadmap, decisions, proposals, risks, next week plan) | Weekly alignment meeting |

## Ways to Interact

### Just open Claude Code and talk
Open a terminal in `agentic-org/` and start a Claude Code session. CLAUDE.md ensures you're talking to the CTO. Say whatever you need — give direction, ask questions, review work, think out loud.

### Give direction
- **In conversation**: Tell the CTO what you want. They'll translate it into directives, backlog items, and execution.
- **Persistently**: Write to `DIRECTIVES.md` directly. Directives survive between sessions and constrain all org behavior.

### See what's been happening
- **Quick**: Use `/status` for a dashboard
- **Narrative**: Read `BRIEFING.md` for the CTO's latest report
- **Autonomous work**: Check `daemon/CYCLE-LOG.md` to see what the daemon did
- **Git history**: Run `git log --oneline` to see all commits (autonomous ones say "Autonomous cycle #N")

### Private conversation with CTO
Anything you say in a session is already private (only the CTO reads it). For persistent private notes:
- Write to `.cto-private/THREAD.md` — the CTO reads this every session
- The CTO flags you at `.cto-private/CEO-INBOX.md` when something needs your attention

### Weekly sync
Type `/sync`. The CTO will prep a structured review: roadmap status, decisions made, proposals for you, risks, and next week's plan. You discuss, adjust priorities, and the CTO updates everything.

## Key Files (Where to Find Things)

| File | What's In It |
|------|-------------|
| `STATE.md` | Live dashboard — where things stand right now |
| `BRIEFING.md` | CTO's narrative report + weekly sync prep |
| `BACKLOG.md` | What's queued up to be done |
| `DIRECTIVES.md` | Your standing orders to the org |
| `DECISIONS.md` | Log of every decision and why |
| `LEARNINGS.md` | What the org learned from experience |
| `ROSTER.md` | Who's in the org, capabilities, gaps |
| `.cto-private/CEO-INBOX.md` | CTO's flags and notifications for you |
| `daemon/CYCLE-LOG.md` | Log of every autonomous cycle |

## GitHub

The org is on GitHub as a public repo. Every commit gets pushed automatically — both from interactive sessions and daemon cycles.

- **View online**: Check the repo on GitHub to see commits, files, and history from anywhere
- **Clone elsewhere**: Anyone can clone the repo to run their own instance or review the org structure

## The Daemon (Background Ops)

The org runs autonomously every 4 hours via `launchd`. No terminal window needed. It picks up the highest-priority backlog item, does the work, commits, and logs what it did. You see the results next time you check in.

- **Pause**: `launchctl unload ~/Library/LaunchAgents/com.agentic-org.daemon.plist`
- **Resume**: `launchctl load ~/Library/LaunchAgents/com.agentic-org.daemon.plist`
- **Run now**: `cd ~/Desktop/claude/agentic-org && ./daemon/run-cycle.sh`
- **Check logs**: `cat /tmp/org-daemon.log | tail -50`

---
*Update protocol: CTO-Agent updates this file whenever new commands, skills, or interaction patterns are added. Reviewed during PB-013 (Quarterly Self-Audit).*
