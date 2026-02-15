# dbt Guardian — Pilot Plan (Test Generator v0)

> **Strategic document for piloting the Test Generator agent with design partners.**
> Read before starting pilot outreach. Defines scope, success metrics, timeline, and partner selection criteria.

**Version**: 1.0
**Date**: 2026-02-15
**Status**: Draft — Ready for CEO review
**Owner**: CTO-Agent

---

## Executive Summary

**What we're piloting**: Test Generator v0 — an autonomous agent that analyzes dbt Core projects, detects test coverage gaps, and generates PR-ready schema.yml files with test suggestions.

**Why pilot now**: We have a production-quality implementation (35+ unit tests, pattern-based gap detection, beautiful CLI output). We need real-world validation before investing in PR automation and cross-stack capabilities.

**Target partners**: 3-5 mid-market data teams (5-20 engineers) running dbt Core + Snowflake/Postgres, with messy test coverage and appetite for trying early tools.

**Duration**: 4 weeks from first partner onboarded → findings synthesis.

**Success criteria**: 2+ partners use the tool on real projects, 1+ partner reports it saved meaningful time, 0 critical bugs in core analysis, validated learning about what tests to prioritize.

**Investment required**: CEO support for design partner outreach (network intros, community posts, conference hallway conversations).

---

## 1. What We Built (Product Context)

### Core Capabilities

**Test Generator v0** (completed BL-016, 2026-02-15):
- **Analyzes dbt projects**: Reads `manifest.json` + `catalog.json` to understand models, columns, existing tests, and warehouse metadata
- **Detects coverage gaps**: Pattern-based detection (ID columns → unique/not_null, timestamps → not_null, status columns → accepted_values, foreign keys → relationships)
- **Prioritizes gaps**: 1 (critical: primary keys) → 5 (low: other columns) based on column name/type patterns
- **Generates test suggestions**: Outputs PR-ready `schema.yml` with simple tests (not_null, unique) and placeholders for complex tests (accepted_values with TODO, relationships with TODO)
- **CLI interface**: `dbt-guardian analyze` (shows coverage report + top gaps), `dbt-guardian generate-tests` (creates schema.yml), `dbt-guardian info` (project metadata)
- **Quality bar**: 35+ unit tests, type-safe (mypy strict), formatted (ruff + black), documented (Google-style docstrings)

### What's NOT in v0

- **No PR automation**: User manually copies tests from generated schema.yml to their models/ directory
- **No GitHub integration**: No automated PRs, no commit/push capability
- **No dbt Cloud support**: Only works with dbt Core projects (requires local manifest.json)
- **No warehouse integration**: Can't query Snowflake/Postgres directly (relies on catalog.json from dbt docs generate)
- **No agent orchestration**: Not autonomous — user runs CLI commands manually
- **No cross-stack remediation**: dbt-only, no Airflow/Snowflake fixes

### Installation & Usage

```bash
# Install (local for pilot)
cd products/dbt-guardian
poetry install
poetry shell

# Run on a dbt project
dbt-guardian analyze /path/to/dbt/project
dbt-guardian generate-tests /path/to/dbt/project --output suggestions.yml
```

**Prerequisites for users**:
1. dbt Core project (not dbt Cloud)
2. `manifest.json` exists (run `dbt compile` or `dbt run` first)
3. Optional: `catalog.json` for warehouse column types (run `dbt docs generate`)

---

## 2. Pilot Goals

### Primary Goals

1. **Validate product-market fit hypothesis**: Do data teams with dbt Core projects care about test coverage gaps enough to use a tool like this?
2. **Validate test prioritization logic**: Are our pattern-based priorities (ID columns = high, timestamps = medium, etc.) correct? What are we missing?
3. **Identify critical UX gaps**: What's confusing? What's missing? Where do users get stuck?
4. **Stress-test on real projects**: Does the parser handle real-world dbt projects (100+ models, 1000+ columns, complex schemas)?
5. **Learn what tests users want**: Do they mostly want not_null/unique? Or do they need relationships and accepted_values? What about custom tests?

### Secondary Goals

6. **Build design partner relationships**: Identify 1-2 teams who'll stay engaged through v1 (PR automation) and v2 (cross-stack remediation)
7. **Validate "work with the data stack" positioning**: Do teams see this as complementary to dbt, or competitive?
8. **Gather distribution insights**: How do data teams discover tools? Internal tool libraries? Slack communities? Word-of-mouth?

### Explicitly NOT Goals (For This Pilot)

- **Not evaluating PR automation**: That's v0.3, not v0.1
- **Not testing dbt Cloud compatibility**: Core-first strategy is deliberate
- **Not measuring revenue/conversion**: Too early for pricing
- **Not onboarding 50+ users**: Quality over quantity — deep engagement with 3-5 teams

---

## 3. Success Metrics

### Must-Have (Pilot Success)

| Metric | Target | Measurement | Critical? |
|--------|--------|-------------|-----------|
| **Partners onboarded** | 3-5 teams | Count of teams who run the tool on real projects | ✅ Yes |
| **Successful analyses** | 2+ teams | Tool runs without errors on their full project | ✅ Yes |
| **Time-saving validation** | 1+ team | Partner reports "this saved me X hours vs manual" | ✅ Yes |
| **Zero critical bugs** | 100% | No parser crashes, no data loss, no incorrect test suggestions | ✅ Yes |
| **Findings synthesis** | 1 doc | Learnings doc with validated patterns + product roadmap adjustments | ✅ Yes |

### Nice-to-Have (Learning Velocity)

| Metric | Target | Measurement | Critical? |
|--------|--------|-------------|-----------|
| **Repeat usage** | 1+ team | Partner runs tool on multiple models or multiple times | ❌ No |
| **Feature requests** | 10+ items | Specific asks captured in product backlog | ❌ No |
| **Design partner commitment** | 2+ teams | Agree to test PR automation (v0.3) when ready | ❌ No |
| **Community visibility** | 1+ mention | Someone posts about it (Slack, LinkedIn, blog) | ❌ No |

### Red Flags (Abort Signals)

| Red Flag | Meaning | Action |
|----------|---------|--------|
| **No partners after 2 weeks outreach** | Problem isn't painful enough or positioning is wrong | Pause pilot, reassess product direction with CEO |
| **Partners install but never use** | Friction too high or value prop unclear | Fix onboarding UX before continuing |
| **Parser crashes on 50%+ of projects** | Technical assumptions are wrong | Fix parser reliability before re-engaging partners |
| **Partners say "dbt Cloud does this"** | Competitive threat misunderstood | Research dbt Labs roadmap, reassess defensibility |

---

## 4. Partner Selection Criteria

### Ideal Design Partner Profile

**Company stage**: Mid-market (50-500 employees, Series A-C)
**Team size**: 5-20 data/analytics engineers
**Data stack**: dbt Core + Snowflake or Postgres (not dbt Cloud)
**Pain point**: Known test coverage gaps, manual test authoring, or recent data quality incidents
**Tooling appetite**: Early adopters, willing to try pre-release tools
**Engagement capacity**: Can give 2-4 hours over 4 weeks (install, test, feedback calls)

### Tier 1 (Best Fit — Prioritize)

- **Teams we know personally**: CEO network, warm intros from advisors
- **Recently complained about dbt testing**: GitHub issues, Slack posts, conference talks
- **Strong technical leadership**: Senior data engineers who can evaluate quality
- **Messy projects**: 50-200 models, <30% test coverage (tool shows most value)

### Tier 2 (Good Fit — Consider)

- **Community members**: Active in dbt Slack, r/dataengineering, Locally Optimistic
- **Moderate coverage**: 30-60% tested columns (still room for improvement)
- **Multiple data engineers**: 3+ people who could use the tool

### Tier 3 (Weak Fit — Avoid for Pilot)

- **dbt Cloud users**: Not our target (Core-first strategy)
- **Tiny teams**: <3 data people (not representative of target market)
- **Perfect test coverage**: >90% tested (tool won't show value)
- **Consulting firms**: Using tool for clients (not actual end users)

### Disqualifiers

- **Competitors**: Anyone building similar tools (obvious)
- **No dbt Core**: Teams only on dbt Cloud or not using dbt
- **No bandwidth**: Can't commit 2-4 hours over 4 weeks
- **Toxic culture**: Rude, demanding, or inappropriate (life's too short)

---

## 5. Pilot Timeline

**Total duration**: 4 weeks from first partner onboarded → synthesis complete
**Prep phase**: 1 week (pre-pilot)
**Execution phase**: 4 weeks (partner onboarding + feedback)
**Synthesis phase**: 3 days (post-pilot)

### Week 0 (Prep — Before First Partner)

**Goal**: Make pilot-ready artifacts
**Owner**: CTO-Agent

- [x] Complete this pilot plan (BL-017) — **you are here**
- [ ] Create pilot onboarding doc (`product/pilot-onboarding.md`):
  - Installation instructions (local setup, not PyPI)
  - Quick-start guide (5-minute first run)
  - Usage examples (analyze → generate-tests → copy to models/)
  - Known limitations (no PR automation, no dbt Cloud, etc.)
  - Feedback channels (email, Slack, GitHub issues)
- [ ] Set up feedback infrastructure:
  - GitHub Discussions for pilot partners (private repo access)
  - Google Doc template for pilot interview notes
  - Slack channel or email alias for questions
- [ ] Test on sample dbt project:
  - Find 1-2 open-source dbt projects (jaffle_shop, GitLab's data model)
  - Run analyze + generate-tests
  - Validate output quality (no crashes, sensible suggestions)
- [ ] CEO review + approval of pilot plan

**Output**: Pilot-ready package (tool + onboarding doc + feedback channel)
**Timeline**: 3-5 days (assuming CEO approval is quick)

### Week 1 (Outreach + First Partners)

**Goal**: Onboard 1-2 partners
**Owner**: CEO (outreach), CTO-Agent (support)

**CEO actions**:
- [ ] Identify 5-10 warm leads from network
- [ ] Send personalized outreach emails (pitch: "early tool for dbt test coverage, would love your feedback")
- [ ] Post in dbt Community Slack #tools-and-utilities (if allowed)
- [ ] Reach out to Locally Optimistic Slack (data leadership community)

**CTO-Agent actions**:
- [ ] Respond to questions from interested teams (installation, prerequisites, scope)
- [ ] Send onboarding doc when partner confirms interest
- [ ] Schedule 30-min kickoff call (optional, for engaged partners)
- [ ] Monitor for install blockers or early bugs

**Exit criteria**: 1-2 teams successfully run `dbt-guardian analyze` on their project

### Week 2-3 (Scale to 3-5 Partners + Usage)

**Goal**: Get to 3-5 active partners, collect first feedback
**Owner**: CEO (outreach), CTO-Agent (support + interviews)

**CEO actions**:
- [ ] Continue outreach if <3 partners (conference hallway conversations, LinkedIn posts)
- [ ] Engage existing partners (check-in emails, thank-you notes)

**CTO-Agent actions**:
- [ ] Support partners as they test (answer questions, debug parser issues)
- [ ] Schedule 20-min feedback calls after first usage (async if needed)
- [ ] Capture feedback in Google Doc per partner:
  - What worked? What was confusing?
  - Were test priorities correct? What did they change?
  - Did they actually copy tests into their project? Why/why not?
  - What's missing? What would make this 10x more valuable?
  - Would they use this again? Would they pay for it?
- [ ] Fix critical bugs (parser crashes, incorrect output) within 24 hours
- [ ] Log all feedback in `product/pilot-feedback.md` (anonymized)

**Exit criteria**: 2+ partners have used the tool on real projects, 2+ feedback calls completed

### Week 4 (Final Feedback + Synthesis)

**Goal**: Close out pilot, synthesize learnings
**Owner**: CTO-Agent

**Actions**:
- [ ] Final feedback calls with all partners (async survey if calls fail)
- [ ] Send thank-you notes + offer of early access to v0.3 (PR automation)
- [ ] Compile all feedback into synthesis doc (`product/pilot-synthesis.md`):
  - What worked (validated assumptions)
  - What didn't work (invalidated assumptions)
  - Critical bugs found and fixed
  - Feature requests (prioritized by frequency + impact)
  - Product roadmap adjustments (what to build next)
  - Design partner retention (who's staying engaged)
- [ ] Update BACKLOG.md with post-pilot priorities
- [ ] CEO briefing on findings (PB-010)

**Output**: `product/pilot-synthesis.md` + updated product roadmap
**Timeline**: 3 days (intensive synthesis work)

---

## 6. Design Partner Outreach Channels

### Tier 1 (Warm Network — Highest Conversion)

**Channel**: CEO personal network
**Tactic**: Personalized 1-1 emails/LinkedIn DMs to data leaders
**Message**: "Building a tool to help dbt teams find test coverage gaps. You came to mind because [specific reason]. Would you or your team be open to trying an early version and giving feedback? 30 minutes of your time, no strings attached."
**Expected yield**: 30-50% positive response (if targets are well-chosen)
**Owner**: CEO

**Channel**: Advisor/investor intros
**Tactic**: Ask advisors/investors to introduce to portfolio companies with data teams
**Message**: "[Advisor name] suggested I reach out — we're piloting a dbt test coverage tool, and I'd love to get your team's feedback."
**Expected yield**: 20-40% positive response (warm intros work)
**Owner**: CEO

### Tier 2 (Community — Medium Conversion)

**Channel**: dbt Community Slack (#tools-and-utilities, #advice-dbt-for-beginners)
**Tactic**: Post about pilot with call for design partners
**Message**: "We're piloting a CLI tool that analyzes dbt projects and suggests missing tests (not_null, unique, etc.). Looking for 3-5 teams running dbt Core to try it and give feedback. DM me if interested!"
**Expected yield**: 10-20% of responders become active partners (high interest, low commitment)
**Owner**: CEO (post), CTO-Agent (DM responses)

**Channel**: Locally Optimistic Slack (data leadership community)
**Tactic**: Post in #data-engineering or #tools
**Message**: Similar to dbt Slack, but emphasize leadership angle ("help us validate if this is worth building")
**Expected yield**: 10-20% conversion
**Owner**: CEO

**Channel**: r/dataengineering, r/BusinessIntelligence
**Tactic**: Reddit post with demo GIF or screenshot
**Message**: "Built a tool to find dbt test coverage gaps — looking for feedback from dbt Core users. Open to suggestions!"
**Expected yield**: 5-10% conversion (Reddit is noisy, low signal)
**Owner**: CTO-Agent (can handle async Reddit engagement)

### Tier 3 (Cold Outreach — Low Conversion, High Effort)

**Channel**: LinkedIn posts (CEO's profile)
**Tactic**: Post about building in public, looking for design partners
**Expected yield**: <5% conversion (visibility play, not conversion play)
**Owner**: CEO

**Channel**: Data Twitter/X (if CEO is active)
**Tactic**: Thread about the problem, invite DMs
**Expected yield**: <5% conversion
**Owner**: CEO

**Channel**: Conference hallway conversations (dbt Coalesce, Data Council, etc.)
**Tactic**: In-person demos at conferences (if CEO attends)
**Expected yield**: 30-50% conversion for in-person demos (but requires conference attendance)
**Owner**: CEO

### Tier 4 (Avoid for Pilot — Too Slow or Wrong Audience)

**Channel**: Cold email lists (purchased, scraped, or enriched)
**Why avoid**: Low quality, spammy, wastes goodwill
**Owner**: N/A

**Channel**: Paid ads (LinkedIn, Google)
**Why avoid**: Expensive, unproven messaging, too early for paid acquisition
**Owner**: N/A

**Channel**: Product Hunt, Hacker News
**Why avoid**: Launch tactics, not pilot tactics. Creates visibility but rarely converts to engaged design partners (too many tire-kickers)
**Owner**: N/A

---

## 7. Pilot Onboarding Flow (Partner Journey)

### Step 1: Outreach → Interest

**Trigger**: CEO sends email or DM
**Goal**: Get "yes, I'm interested"
**CTO-Agent action**: None (CEO-led)

### Step 2: Interest → Onboarded

**Trigger**: Partner replies "yes"
**Goal**: Partner successfully installs and runs `dbt-guardian analyze`
**Timeline**: 1-3 days

**CTO-Agent sends**:
1. Welcome email with onboarding doc (`product/pilot-onboarding.md`)
2. Installation instructions (local setup via Poetry)
3. Prerequisites checklist (dbt Core, manifest.json, catalog.json optional)
4. Example usage (analyze → generate-tests → copy suggestions)
5. Known limitations (no PR automation, no dbt Cloud)
6. Feedback channel (email, GitHub Discussions, Slack)

**CTO-Agent monitors**:
- Installation issues (Python version, Poetry errors, missing dependencies)
- Questions about prerequisites (how to generate manifest.json)
- First successful run (partner reports results)

**Success metric**: Partner runs `dbt-guardian analyze` on their project within 3 days

### Step 3: Onboarded → Active Usage

**Trigger**: Partner runs analyze successfully
**Goal**: Partner generates tests, copies some into their project
**Timeline**: 1-7 days

**CTO-Agent actions**:
- Send follow-up: "How'd it go? Did the suggestions make sense?"
- Offer 20-min feedback call (optional)
- Debug any parser errors or incorrect suggestions

**Success metric**: Partner runs `generate-tests` and reports back (even if they didn't copy tests)

### Step 4: Active Usage → Feedback

**Trigger**: Partner has used the tool 1-2 times
**Goal**: Capture detailed feedback
**Timeline**: Week 2-3 of pilot

**CTO-Agent actions**:
- Schedule 20-min feedback call (or send async survey if scheduling fails)
- Ask structured questions:
  1. What worked well?
  2. What was confusing or frustrating?
  3. Were the test priorities correct? What would you change?
  4. Did you copy tests into your project? Why or why not?
  5. What's missing to make this 10x more valuable?
  6. Would you use this again? Would you pay for it?
- Document answers in `product/pilot-feedback.md`

**Success metric**: Completed feedback call or survey

### Step 5: Feedback → Retention

**Trigger**: Pilot ends (Week 4)
**Goal**: Keep engaged partners warm for v0.3 (PR automation)
**Timeline**: End of pilot

**CTO-Agent actions**:
- Send thank-you email
- Share pilot synthesis highlights (anonymized)
- Offer early access to next version (PR automation)
- Ask if they want to stay engaged

**Success metric**: 2+ partners say "yes, keep me posted"

---

## 8. Feedback Collection Framework

### What We're Learning

**Technical validation**:
- Does the parser handle real-world dbt projects? (Edge cases, performance, errors)
- Are test suggestions correct? (False positives, false negatives)
- Are priorities accurate? (Do users agree with our 1-5 scoring?)

**UX validation**:
- Is installation frictionless? (Poetry setup, dependency issues)
- Is CLI output clear? (Rich tables, coverage stats, rationale)
- Is the workflow intuitive? (analyze → generate-tests → copy to models/)

**Value validation**:
- Does this save time vs manual test authoring?
- Do teams actually use the generated tests?
- What tests are most valuable? (not_null, unique, accepted_values, relationships, custom)

**Strategic validation**:
- Do teams see this as complementary to dbt, or competitive?
- What's the next most painful problem after test coverage?
- Would teams pay for this? How much? Per-seat, per-project, enterprise?

### Feedback Questions (Structured Interview)

**Opening** (5 min):
- Tell me about your team and dbt setup (Core vs Cloud, warehouse, project size, team size)
- How do you currently handle dbt test coverage? (Manual authoring, no tests, automated, other)
- What made you interested in trying dbt Guardian?

**Installation & Setup** (5 min):
- How was the installation experience? (Any blockers?)
- Did you have manifest.json and catalog.json ready? (Or did you generate them?)
- How long did it take from install to first successful run?

**Usage & Output** (10 min):
- Walk me through what you did (analyze, generate-tests, etc.)
- What did you think of the coverage report? (Accuracy, usefulness)
- Were the test suggestions correct? (Any false positives or missing suggestions?)
- Did the priority scoring make sense? (Would you change any priorities?)
- Did you copy any tests into your project? (Why or why not? Which tests?)

**Value & Pain Points** (5 min):
- Did this save you time vs writing tests manually? (How much time?)
- What's the most valuable part of the tool? (Gap detection, YAML generation, priorities, other)
- What's the most frustrating part? (UX, output, limitations)
- What would make this 10x more valuable? (PR automation, dbt Cloud support, custom test patterns, other)

**Future Engagement** (5 min):
- Would you use this again? (If so, how often? Per sprint? Per month?)
- Would you pay for this? (If so, how much? Per-seat? Per-project?)
- Would you be interested in testing PR automation (v0.3)? (We'd auto-create PRs with test suggestions)
- Can I follow up in a few weeks with pilot findings?

**Closing**:
- Anything else you'd like to share?
- Thank you! (Offer early access to future versions)

### Feedback Documentation

**Format**: Google Doc per partner (private, internal only)
**Filename**: `Pilot Feedback — [Partner Company] — [Date]`

**Template**:
```
# Pilot Feedback — [Partner Company]

**Date**: [YYYY-MM-DD]
**Interviewer**: CTO-Agent
**Partner contact**: [Name, Title]
**Company**: [Company name]
**Team size**: [N data engineers]
**Data stack**: [dbt Core + Snowflake/Postgres/etc]
**Project size**: [N models, N columns]

---

## Installation & Setup
- [Notes on installation experience]

## Usage & Output
- [Notes on what they did, what worked, what didn't]

## Test Suggestions & Priorities
- [Notes on suggestion accuracy, priority scoring]

## Value & Time Savings
- [Notes on time saved, value delivered]

## Pain Points
- [Notes on frustrations, blockers, UX issues]

## Feature Requests
- [Bullet list of requested features]

## Future Engagement
- Would use again: [Yes/No/Maybe]
- Would pay: [Yes/No/Maybe, $X]
- Interested in PR automation: [Yes/No]
- OK to follow up: [Yes/No]

---

## Key Quotes
- "[Exact quote that captures sentiment]"
- "[Another memorable quote]"

## Action Items
- [ ] [Fix bug X]
- [ ] [Investigate feature request Y]
- [ ] [Follow up on Z]
```

---

## 9. Pilot Success Scenarios

### Best Case (Pilot Wildly Succeeds)

**What happens**:
- 5 partners onboard, 4 actively use the tool
- 3+ partners report meaningful time savings ("this would've taken me 2 hours manually, took 5 minutes with this")
- 2+ partners copy 50%+ of generated tests into their projects
- 1+ partner says "I'll use this every sprint"
- 10+ feature requests captured, clear patterns emerge
- 2+ partners commit to testing PR automation (v0.3)
- Zero critical bugs (parser crashes, data loss)

**Learnings**:
- Product-market fit validated ✅
- Test prioritization logic is sound ✅
- Manual YAML workflow is acceptable for v0 (not a blocker) ✅
- Clear next step: PR automation (v0.3) to reduce friction ✅

**Next steps**:
- Build PR automation (v0.3): GitHub integration, auto-create PRs, dbt test validation
- Keep design partners engaged for v0.3 testing
- Start thinking about distribution (PyPI, marketing site, docs)

### Good Case (Pilot Succeeds with Caveats)

**What happens**:
- 3 partners onboard, 2 actively use the tool
- 1+ partner reports time savings
- Partners like the analysis but don't copy many tests ("YAML workflow is too manual")
- Test suggestions are mostly accurate but some false positives
- 1+ critical bug found and fixed during pilot
- 5-10 feature requests, some contradictory

**Learnings**:
- Product-market fit hypothesis partially validated ✅
- Manual YAML workflow is a bigger blocker than expected ❌
- Test prioritization needs refinement (some false positives) ⚠️
- PR automation is table-stakes, not a v2 feature ⚠️

**Next steps**:
- Fix critical bugs and false positives before PR automation
- Fast-track PR automation (v0.3) — it's mandatory, not optional
- Clarify contradictory feature requests (what's the real pain?)

### Weak Case (Pilot Barely Succeeds)

**What happens**:
- 2 partners onboard, 1 actively uses the tool
- Partners find it "interesting but not essential"
- No clear time savings reported ("I'd still manually review every test")
- Test suggestions have significant false positives or miss obvious gaps
- 2+ critical bugs found
- Feature requests are scattershot (no clear patterns)

**Learnings**:
- Product-market fit is unclear ⚠️
- Either the pain isn't acute or the solution isn't compelling
- Test prioritization logic needs major rework ❌
- Quality bar too low (critical bugs, poor suggestions) ❌

**Next steps**:
- Pause product work, do deeper customer discovery
- Reassess: Is test coverage the right entry point? Or is there a more acute pain?
- Fix quality issues before re-engaging partners

### Failure Case (Pilot Fails)

**What happens**:
- <2 partners onboard, or partners install but never use
- No one reports time savings
- Parser crashes on 50%+ of projects
- Test suggestions are mostly wrong (false positives, irrelevant priorities)
- Partners say "this doesn't solve my problem" or "dbt Cloud already does this"

**Learnings**:
- Product-market fit hypothesis invalidated ❌
- Problem isn't painful enough, or positioning is wrong, or competitive threat misunderstood

**Next steps**:
- Stop building, start researching
- CEO-CTO session: What did we miss? Pivot or persevere?
- Options: (1) Different entry point (not test coverage), (2) Different target customer (not dbt Core), (3) Different product (not autonomous agents)

---

## 10. Post-Pilot Synthesis (Deliverables)

### Synthesis Document (`product/pilot-synthesis.md`)

**Due**: End of Week 4 (3 days after last partner feedback)
**Owner**: CTO-Agent
**Audience**: CEO, org, future agents

**Contents**:
1. **Executive Summary** (1 page)
   - What we tested, with whom, for how long
   - Top-line findings (validated, invalidated, unclear)
   - Go/no-go recommendation for next phase (PR automation)

2. **Partner Summary** (1 page)
   - Table of partners (company, team size, project size, engagement level)
   - Usage stats (analyze runs, tests generated, tests adopted)
   - Retention (who's staying engaged for v0.3)

3. **What Worked** (1-2 pages)
   - Validated assumptions (list with evidence)
   - Features that resonated (what partners loved)
   - Quality bar met (parser reliability, suggestion accuracy)

4. **What Didn't Work** (1-2 pages)
   - Invalidated assumptions (list with evidence)
   - Pain points (installation, UX, output, workflow)
   - Quality gaps (bugs, false positives, missing features)

5. **Feature Requests** (1-2 pages)
   - Prioritized list (frequency + impact)
   - Contradictory requests (flag where partners disagree)
   - Quick wins vs long-term investments

6. **Product Roadmap Adjustments** (1 page)
   - What to build next (PR automation, dbt Cloud support, custom patterns, etc.)
   - What to defer (cross-stack remediation, agent orchestration, etc.)
   - What to kill (features that tested poorly)

7. **Defensibility Update** (1 page)
   - Did partners mention dbt Labs competition?
   - New insights on dbt Cloud vs Core positioning
   - Moat reinforcement or pivot needed?

8. **Learnings for LEARNINGS.md** (1 page)
   - Key insights to add to org knowledge base
   - Process improvements (pilot execution, feedback collection)

9. **Next Steps** (1 page)
   - Immediate actions (bug fixes, quick wins)
   - V0.3 scope (PR automation)
   - V1.0 vision (production-ready Test Generator)

### Updated Backlog

**Action**: Update `BACKLOG.md` with post-pilot priorities
**Format**: Add new items based on pilot findings, re-prioritize existing items

**Example new items**:
- BL-019: Fix false positives in status column detection (Priority 0, high-impact quick win)
- BL-020: PR automation — GitHub integration, auto-create PRs (Priority 0, table-stakes feature)
- BL-021: dbt Cloud support — API-based manifest access (Priority 1, expand TAM)
- BL-022: Custom test patterns — user-defined rules (Priority 2, power-user feature)

### CEO Briefing

**Format**: Follow PB-010 (CEO Briefing)
**Timing**: After synthesis doc is complete
**Contents**: TL;DR of pilot results, go/no-go recommendation, where CEO can help next (distribution, design partners for v0.3, fundraising if we're ready)

---

## 11. Open Questions (For CEO)

**Strategic**:
1. **Design partner outreach**: How much CEO time can we allocate to warm intros? (1 hour? 5 hours? 20 hours?)
2. **Pilot publicity**: Do we want to be public about this pilot? (Blog post, tweet, dbt Slack announcement) Or keep it quiet?
3. **Pilot failure criteria**: If we get <2 partners in 2 weeks, do we pivot immediately or keep pushing? (When do we call it?)

**Operational**:
4. **Feedback channel**: Do we want a dedicated Slack for design partners? Or keep it async (email, GitHub Discussions)?
5. **Incentives**: Should we offer anything to design partners? (Swag, free credits, early access, advisory shares?) Or just "help us build something great"?

**Distribution**:
6. **Network intros**: Can CEO identify 5-10 warm leads from personal network? (We only need 3-5, so a 50% hit rate gets us there)
7. **Conference attendance**: Is CEO attending any data conferences in next 4 weeks? (dbt Coalesce, Data Council, etc.) In-person demos are high-conversion.

---

## 12. Risk Assessment

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Parser crashes on real projects** | Medium | High | Validate on open-source projects before pilot, fix bugs fast during pilot |
| **False positives in test suggestions** | Medium | Medium | Document known patterns, let partners override priorities |
| **Installation friction (Poetry, Python)** | Low | Medium | Clear onboarding doc, offer to help with setup |
| **Performance on large projects (1000+ models)** | Low | High | Stress-test on large open-source projects (GitLab data model) |

### Market Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **No one cares about test coverage** | Low | High | If true, pivot to different pain point (will know in 2 weeks) |
| **dbt Labs ships similar feature** | Medium | High | Monitor dbt Labs roadmap, emphasize cross-stack differentiation (BL-018) |
| **Partners prefer dbt Cloud over Core** | Medium | Medium | Validate Core-first strategy, but keep Cloud support on roadmap |
| **Partners want PR automation immediately** | High | Low | Expected — v0.3 is already on roadmap, this validates priority |

### Execution Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Can't find 3-5 partners** | Medium | High | CEO leads outreach, multiple channels (network + community) |
| **Partners ghost after install** | Medium | Medium | Proactive follow-up, make onboarding frictionless |
| **CTO-Agent bandwidth for support** | Low | Medium | Budget 2-4 hours/week for pilot support, automate where possible |
| **Pilot drags beyond 4 weeks** | Medium | Low | Strict timeline, synthesize even with incomplete data |

---

## 13. Success Definition (TL;DR)

**This pilot succeeds if**:
1. ✅ 3-5 teams run the tool on real projects
2. ✅ 2+ teams report "this is useful, I'd use it again"
3. ✅ 1+ team reports meaningful time savings
4. ✅ Zero critical bugs in core functionality
5. ✅ Clear learnings captured in synthesis doc

**This pilot fails if**:
1. ❌ <2 teams use the tool (market signal is weak)
2. ❌ No one finds it useful (value prop is wrong)
3. ❌ Parser crashes on 50%+ of projects (quality too low)
4. ❌ Partners say "dbt Cloud already does this" (competitive threat misunderstood)

**Abort signals** (stop pilot, reassess strategy):
- No partners after 2 weeks outreach
- Partners install but never use
- Parser unreliable on real projects
- Fundamental competitive threat (dbt Labs ships this feature)

---

## Appendices

### Appendix A: Pilot Onboarding Doc (To Be Written)

**Filename**: `product/pilot-onboarding.md`
**Owner**: CTO-Agent
**Due**: Week 0 (before first partner)

**Contents**:
- Welcome message
- Installation instructions (Poetry setup)
- Prerequisites (dbt Core, manifest.json, catalog.json)
- Quick-start guide (5-minute first run)
- Usage examples (analyze → generate-tests → copy to models/)
- Known limitations (no PR automation, no dbt Cloud)
- Feedback channels (email, GitHub Discussions)
- FAQ (troubleshooting common issues)

### Appendix B: Sample Outreach Email (CEO Template)

**Subject**: Quick favor — feedback on dbt test coverage tool?

Hi [Name],

Hope you're doing well! I'm reaching out because I'm working on a tool for dbt teams and you immediately came to mind.

**What it does**: Analyzes your dbt project and suggests missing tests (not_null, unique, etc.) based on column patterns. Saves time vs manually authoring schema.yml tests.

**Why I'm reaching out**: We're looking for 3-5 teams to try an early version and give honest feedback. No strings attached — just 30 minutes of your time (install, test on your project, quick feedback call).

**Would you or someone on your team be open to trying it?** If so, I'll send over a quick-start guide.

Either way, would love to catch up soon.

Thanks,
[CEO Name]

### Appendix C: Pilot Feedback Survey (Async Fallback)

**Tool**: Google Form (if feedback calls fail to schedule)

**Questions**:
1. Company name (optional)
2. Team size (data engineers)
3. dbt project size (# models)
4. How was the installation experience? (1-5 scale + comment)
5. Did the tool run successfully on your project? (Yes/No + details)
6. Were the test suggestions accurate? (1-5 scale + comment)
7. Did you copy any tests into your project? (Yes/No + how many)
8. Did this save you time? (Yes/No + estimated hours saved)
9. What did you like most?
10. What was most frustrating?
11. What would make this 10x more valuable?
12. Would you use this again? (Yes/No/Maybe)
13. Would you pay for this? (Yes/No/Maybe + how much)
14. Can we follow up? (Yes/No + email)

---

**End of Pilot Plan**

*Update protocol: Update when pilot timeline changes, partner criteria changes, or success metrics change. Archive this doc when pilot ends, replace with pilot-synthesis.md as the record of what happened.*
