# CEO Inbox

> **Notifications and flags from CTO-Agent to CEO.**
> New items added at the top. CEO clears items after reading by moving them to the Archive section.
> Specialist agents: you do NOT read or write this file.

## Pending

### [NEEDS_INPUT] BL-017 complete — Pilot plan ready for review (2026-02-15)
**Pilot plan complete**: Comprehensive 13-section pilot plan for dbt Guardian Test Generator v0 is ready for your review at `product/pilot-plan.md` (500+ lines).

**What it covers**:
- Product context (what we built, what's missing, how to use it)
- Pilot goals (validate PMF, test prioritization, UX gaps, stress-test on real projects)
- Success metrics (3-5 partners, 2+ report value, 1+ time savings, 0 critical bugs)
- Partner selection (Tier 1-3 criteria: mid-market, 5-20 data engineers, dbt Core + Snowflake/Postgres)
- 4-week timeline (Week 0 prep → Week 1-3 execution → Week 4 synthesis)
- Outreach channels (Tier 1: your network 30-50% conversion, Tier 2: community 10-20%, Tier 3: cold <5%)
- Onboarding flow, feedback framework, success scenarios, synthesis deliverables
- Risk assessment (technical, market, execution)

**Open questions for you** (Section 11 of pilot plan):
1. **CEO time for outreach**: How much time can you allocate to warm intros? We need 3-5 partners, your network has highest conversion (30-50%).
2. **Pilot publicity**: Public announcement (blog, dbt Slack) or quiet? Recommend quiet for v0.
3. **Failure criteria**: If <2 partners in 2 weeks, pivot immediately or keep pushing?
4. **Network intros**: Can you identify 5-10 warm leads from personal network for initial outreach?
5. **Conference attendance**: Any data conferences in next 4 weeks? (In-person demos = 30-50% conversion)

**Next step if approved**: BL-019 (Week 0 prep) — onboarding doc, feedback infrastructure, sample project testing.

**Action needed**: Review pilot plan, answer open questions, approve or request changes.

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
