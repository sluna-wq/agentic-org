#!/bin/bash
# Org Daemon — Autonomous CTO Cycle
# Called by cron every 4 hours (or whatever frequency CEO configures)
# Usage: ./daemon/run-cycle.sh

set -euo pipefail

ORG_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CYCLE_LOG="$ORG_DIR/daemon/CYCLE-LOG.md"
PROMPT_FILE="$ORG_DIR/daemon/cto-cycle-prompt.md"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Get next cycle number
if grep -q "^| [0-9]" "$CYCLE_LOG" 2>/dev/null; then
    LAST_CYCLE=$(grep "^| [0-9]" "$CYCLE_LOG" | tail -1 | awk -F'|' '{print $2}' | tr -d ' ')
    CYCLE_NUM=$((LAST_CYCLE + 1))
else
    CYCLE_NUM=1
fi

echo "[$TIMESTAMP] Starting autonomous CTO cycle #$CYCLE_NUM..."

# Run the CTO cycle
cd "$ORG_DIR"
START_TIME=$(date +%s)

claude -p "$(cat "$PROMPT_FILE")

CYCLE_CONTEXT:
- Cycle #: $CYCLE_NUM
- Timestamp: $TIMESTAMP
- Mode: Autonomous (daemon)
" --dangerously-skip-permissions 2>&1 | tee "/tmp/cto-cycle-$CYCLE_NUM.log"

END_TIME=$(date +%s)
DURATION=$(( (END_TIME - START_TIME) / 60 ))

echo "[$TIMESTAMP] Cycle #$CYCLE_NUM completed in ${DURATION}m"

# Push to GitHub
echo "[$TIMESTAMP] Pushing to GitHub..."
cd "$ORG_DIR"
git push 2>&1 || echo "[$TIMESTAMP] Warning: git push failed (no remote or auth issue)"
