# Daemon Setup — The Org's Heartbeat

This directory enables the org to run autonomously without CEO prompting.

## How It Works
A cron job runs `run-cycle.sh` every 4 hours. The script invokes Claude Code with the CTO cycle prompt. The CTO-Agent reads org state, does the highest-priority work, updates all artifacts, and logs the cycle.

## One-Time Setup (macOS)

### Option 1: crontab (simplest)
```bash
# Open crontab editor
crontab -e

# Add this line (runs every 4 hours):
0 */4 * * * cd /Users/santiagoluna/Desktop/claude/agentic-org && ./daemon/run-cycle.sh >> /tmp/org-daemon.log 2>&1

# Save and exit
```

### Option 2: launchd (recommended for macOS — survives reboots)
```bash
# Create the plist file
cat > ~/Library/LaunchAgents/com.agentic-org.daemon.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.agentic-org.daemon</string>
    <key>ProgramArguments</key>
    <array>
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
</dict>
</plist>
EOF

# Load it
launchctl load ~/Library/LaunchAgents/com.agentic-org.daemon.plist
```

### Verify It's Running
```bash
# Check launchd
launchctl list | grep agentic-org

# Check cron
crontab -l

# Check logs
tail -f /tmp/org-daemon.log
```

### Changing Frequency
- **Every 2 hours** (shipping mode): Change `StartInterval` to `7200` or cron to `0 */2 * * *`
- **Every 8 hours** (planning mode): Change `StartInterval` to `28800` or cron to `0 */8 * * *`
- **Pause the daemon**: `launchctl unload ~/Library/LaunchAgents/com.agentic-org.daemon.plist`

### Manual Trigger
Run a cycle manually anytime:
```bash
cd /Users/santiagoluna/Desktop/claude/agentic-org && ./daemon/run-cycle.sh
```

## Cycle Logs
Check `daemon/CYCLE-LOG.md` for a summary of every autonomous cycle.
