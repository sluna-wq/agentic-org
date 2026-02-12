# Daemon — The Org's Heartbeat

## What This Is

The org runs autonomously in the background. Every 4 hours, a cron job on your machine fires `run-cycle.sh`, which starts a Claude Code session. That session *is* the CTO — it reads STATE.md, picks up the highest-priority work, executes it, commits changes, updates all org docs, and logs what it did. Then the session ends. 4 hours later, it happens again.

**You wake up, open the repo, and work got done overnight.** Commits are there. STATE.md is updated. CYCLE-LOG.md shows what happened.

## Where It Runs

The daemon needs a machine that's on and connected to the internet.

### Option A: Your MacBook (Start Here)
- Simplest. Use launchd (below). The org runs while your laptop is open.
- **Limitation**: Org sleeps when your laptop sleeps. Fine for getting started.

### Option B: Always-On Machine (Recommended for Production)
- A Mac Mini, Linux server, or cloud VM that's always running.
- Same setup as below, but on a machine that never sleeps.
- The org is truly alive 24/7.

### Option C: GitHub Actions (Future)
- Push this repo to GitHub. Use a scheduled workflow to run the daemon in CI.
- Requires: GitHub repo, Claude Code installed in the workflow, API key as a secret.
- No dependency on any physical machine. Cloud-native.
- We'll set this up when we have a product and a GitHub repo.

## Who Commits?

When the daemon runs, Claude Code commits under your git identity (the one configured on the machine). Every autonomous commit follows this format:

```
Autonomous cycle #47: implemented login endpoint

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

You can always tell which commits were autonomous (they say "Autonomous cycle #N") vs. interactive (your normal session commits).

## One-Time Setup

### Step 1: Set up launchd (runs every 4 hours, survives reboots)

Copy and paste this entire block into your terminal:

```bash
cat > ~/Library/LaunchAgents/com.agentic-org.daemon.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.agentic-org.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/santiagoluna/Desktop/claude/agentic-org/daemon/run-cycle.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>14400</integer>
    <key>WorkingDirectory</key>
    <string>/Users/santiagoluna/Desktop/claude/agentic-org</string>
    <key>StandardOutPath</key>
    <string>/tmp/org-daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/org-daemon-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.agentic-org.daemon.plist
```

### Step 2: Verify

```bash
# Check it's registered
launchctl list | grep agentic-org

# Watch logs (Ctrl+C to stop)
tail -f /tmp/org-daemon.log
```

### Step 3: Run the first cycle manually to test

```bash
cd /Users/santiagoluna/Desktop/claude/agentic-org && ./daemon/run-cycle.sh
```

Then check `daemon/CYCLE-LOG.md` and `git log` to see the results.

## Control

```bash
# Pause the daemon
launchctl unload ~/Library/LaunchAgents/com.agentic-org.daemon.plist

# Resume the daemon
launchctl load ~/Library/LaunchAgents/com.agentic-org.daemon.plist

# Run a cycle right now (doesn't affect the schedule)
cd /Users/santiagoluna/Desktop/claude/agentic-org && ./daemon/run-cycle.sh

# Change frequency to every 2 hours (shipping mode)
# Edit the plist: change <integer>14400</integer> to <integer>7200</integer>
# Then: launchctl unload ... && launchctl load ...

# Check recent cycle output
cat /tmp/org-daemon.log | tail -50
```

## What Happens Each Cycle

```
cron fires (every 4 hours)
  → run-cycle.sh starts
    → claude -p with CTO cycle prompt
      → CTO reads STATE.md, DIRECTIVES.md, BACKLOG.md, CEO-INBOX.md
      → Picks highest-priority backlog item within Autonomous Zone
      → Executes the work (writes code, updates docs, etc.)
      → Updates STATE.md (active work, current cycle, last activity)
      → Updates BRIEFING.md if meaningful progress
      → Flags CEO-INBOX.md if CEO input needed
      → Commits everything: "Autonomous cycle #N: [summary]"
      → Appends to CYCLE-LOG.md
    → Session ends
  → run-cycle.sh logs duration
```

## Logs

- **Cycle log** (what the org did): `daemon/CYCLE-LOG.md`
- **Raw output** (full session transcript): `/tmp/cto-cycle-[N].log`
- **Daemon system log**: `/tmp/org-daemon.log`
- **Daemon errors**: `/tmp/org-daemon-error.log`

## Cloud Deployment (Future — BL-013)

The org can run headless in the cloud, accessible from your phone.

### Architecture
```
Cloud VM (AWS EC2 / DigitalOcean / GCP)
├── Claude Code CLI installed
├── Git repo cloned
├── Cron or systemd timer triggers cycles
└── Pushes commits → GitHub

CEO interacts via:
├── GitHub mobile app (read commits, files, inbox)
├── GitHub web UI (full experience)
└── SSH to VM for interactive sessions (optional)
```

### Cost Model
- **Compute**: $5-10/month (small VM — daemon runs briefly every few hours)
- **API credits**: The real cost. Determined by cycle frequency and work complexity.
- **Storage**: Negligible (text files + git)

### What Changes
- Same `run-cycle.sh`, same prompts, same org structure
- Just runs on a machine that never sleeps
- Git is the communication channel — daemon pushes, CEO reviews on GitHub

### Implementation
Tracked as BL-013 in BACKLOG.md. Will implement when the org needs 24/7 operation.
