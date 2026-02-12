# Daemon — The Org's Heartbeat

## What This Is

The org runs autonomously in the cloud. Every 4 hours, GitHub Actions fires a workflow that runs the CTO-Agent via the Claude Agent SDK. The agent reads STATE.md, picks up the highest-priority work, executes it, commits changes, updates all org docs, and logs what it did. Then the session ends. 4 hours later, it happens again.

**You wake up, open the repo, and work got done overnight.** Commits are there. STATE.md is updated. CYCLE-LOG.md shows what happened. `daemon/health.json` tells you if the org is alive.

## Architecture (DEC-008)

```
Two doors into the same org:

CEO (interactive)                    Daemon (autonomous)
┌────────────────────┐              ┌──────────────────────────┐
│ Claude Code CLI    │              │ GitHub Actions (cron)    │
│ on your machine    │              │ every 4 hours            │
│                    │              │   → SDK harness (TS)     │
│ You ↔ CTO-Agent   │              │     → Claude Agent SDK   │
│ Conversation mode  │              │       → Anthropic API    │
│                    │              │     → git commit + push  │
└────────┬───────────┘              └────────────┬─────────────┘
         │                                       │
         └───────────── Git Repo ────────────────┘
                    (the org lives here)
```

**The org is the repo.** Both doors read and write the same files. The repo is the only persistent thing. Everything else — the CLI session, the GitHub runner, the API call — is temporary.

## What Happens Each Cycle

```
GitHub Actions cron fires (every 4 hours at :17)
  → Ubuntu runner spins up
    → Checks out repo
    → Installs Claude Agent SDK
    → Runs daemon/harness/run-cycle.ts
      → Harness reads cycle prompt, injects cycle context
      → SDK creates agent session (calls Anthropic API)
        → Agent reads STATE.md, DIRECTIVES.md, BACKLOG.md, CEO-INBOX.md
        → Picks highest-priority item within Autonomous Zone
        → Executes work (reads/writes files, runs commands)
        → Updates STATE.md, BRIEFING.md, CYCLE-LOG.md
        → Flags CEO-INBOX.md if CEO input needed
        → Commits: "Autonomous cycle #N: [summary]"
      → SDK returns structured result (cost, tokens, turns, duration)
    → Harness writes health.json + cycle report
    → Harness commits report artifacts
    → Workflow pushes all commits to GitHub
  → Runner is destroyed
```

## Harness: What It Does

The SDK harness (`daemon/harness/run-cycle.ts`) wraps the Claude Agent SDK with:

- **Cost tracking**: Every cycle reports API spend. Hard cap at $2/cycle.
- **Turn limits**: Max 50 turns per cycle to prevent runaway sessions.
- **Health file**: `daemon/health.json` — last cycle status, cost, duration, consecutive failures.
- **Cycle reports**: `daemon/reports/cycle-N.json` — detailed per-cycle telemetry.
- **Concurrency safety**: GitHub Actions `concurrency` group prevents overlapping cycles.
- **Git ops**: Harness commits its own artifacts (report, health) after the agent commits its work.

## Logs & Observability

| File | What | Updated |
|------|------|---------|
| `daemon/CYCLE-LOG.md` | Human-readable index of all cycles | Each cycle (by agent) |
| `daemon/health.json` | Machine-readable liveness status | Each cycle (by harness) |
| `daemon/reports/cycle-N.json` | Detailed telemetry per cycle | Each cycle (by harness) |
| GitHub Actions logs | Full stdout/stderr of each run | Each cycle (by GitHub) |

**How to tell if the org is alive**: Check `daemon/health.json`. If `last_timestamp` is more than 5 hours old, something is wrong. If `consecutive_failures` > 0, the daemon is running but cycles are failing.

## CEO Setup (One-Time)

### Step 1: Add secrets to GitHub repo

Go to: `https://github.com/sluna-wq/agentic-org/settings/secrets/actions`

Add two repository secrets:

| Secret | Value | How to get it |
|--------|-------|---------------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key | https://console.anthropic.com/settings/keys |
| `ORG_PAT` | GitHub Personal Access Token (with `repo` scope) | https://github.com/settings/tokens → Generate new token (classic) → check `repo` scope |

### Step 2: Verify

After pushing this code and adding secrets:

1. Go to: `https://github.com/sluna-wq/agentic-org/actions`
2. Click "Autonomous CTO Cycle" workflow
3. Click "Run workflow" → "Run workflow" (manual trigger)
4. Watch the run. It should complete in ~10-20 minutes.
5. Check: `daemon/CYCLE-LOG.md`, `daemon/health.json`, and `git log` for results.

### Step 3: Done

The workflow runs automatically every 4 hours. You don't need to do anything else. Check GitHub periodically to see what the org did.

## Control

```bash
# Trigger a cycle manually (from GitHub web UI)
# Go to Actions → Autonomous CTO Cycle → Run workflow

# Or via CLI:
gh workflow run daemon-cycle.yml

# View recent runs:
gh run list --workflow=daemon-cycle.yml

# View a specific run's logs:
gh run view <run-id> --log
```

## Cost Model

- **Compute**: Free (GitHub Actions free tier for public repos, ~$4/mo for private)
- **API credits**: ~$0.50-2.00 per cycle (depends on work complexity). Budget cap: $2/cycle.
- **At 6 cycles/day**: ~$3-12/day in API costs = ~$90-360/month
- **Storage**: Negligible (text files + git)

## Legacy: Local Daemon (MacBook)

The original `run-cycle.sh` and launchd setup still work for local development. The cloud deployment supersedes this for production use. See `run-cycle.sh` for the local version.
