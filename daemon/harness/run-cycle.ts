/**
 * CTO-Agent Autonomous Cycle — SDK Harness
 *
 * This is the org's execution runtime. It wraps the Claude Agent SDK
 * with cost tracking, health checks, structured logging, and git ops.
 *
 * Architecture:
 *   GitHub Actions (scheduler) → this script (harness) → Claude Agent SDK (agent) → Anthropic API (brain)
 *
 * What this harness owns:
 *   - Cycle numbering and timestamps
 *   - Cost tracking and budget limits
 *   - Structured logging (cycle-report.json)
 *   - Git commit with standardized message
 *   - Error handling and graceful failure
 *
 * What the SDK owns:
 *   - The agent loop (prompt → tool calls → responses)
 *   - File reading/writing/editing
 *   - Bash execution
 *   - Context management
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";

// ─── Configuration ──────────────────────────────────────────────────────────

const ORG_DIR = path.resolve(__dirname, "../..");
const CYCLE_LOG = path.join(ORG_DIR, "daemon/CYCLE-LOG.md");
const CYCLE_PROMPT = path.join(ORG_DIR, "daemon/cto-cycle-prompt.md");
const REPORT_DIR = path.join(ORG_DIR, "daemon/reports");

const MAX_TURNS = 50;           // Hard cap on agent turns per cycle
const MAX_BUDGET_USD = 2.00;    // Hard cap on API spend per cycle
const MODEL = "sonnet";         // Default model for autonomous cycles

// ─── Helpers ────────────────────────────────────────────────────────────────

function getNextCycleNumber(): number {
  try {
    const log = fs.readFileSync(CYCLE_LOG, "utf-8");
    const rows = log.split("\n").filter((line) => /^\| \d+/.test(line));
    if (rows.length === 0) return 1;
    const lastRow = rows[rows.length - 1];
    const lastNum = parseInt(lastRow.split("|")[1].trim(), 10);
    return lastNum + 1;
  } catch {
    return 1;
  }
}

function timestamp(): string {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

function gitCommit(message: string): void {
  try {
    execSync("git add -A", { cwd: ORG_DIR, stdio: "pipe" });
    // Check if there are changes to commit
    try {
      execSync("git diff --cached --quiet", { cwd: ORG_DIR, stdio: "pipe" });
      console.log("No changes to commit");
    } catch {
      // diff --quiet exits non-zero when there ARE changes — that's what we want
      execSync(`git commit -m "${message}\n\nCo-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"`, {
        cwd: ORG_DIR,
        stdio: "pipe",
      });
      console.log(`Committed: ${message}`);
    }
  } catch (err) {
    console.error("Git commit failed:", err);
  }
}

// ─── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const cycleNum = getNextCycleNumber();
  const startTime = Date.now();
  const startTs = timestamp();

  console.log(`\n${"=".repeat(60)}`);
  console.log(`  Autonomous CTO Cycle #${cycleNum}`);
  console.log(`  Started: ${startTs}`);
  console.log(`  Model: ${MODEL} | Max turns: ${MAX_TURNS} | Budget: $${MAX_BUDGET_USD}`);
  console.log(`${"=".repeat(60)}\n`);

  // Read the cycle prompt
  const promptTemplate = fs.readFileSync(CYCLE_PROMPT, "utf-8");
  const prompt = `${promptTemplate}

CYCLE_CONTEXT:
- Cycle #: ${cycleNum}
- Timestamp: ${startTs}
- Mode: Autonomous (daemon — GitHub Actions)
- Budget limit: $${MAX_BUDGET_USD} per cycle
- Turn limit: ${MAX_TURNS} turns

IMPORTANT: Do NOT run git push — the harness handles that. Do commit your changes with: git add -A && git commit -m "Autonomous cycle #${cycleNum}: [brief summary]"
`;

  // Run the agent
  let result: string | undefined;
  let cost: number = 0;
  let usage: any = {};
  let turns: number = 0;
  let durationMs: number = 0;
  let error: string | undefined;
  let subtype: string = "unknown";

  try {
    for await (const message of query({
      prompt,
      options: {
        cwd: ORG_DIR,
        model: MODEL,
        maxTurns: MAX_TURNS,
        maxBudgetUsd: MAX_BUDGET_USD,
        permissionMode: "bypassPermissions",
        allowDangerouslySkipPermissions: true,
        settingSources: ["project"],  // Load CLAUDE.md
      },
    })) {
      if (message.type === "assistant") {
        // Log agent activity as it streams
        process.stdout.write(".");
      }

      if (message.type === "result") {
        subtype = message.subtype;
        if (message.subtype === "success") {
          result = message.result;
          cost = message.total_cost_usd ?? 0;
          usage = message.usage ?? {};
          turns = message.num_turns ?? 0;
          durationMs = message.duration_ms ?? 0;
        } else {
          // Agent hit a limit or errored
          error = `Agent ended with: ${message.subtype}`;
          cost = message.total_cost_usd ?? 0;
          usage = message.usage ?? {};
          turns = message.num_turns ?? 0;
          durationMs = message.duration_ms ?? 0;
          if (message.subtype === "success") {
            result = message.result;
          }
        }
      }
    }
  } catch (err: any) {
    error = `SDK exception: ${err.message}`;
    console.error("\nAgent crashed:", err.message);
  }

  const endTime = Date.now();
  const wallDurationMin = Math.round((endTime - startTime) / 60000);

  console.log(`\n\n${"=".repeat(60)}`);
  console.log(`  Cycle #${cycleNum} ${error ? "FAILED" : "COMPLETE"}`);
  console.log(`  Duration: ${wallDurationMin}min | Turns: ${turns} | Cost: $${cost.toFixed(4)}`);
  console.log(`  Tokens: ${JSON.stringify(usage)}`);
  if (error) console.log(`  Error: ${error}`);
  console.log(`${"=".repeat(60)}\n`);

  // ─── Write structured report ────────────────────────────────────────────

  fs.mkdirSync(REPORT_DIR, { recursive: true });
  const report = {
    cycle: cycleNum,
    timestamp: startTs,
    duration_minutes: wallDurationMin,
    duration_api_ms: durationMs,
    model: MODEL,
    turns,
    cost_usd: cost,
    usage,
    status: error ? "error" : "success",
    subtype,
    error: error ?? null,
    result_summary: result?.slice(0, 500) ?? null,
  };

  const reportPath = path.join(REPORT_DIR, `cycle-${cycleNum}.json`);
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`Report written: ${reportPath}`);

  // ─── Write health file (latest cycle status for monitoring) ─────────────

  const healthPath = path.join(ORG_DIR, "daemon/health.json");
  const health = {
    last_cycle: cycleNum,
    last_timestamp: startTs,
    last_status: error ? "error" : "success",
    last_cost_usd: cost,
    last_duration_minutes: wallDurationMin,
    last_turns: turns,
    consecutive_failures: 0,  // TODO: read previous health and increment
  };

  // Read previous health to track consecutive failures
  try {
    const prev = JSON.parse(fs.readFileSync(healthPath, "utf-8"));
    if (error) {
      health.consecutive_failures = (prev.consecutive_failures ?? 0) + 1;
    }
  } catch {
    // No previous health file — first cycle
    if (error) health.consecutive_failures = 1;
  }

  fs.writeFileSync(healthPath, JSON.stringify(health, null, 2));

  // ─── Git commit the report and health file ──────────────────────────────
  // (The agent should have already committed its own work.
  //  This catches the harness artifacts — report + health.)

  gitCommit(`Cycle #${cycleNum} harness report [${error ? "FAILED" : "OK"}, $${cost.toFixed(4)}, ${wallDurationMin}min]`);

  // Exit with error code if the cycle failed
  if (error) {
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("Harness fatal error:", err);
  process.exit(1);
});
