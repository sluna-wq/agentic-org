# Pilot Feedback Template

> **Template for documenting pilot partner feedback.**
> Create one copy per partner. Keep internal/private.

---

## Partner Information

**Company**: [Company Name]
**Contact**: [Name, Title, Email]
**Team Size**: [Number of data engineers]
**dbt Setup**:
- dbt version: [e.g., 1.7.4]
- Warehouse: [Snowflake / Postgres / BigQuery / Redshift]
- Project size: [Number of models, columns]
- Team structure: [Centralized data team / Embedded analytics engineers / etc.]

**Pilot Status**:
- Invited: [Date]
- Installed: [Date]
- First usage: [Date]
- Feedback call: [Date]
- Status: [Active / Ghosted / Completed]

---

## Installation Experience

### Did installation work smoothly?
[Yes / No / Partially]

### Issues encountered:
- [ ] Poetry installation problems
- [ ] Python version compatibility
- [ ] Missing dependencies
- [ ] manifest.json not found
- [ ] Other: [describe]

### Time to first successful run:
[e.g., 5 minutes / 30 minutes / Never got it working]

### Feedback/quotes:
```
[Raw notes or quotes from partner about installation]
```

---

## First Usage (Analyze Command)

### Did the tool run successfully?
[Yes / No / Partially]

### Project details:
- Number of models analyzed: [X]
- Number of columns analyzed: [X]
- Existing test coverage: [X%]
- Number of gaps detected: [X]
- Critical gaps (P1-P2): [X]

### Parser issues:
- [ ] Tool crashed
- [ ] Incorrect model count
- [ ] Incorrect column detection
- [ ] Performance issues (slow)
- [ ] None — worked perfectly
- [ ] Other: [describe]

### Reaction to coverage report:
[Surprised? Expected? Concerned? Unimpressed?]

### Feedback/quotes:
```
[Raw notes about first usage experience]
```

---

## Test Generation (Generate-Tests Command)

### Did they run generate-tests?
[Yes / No / Why not?]

### Output quality:
- Number of tests generated: [X]
- False positives (bad suggestions): [X / Examples]
- False negatives (missed obvious gaps): [X / Examples]
- Placeholder tests (accepted_values, relationships): [X]

### Did they copy tests into their project?
[Yes / No / Partially]

**If Yes:**
- How many tests copied: [X out of Y suggestions]
- Which types: [not_null / unique / accepted_values / relationships]
- Time saved vs manual authoring: [estimate]

**If No:**
- Why not: [Too noisy / Not accurate / Too much work / Didn't trust suggestions / Other]

### Feedback/quotes:
```
[Raw notes about test generation quality]
```

---

## Test Prioritization

### Were priorities accurate?
[Very accurate / Somewhat accurate / Not accurate]

### Examples of good prioritization:
```
[Which gaps were correctly flagged as high priority?]
```

### Examples of bad prioritization:
```
[Which gaps were incorrectly prioritized?]
[What should have been higher priority but wasn't?]
```

### Did they override priorities manually?
[Yes / No / How?]

### Feedback/quotes:
```
[Raw notes about prioritization logic]
```

---

## Use Cases & Context

### Why did they try the tool?
- [ ] Known test coverage gaps
- [ ] Recent data quality incident
- [ ] Curiosity / exploration
- [ ] Trying to improve engineering practices
- [ ] Boss told them to improve test coverage
- [ ] Other: [describe]

### How do they currently write tests?
- [ ] Manually author schema.yml files
- [ ] Copy-paste from other models
- [ ] Don't write tests at all
- [ ] Use dbt Cloud test recommendations
- [ ] Other: [describe]

### Where does test authoring fit in their workflow?
[During model development / Retroactively / Code review requirement / Ad-hoc / Never]

### Feedback/quotes:
```
[Raw notes about their current testing practices]
```

---

## Pain Points & Unmet Needs

### What was confusing or frustrating?
```
[List specific UX issues, error messages, unclear output, etc.]
```

### What's missing from v0.1?
- [ ] PR automation (auto-commit tests)
- [ ] GitHub integration
- [ ] dbt Cloud support
- [ ] Warehouse integration (query directly)
- [ ] Custom test templates
- [ ] Relationship detection (foreign keys)
- [ ] accepted_values inference (from data)
- [ ] Better placeholder suggestions
- [ ] Model-level filtering
- [ ] CI/CD integration
- [ ] Other: [describe]

### What would make this 10x more valuable?
```
[Dream features, even if unrealistic]
```

### Feedback/quotes:
```
[Raw notes about pain points and feature requests]
```

---

## Value Assessment

### Did this save time vs manual test authoring?
[Yes / No / Unclear]

**If Yes:**
- Estimated time saved: [X minutes/hours]
- For what: [Initial coverage audit / Writing YAML / Identifying gaps]

**If No:**
- Why not: [describe]

### Would they use this again?
[Yes / No / Maybe]

**If Yes:**
- How often: [Every sprint / Monthly / Ad-hoc / For new models only]
- For what: [New projects / Existing projects / Both]

**If No:**
- Why not: [describe]

### Would they recommend to colleagues?
[Yes / No / Maybe]

### Feedback/quotes:
```
[Raw notes about perceived value]
```

---

## Pricing & Willingness to Pay

### Would they pay for this?
[Yes / No / Maybe]

**If Yes:**
- How much: [$/month or $/year estimate]
- Per what: [Per seat / Per project / Flat rate / Enterprise]

**If No:**
- Why not: [Not valuable enough / Should be free / Budget constraints]

### What would justify paying?
[More features / Better accuracy / Autonomous agents / SLA / Support]

### Feedback/quotes:
```
[Raw notes about pricing]
```

---

## Competitive Context

### What other tools do they use for data quality?
- [ ] dbt Cloud test recommendations
- [ ] Great Expectations
- [ ] Soda
- [ ] Monte Carlo
- [ ] Custom scripts
- [ ] Nothing (manual only)
- [ ] Other: [describe]

### How does dbt Guardian compare?
[Better / Worse / Different use case]

### Do they see this as complementary or competitive with dbt?
[Complementary / Competitive / Unsure]

### Feedback/quotes:
```
[Raw notes about competitive positioning]
```

---

## Engagement & Follow-Up

### Overall engagement level:
[Highly engaged / Moderately engaged / Low engagement / Ghosted]

### Communication frequency:
[Daily / Weekly / Sporadic / Unresponsive]

### Likelihood to continue in v0.2/v0.3 pilots:
[High / Medium / Low / No]

### Relationship quality:
[Potential champion / Friendly but busy / Transactional / Unresponsive]

### Follow-up actions:
- [ ] Send thank-you email
- [ ] Offer early access to v0.2
- [ ] Schedule follow-up call for v0.3
- [ ] Add to advisory board candidates
- [ ] Other: [describe]

---

## Key Insights

### What worked well:
```
[3-5 bullet points of validated assumptions]
```

### What didn't work:
```
[3-5 bullet points of invalidated assumptions or failures]
```

### Surprising learnings:
```
[Unexpected feedback or use cases]
```

### Quotes worth sharing:
```
[2-3 standout quotes that capture sentiment]
```

---

## Action Items

### Bugs to fix:
- [ ] [Bug description] — Priority: [High/Medium/Low]
- [ ] [Bug description] — Priority: [High/Medium/Low]

### Features to prioritize:
- [ ] [Feature request] — Validated by [X partners]
- [ ] [Feature request] — Validated by [X partners]

### Documentation improvements:
- [ ] [What was confusing? What to clarify?]

---

## Metadata

**Feedback collected by**: [CTO-Agent / CEO]
**Interview date**: [YYYY-MM-DD]
**Interview format**: [Video call / Phone / Email / Slack async]
**Interview duration**: [X minutes]
**Notes taken by**: [Human / Agent]
**Raw notes location**: [Link to recording, transcript, or notes]

**Status**: [Draft / Reviewed / Synthesized]

---

*Template version: 1.0*
*Last updated: 2026-02-16*
