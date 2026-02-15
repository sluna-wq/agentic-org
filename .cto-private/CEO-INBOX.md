# CEO Inbox

> **Notifications and flags from CTO-Agent to CEO.**
> New items added at the top. CEO clears items after reading by moving them to the Archive section.
> Specialist agents: you do NOT read or write this file.

## Pending

### [INFO] BL-015 complete — dbt parser implemented + multi-repo workflow issue identified (2026-02-15)
**Good news**: dbt project parser fully implemented (ManifestParser, CatalogParser, ProjectParser) with type-safe Pydantic models, CLI commands, unit tests. BL-016 (Test Generator) is unblocked.

**Workflow issue discovered**: The multi-repo architecture (separate GitHub repos per product) doesn't work with the current daemon setup because:
1. GitHub Actions runners have ephemeral filesystems — previous cycle's work (BL-014) disappeared
2. Daemon can't create GitHub repos (no API access via ORG_PAT or GitHub App)
3. Only the org repo persists between cycles

**Adapted**: Product code now lives in `products/dbt-guardian/` (mono-repo approach) until GitHub repo creation is available. This unblocks all product work. When you add GitHub API access, we can migrate with full git history preserved.

**No action needed** unless you want to prioritize separate repos. Current approach works fine for now. See LRN-013 for full analysis.

## Archive

### [INFO] Product research complete — 4 docs ready for review (2026-02-11)
CEO reviewed 2026-02-14. Product direction confirmed: dbt Guardian, dbt Core first, Test Generator agent as first capability. See DEC-009.

### [NEEDS_INPUT] Product direction needed (2026-02-11)
The org is fully bootstrapped with all interfaces, daemon, and skills. Blocked on: what product are we building?
**Resolved**: CEO directed pre-product work — build AI agent expertise first. DIR-002 issued, backlog seeded (BL-001, BL-002, BL-003). Archived 2026-02-11.

---
*Update protocol: CTO adds items at top of Pending with severity tag: `[INFO]` (FYI), `[NEEDS_INPUT]` (blocking), `[URGENT]` (something broke). CEO clears by moving to Archive. CTO reads on every session startup to check for CEO responses. See PB-016.*
