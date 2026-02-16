# Pilot Feedback — Interview Guide & Survey

> **Structured questions for pilot partner feedback.**
> Use for 20-minute feedback calls or async surveys.

---

## Feedback Call Script (20 Minutes)

### Introduction (2 min)

"Thanks for taking the time to chat! This should take about 20 minutes. I want to hear your honest thoughts — good and bad. There are no wrong answers, and we won't be offended by criticism. In fact, critical feedback is the most valuable.

I'm going to ask you about:
1. Your experience getting set up and using the tool
2. Whether the test suggestions were accurate and useful
3. What's missing or confusing
4. Whether you'd use this again

Sound good? Let's start with your setup and dbt context."

---

### Section 1: Setup & Context (3 min)

**Q1: Tell me about your dbt setup**
- What version of dbt are you running? (Core vs Cloud?)
- What warehouse? (Snowflake, Postgres, etc.)
- How big is your dbt project? (rough number of models)
- How many people on your data team?

**Q2: How did installation go?**
- Any issues getting set up?
- How long from "I got the zip file" to "I ran my first command"?
- What was confusing or broken?

**Notes:**
```
[Record setup issues, environment details, time to first run]
```

---

### Section 2: First Usage (5 min)

**Q3: Walk me through your first time running `dbt-guardian analyze`**
- What was your first reaction to the coverage report?
- Were you surprised by the coverage percentage? Higher or lower than expected?
- Did the tool run without errors?

**Q4: Let's talk about the gaps it detected**
- Did the top 10 gaps make sense to you?
- Were there obvious gaps it missed?
- Were there false positives (columns it flagged that don't need tests)?

**Q5: What about the prioritization?**
- Did Priority 1 (critical) gaps seem actually critical?
- Did anything low-priority seem like it should be higher?
- How did you decide which gaps to act on?

**Notes:**
```
[Record accuracy of gap detection, prioritization feedback, false positives/negatives]
```

---

### Section 3: Test Generation (5 min)

**Q6: Did you run `dbt-guardian generate-tests`?**
- (If yes) What did you think of the output?
- (If no) Why not? What blocked you?

**Q7: Did you copy any of the suggested tests into your project?**
- (If yes) How many? Which types? (not_null, unique, etc.)
- (If yes) Did you modify them before copying?
- (If no) Why not? What stopped you?

**Q8: How much time did this save vs writing tests manually?**
- If you'd written these tests yourself, how long would it have taken?
- Did this feel like it saved time, or created more work?

**Q9: Let's talk about the placeholder tests** (accepted_values, relationships)
- The tool generates TODO placeholders for tests that need custom values
- Was that helpful or annoying?
- How would you improve this?

**Notes:**
```
[Record whether they used suggestions, time saved, placeholder feedback]
```

---

### Section 4: Use Case & Workflow (3 min)

**Q10: Why did you want to try this tool?**
- Do you have known test coverage issues?
- Recent data quality incidents?
- Just curious?
- Boss wants better test coverage?

**Q11: How do you currently write tests?**
- Manually author schema.yml?
- Copy-paste from other models?
- Don't write tests?
- Use dbt Cloud recommendations?

**Q12: Where would this fit in your workflow?**
- During initial model development?
- Retroactively on old models?
- As a CI/CD check?
- Ad-hoc when you remember?

**Notes:**
```
[Record current testing practices, pain points, workflow integration needs]
```

---

### Section 5: What's Missing (4 min)

**Q13: What was the most frustrating or confusing part?**
- Specific UX issues?
- Error messages that didn't make sense?
- Output format?
- Anything that felt broken or half-baked?

**Q14: What's the #1 thing missing from this tool?**
- If you could wave a magic wand and add one feature, what would it be?

**Q15: Here are some things we're considering for future versions. Which would be most valuable to you?**
- PR automation (auto-commit tests to your repo)
- GitHub integration (open PRs automatically)
- dbt Cloud support
- Smart value inference (analyze actual data to suggest accepted_values)
- Better relationship detection (infer foreign keys from column names)
- CI/CD integration (run in your pipeline, fail if coverage drops)
- Cross-stack remediation (fix Snowflake schema issues, not just dbt)

**Notes:**
```
[Record pain points, top feature requests, prioritization feedback]
```

---

### Section 6: Value & Future (3 min)

**Q16: Would you use this tool again?**
- On new models?
- To audit existing coverage?
- How often? (Weekly? Monthly? Ad-hoc?)

**Q17: Would you recommend this to colleagues or other dbt teams?**
- Why or why not?

**Q18: If this were a paid product, would your team pay for it?**
- (If yes) Roughly how much? (per seat? per project? flat rate?)
- (If yes) What would justify the cost?
- (If no) What would need to change for you to pay?

**Q19: Would you be interested in trying future versions?**
- v0.2 (probably PR automation)?
- v0.3 (maybe cross-stack remediation)?

**Notes:**
```
[Record retention likelihood, pricing feedback, champion potential]
```

---

### Closing (1 min)

"That's all my questions! Is there anything else you want to share? Any feedback or thoughts I didn't ask about?

Thanks so much for your time and honesty. We'll send you a summary of what we learned across all pilot partners, and we'll keep you in the loop on future versions.

Feel free to reach out anytime if you have more thoughts or run into issues!"

**Notes:**
```
[Record any additional feedback, relationship quality, follow-up actions]
```

---

## Async Survey (If Call Scheduling Fails)

> **Use this Google Form or email survey if partner can't schedule a live call.**
> Keep it short (10 questions max) to avoid abandonment.

### Survey Questions

**1. How would you describe your dbt setup?**
- [ ] dbt Core + Snowflake
- [ ] dbt Core + Postgres
- [ ] dbt Core + BigQuery
- [ ] dbt Core + Redshift
- [ ] dbt Cloud
- [ ] Other: ________

**2. How many models in your dbt project?**
- [ ] <10
- [ ] 10-50
- [ ] 50-100
- [ ] 100-500
- [ ] 500+

**3. How did installation go?**
- [ ] Smooth — installed and ran first command in <10 minutes
- [ ] Some issues — took 10-30 minutes
- [ ] Major issues — took >30 minutes or never got it working
- [ ] Didn't try to install

**4. Did the test coverage analysis work on your project?**
- [ ] Yes — ran without errors
- [ ] Partially — ran but had some issues
- [ ] No — crashed or gave incorrect results
- [ ] Didn't try

**5. Were the test gap priorities accurate?**
- [ ] Very accurate — flagged the right columns as critical
- [ ] Somewhat accurate — mostly right but some errors
- [ ] Not accurate — priorities didn't make sense
- [ ] Unsure / didn't review priorities

**6. Did you copy any of the suggested tests into your project?**
- [ ] Yes — copied many suggestions (10+)
- [ ] Yes — copied a few suggestions (1-9)
- [ ] No — but I reviewed the suggestions
- [ ] No — didn't generate tests

**If yes: How much time did this save vs writing tests manually?**
- [ ] Saved 10+ minutes
- [ ] Saved a few minutes
- [ ] Broke even (no time saved)
- [ ] Created more work

**7. What's the #1 thing missing from this tool?** (open text)
```
[Free text response]
```

**8. Would you use this tool again?**
- [ ] Yes — definitely
- [ ] Maybe — depends on improvements
- [ ] No — not useful for my workflow

**9. If this were a paid product, would your team pay for it?**
- [ ] Yes — if it had more features
- [ ] Maybe — depends on price
- [ ] No — wouldn't pay

**If yes: What would you pay per month?**
- [ ] $50-100/month
- [ ] $100-500/month
- [ ] $500-1000/month
- [ ] $1000+/month
- [ ] Unsure

**10. Any other feedback or thoughts?** (open text)
```
[Free text response]
```

**11. Would you like to stay updated on future versions?**
- [ ] Yes — send me updates
- [ ] No thanks

**Email (optional):** ________

---

## Post-Interview Actions

After each feedback call or survey response:

1. **Create partner feedback doc** using `pilot-feedback-template.md`
2. **Fill in all sections** while conversation is fresh
3. **Tag action items**:
   - Bugs: Add to GitHub Issues or `product/bugs.md`
   - Feature requests: Add to `product/feature-requests.md`
   - Documentation issues: Note for `pilot-onboarding.md` updates
4. **Update pilot tracking**:
   - Mark partner as "Feedback complete"
   - Note retention likelihood (High / Medium / Low)
5. **Send thank-you email**:
   - Thank them for time
   - Offer early access to v0.2
   - Share timeline for synthesis doc

---

## Feedback Analysis Framework

After collecting 3-5 partner responses, look for:

### Patterns (Signal)
- **Repeated pain points** → High-priority fixes
- **Repeated feature requests** → Validate for roadmap
- **Consistent positive feedback** → What's working, don't break it
- **Consistent confusion** → UX/documentation issues

### Outliers (Noise vs Insight)
- **One-off complaints** → May be partner-specific, not systemic
- **One-off feature requests** → Low priority unless CEO/CTO agrees
- **Contradictory feedback** → May reveal segmentation (different personas?)

### Key Metrics to Track
- **Activation rate**: % of partners who successfully ran the tool
- **Engagement rate**: % of partners who copied tests into their project
- **Time saved**: Average time saved vs manual authoring
- **Retention intent**: % who'd use again
- **NPS proxy**: % who'd recommend to colleagues
- **Willingness to pay**: % who'd pay + price range

---

*Last updated: 2026-02-16*
*Version: 1.0 (for dbt Guardian Test Generator v0.1 pilot)*
