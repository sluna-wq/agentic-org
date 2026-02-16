# Pilot Partner Tracker

> **Live dashboard for tracking pilot partner status.**
> Update after every interaction. Read daily during pilot execution (Weeks 1-4).

**Pilot start date**: [TBD — when first partner onboards]
**Pilot end date**: [TBD — 4 weeks after start]
**Target partners**: 3-5
**Current partners**: 0

---

## Partner Status Overview

| Partner | Tier | Invited | Installed | First Use | Feedback | Status | Champion? |
|---------|------|---------|-----------|-----------|----------|--------|-----------|
| [Company Name] | 1 | [Date] | [Date] | [Date] | [Date] | Active | ⭐ High |
| [Company Name] | 2 | [Date] | — | — | — | Ghosted | Low |
| [Company Name] | 1 | [Date] | [Date] | [Date] | [Date] | Complete | Medium |
| | | | | | | | |

**Status values**: Invited / Installed / Active / Ghosted / Complete / Dropped

**Champion potential**: ⭐ High / Medium / Low

---

## Week-by-Week Progress

### Week 1 (Outreach + First Partners)

**Goal**: Get 1-2 partners installed and using the tool

**Outreach metrics**:
- Tier 1 (CEO network) invites sent: 0 / [target: 5-10]
- Tier 2 (community) posts made: 0 / [target: 2-3]
- Tier 3 (cold) outreach: 0 / [target: 10-20]
- Positive responses: 0
- Conversion rate: N/A

**Partner metrics**:
- Partners installed: 0 / [target: 1-2]
- Partners active: 0
- Installation issues: 0

**Blockers**:
- [ ] None yet

---

### Week 2 (Scale to 3-5 Partners + Usage)

**Goal**: Get 3-5 partners using tool, collect first feedback

**Partner metrics**:
- Total partners: 0 / [target: 3-5]
- Partners with feedback: 0 / [target: 1-2]
- Partners who copied tests: 0
- Critical bugs found: 0

**Feedback themes** (emerging):
- [Theme 1]: (mentioned by X partners)
- [Theme 2]: (mentioned by X partners)

**Blockers**:
- [ ] None yet

---

### Week 3 (Sustained Usage + Deep Feedback)

**Goal**: All partners have used tool, most feedback calls complete

**Partner metrics**:
- Active partners: 0 / [target: 3-5]
- Feedback calls complete: 0 / [target: 2-3]
- Total test suggestions generated: 0
- Total tests copied into projects: 0

**Feedback themes** (consolidated):
- [Theme 1]: (mentioned by X partners)
- [Theme 2]: (mentioned by X partners)

**Action items**:
- [ ] Fix critical bugs
- [ ] Update onboarding doc for common confusion
- [ ] Add FAQ items

**Blockers**:
- [ ] None yet

---

### Week 4 (Final Feedback + Synthesis)

**Goal**: Complete all feedback, start synthesis

**Partner metrics**:
- Total partners: 0 / [target: 3-5]
- Feedback complete: 0 / [target: 3-5]
- Partners likely to continue to v0.2: 0
- NPS proxy (would recommend): 0 / 0 = N/A

**Success metrics** (from pilot plan):
- ✅ 3-5 partners onboarded: 0 / [target: 3-5]
- ✅ 2+ partners used tool: 0 / [target: 2]
- ✅ 2+ partners gave feedback: 0 / [target: 2]
- ✅ 1+ partner reports time saved: 0 / [target: 1]
- ✅ 0 critical bugs: 0 bugs (target: 0)

**Synthesis progress**:
- [ ] All feedback docs complete
- [ ] Feedback themes identified
- [ ] Synthesis doc drafted
- [ ] Recommendations for v0.2 ready

---

## Partner Details

### [Company Name] — [Status]

**Tier**: [1/2/3]
**Contact**: [Name, Title, Email]
**Team**: [X data engineers]
**dbt setup**: [dbt version, warehouse, project size]

**Timeline**:
- Invited: [Date]
- Installed: [Date]
- First use: [Date]
- Feedback call: [Date]

**Engagement**:
- Installation: [Smooth / Issues / Never completed]
- Usage: [Analyzed project / Generated tests / Copied tests / None]
- Feedback quality: [High / Medium / Low]
- Champion potential: [High ⭐ / Medium / Low]
- Retention likelihood: [High / Medium / Low / No]

**Key insights**:
- What worked: [1-2 sentence summary]
- What didn't: [1-2 sentence summary]
- Top request: [Feature or fix]

**Action items**:
- [ ] [Follow-up action]
- [ ] [Bug to fix]

**Notes**:
```
[Quick notes on this partner — context for synthesis]
```

---

*(Repeat section above for each partner)*

---

## Outreach Tracking

### Tier 1: CEO Network (Warm Intros)

| Contact | Company | Outreach Date | Response | Status | Notes |
|---------|---------|---------------|----------|--------|-------|
| [Name] | [Company] | [Date] | [Yes/No/Pending] | [Invited/Declined/Ghosted] | [Notes] |
| | | | | | |

**Metrics**:
- Invites sent: 0
- Positive responses: 0
- Partners onboarded: 0
- Conversion rate: N/A

---

### Tier 2: Community (Public Channels)

| Channel | Post Date | Impressions | Responses | Partners | Notes |
|---------|-----------|-------------|-----------|----------|-------|
| dbt Slack #tools | [Date] | [Est] | [X] | [Y] | [Notes] |
| Locally Optimistic | [Date] | [Est] | [X] | [Y] | [Notes] |
| | | | | | |

**Metrics**:
- Posts made: 0
- Total responses: 0
- Partners onboarded: 0
- Conversion rate: N/A

---

### Tier 3: Cold Outreach

| Channel | Volume | Responses | Partners | Notes |
|---------|--------|-----------|----------|-------|
| Reddit | [X posts] | [Y] | [Z] | [Notes] |
| LinkedIn | [X DMs] | [Y] | [Z] | [Notes] |
| | | | | |

**Metrics**:
- Total cold outreach: 0
- Responses: 0
- Partners onboarded: 0
- Conversion rate: N/A

---

## Bugs & Issues Log

> **Track bugs discovered during pilot. Fix critical ones within 24 hours.**

| ID | Severity | Description | Reported By | Date | Status | Fixed? |
|----|----------|-------------|-------------|------|--------|--------|
| B001 | Critical | [Description] | [Partner] | [Date] | [Open/In Progress/Fixed] | [Date] |
| B002 | Medium | [Description] | [Partner] | [Date] | [Open/In Progress/Fixed] | [Date] |
| | | | | | | |

**Severity levels**:
- **Critical**: Tool doesn't work (crashes, incorrect output, data loss)
- **High**: Major UX issue or missing core functionality
- **Medium**: Annoying but has workaround
- **Low**: Nice-to-have, cosmetic, edge case

---

## Feature Requests Log

> **Track feature requests. Count how many partners request each.**

| Feature | Requested By (Count) | Priority | Notes |
|---------|---------------------|----------|-------|
| PR automation | [Partner A, Partner B] (2) | High | Most requested |
| dbt Cloud support | [Partner C] (1) | Medium | |
| | | | |

**Priority framework**:
- **High**: Requested by 2+ partners, feasible, high impact
- **Medium**: Requested by 1 partner OR high value but hard to build
- **Low**: Nice-to-have, low impact, or very complex

---

## Success Metrics (Live)

> **Track against pilot plan success criteria.**

### Must-Have (Pilot Success)

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Partners onboarded | 3-5 | 0 | 🔴 |
| Partners who used tool | 2+ | 0 | 🔴 |
| Partners who gave feedback | 2+ | 0 | 🔴 |
| Partners who report time saved | 1+ | 0 | 🔴 |
| Critical bugs in core analysis | 0 | 0 | 🟢 |

### Nice-to-Have

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Partners onboarded | 5+ | 0 | 🔴 |
| Partners who copied tests | 2+ | 0 | 🔴 |
| Average time saved per partner | 10+ min | N/A | — |
| Partners willing to pay | 1+ | 0 | 🔴 |
| Partners want v0.2 access | 2+ | 0 | 🔴 |

### Red Flags

| Red Flag | Observed? | Action Taken |
|----------|-----------|--------------|
| No partners after 2 weeks | ❌ No | N/A |
| Partners install but never use | ❌ No | N/A |
| Parser crashes on 50%+ of projects | ❌ No | N/A |
| Partners say "dbt Cloud does this" | ❌ No | N/A |

**Status key**: 🟢 On track | 🟡 At risk | 🔴 Off track

---

## Next Actions

> **Updated daily. Top 3 priorities for CTO-Agent.**

1. [Action] — [Owner] — [Due date]
2. [Action] — [Owner] — [Due date]
3. [Action] — [Owner] — [Due date]

---

## Notes & Observations

> **Running log of observations during pilot execution. Append at bottom.**

### [Date] — [Observation]
```
[Details]
```

---

*Last updated: [Date]*
*Pilot day: [N/28]*
*Next update: [When]*
