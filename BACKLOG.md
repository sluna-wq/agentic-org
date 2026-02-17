# Backlog

> **What needs to be done, in what order, and why.**
> This is the prioritized queue of work. Items flow: Backlog → Active (STATE.md) → Done → Learnings.

## Prioritization Framework
Items are scored on:
- **Impact**: How much does this move a key metric or unblock other work? (1-5)
- **Urgency**: Is there a time constraint? (1-5)
- **Effort**: How much work is this? (T-shirt: XS, S, M, L, XL)
- **Dependencies**: What must exist first?

## Queue

### Priority 0 — Active: DE Walkthroughs (Discovery Phase)
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-022 | **DE Walkthroughs (WT-02 through WT-10)** — Continue walkthrough curriculum. Each scenario teaches different DE skills and surfaces agent DE requirements. CEO + CTO both participate. WT-10 synthesizes all learnings into agent design. | 5 | 5 | L | WT-01 ✓ | CEO + CTO-Agent |

### Priority 1 — Infrastructure (when needed)
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-013 | Cloud daemon — fix credits + PAT, get daemon running again | 3 | 2 | S | Credits + PAT | CTO-Agent |

### Icebox
*(Ideas captured but not yet prioritized — YAGNI per DIR-004)*
- BL-021: "SDKification" research — Moved from P2 to Icebox. Speculative while still in discovery (DIR-004: YAGNI). Revisit only if walkthroughs surface this as the product direction.
- BL-006: Broader market landscape (superseded by product-specific research)
- BL-007: Product vision drafting (superseded by DEC-009, product direction confirmed)
- BL-020: dbt Guardian pilot execution (ON HOLD — pivot to walkthroughs per DEC-012. May revive in different form after WT-10 synthesis.)

## Completed
| ID | Description | Completed | Outcome | Learnings Ref |
|----|-------------|-----------|---------|---------------|
| BL-008 | Org process stress test (mini PB-013 audit) | 2026-02-16 | Success — Systematic audit of all org artifacts after 7 autonomous cycles. Verified: core knowledge architecture internally consistent ✅, playbooks reflect learnings ✅, 4 skills operational ✅. Fixed 2 inconsistencies: ROSTER.md updated with talent plan findings (no capability gaps for 6mo), STATE.md corrected to Cycle #8. Evaluated new AI tools (Feb 2026): Claude Opus 4.6 (1M context, compaction API, adaptive thinking), Agent SDK updates (Agent Teams, memory frontmatter, hook events) — all relevant for future adoption. Pattern: audit at natural checkpoints → catch drift early → fix immediately → evaluate new tools. | LRN-020 |
| BL-003 | Org talent & capability plan | 2026-02-16 | Success — Comprehensive talent plan (11 sections, 400+ lines) at `org/talent-capability-plan.md`: current state assessment (CTO-Agent high-performing, no delivery bottleneck), 7 specialist agent roles defined (Backend/Data/Frontend/DevOps/QA/PM/Security), hiring triggers and sequencing (stay lean through Month 3, hire Data Engineer at Month 6-9, SaaS team at Month 9-12), cost analysis ($90/month per agent, scaling to ~$600/month at 7 agents), org structure evolution (flat through Month 6, consider management layer at 6+ agents). Recommendation: Stay solo through pilot, reassess after pilot synthesis with real execution data. | LRN-019 |
| BL-019 | Pilot Week 0 prep (onboarding doc, feedback infra) | 2026-02-16 | Success — Created comprehensive pilot infrastructure (3,200+ lines, 4 docs): pilot-onboarding.md (1,400 lines: installation, quick-start, troubleshooting, FAQ), pilot-feedback-template.md (600 lines: per-partner capture), pilot-feedback-questions.md (700 lines: interview guide + survey), pilot-tracker.md (500 lines: live dashboard). All docs reviewed for clarity, completeness, pilot-appropriate tone. Ready to onboard first partner within 1-3 days once CEO approves pilot plan. | LRN-018 |
| BL-005 | Developer tooling & environment setup | 2026-02-15 | Success — Complete developer tooling infrastructure: GitHub Actions (test.yml, lint.yml, release.yml), Makefile (15+ targets), pre-commit config, VS Code settings/extensions/launch, .editorconfig, .python-version, CONTRIBUTING.md. CI enforces quality on every PR (Python 3.11/3.12, coverage, linting, type checking, security audit). Zero-config onboarding: clone → `make install` → start coding. | LRN-017 |
| BL-018 | Defensibility analysis (vs dbt Labs) | 2026-02-15 | Success — Comprehensive defensibility analysis (8 sections, 9K+ words) covering dbt Labs roadmap, what they're NOT building, overlap analysis, strategic constraints, moat framework, threat scenarios with mitigation, positioning strategy. Key finding: dbt Labs focused on dev tools (Copilot, Semantic Layer), not operational agents. Window open for dbt Guardian. | LRN-016 |
| BL-017 | Pilot plan & design partner strategy | 2026-02-15 | Success — Comprehensive 13-section pilot plan covering: product context, goals, metrics, partner criteria, timeline, outreach channels, onboarding flow, feedback framework, success scenarios, synthesis deliverables, open questions, risk assessment. Ready for CEO review. | LRN-015 |
| BL-016 | Test Generator agent v0 | 2026-02-15 | Success — Full implementation: TestCoverageAnalyzer (detects gaps, prioritizes by column patterns), SchemaYamlGenerator (PR-ready YAML with placeholders), CLI commands (analyze + generate-tests), 35+ unit tests. Works on any dbt Core project. | LRN-014 |
| BL-015 | dbt project parser (manifest.json, catalog, YAML) | 2026-02-15 | Success — Full parser implementation with 3 modules (ManifestParser, CatalogParser, ProjectParser), Pydantic models, type hints, CLI commands, unit tests. In `products/dbt-guardian/` (mono-repo approach until GitHub repo creation is available). | LRN-013 |
| BL-014 | Product repo bootstrap (dbt-guardian) | 2026-02-15 | Success — Full repo scaffold: CLAUDE.md, Python project structure, CI/CD, CLI skeleton. Local at `/home/runner/work/agentic-org/dbt-guardian` | LRN-010 |
| BL-004 | Technical standards & conventions | 2026-02-14 | Success — `standards/CONVENTIONS.md` (comprehensive 600+ line doc) | LRN-009 |
| BL-002 | Claude Code & Agent SDK deep dive | 2026-02-14 | Success — `research/claude-agent-capabilities.md` (2,711 lines) | LRN-008 |
| BL-001 | AI agent landscape research | 2026-02-12 | Success — `research/ai-agent-landscape.md` | LRN-006 |
| BL-009 | Data stack competitive landscape | 2026-02-11 | Success — `research/data-stack-competitive-landscape.md` | LRN-004 |
| BL-010 | Data stack pain points & agent opportunities | 2026-02-11 | Success — `research/modern-data-stack-agent-opportunity.md` | LRN-004 |
| BL-011 | Agent architecture for data stack | 2026-02-11 | Success — `research/data-stack-agent-architecture.md` | LRN-004 |
| BL-012 | Product concept synthesis | 2026-02-11 | Success — `research/product-concepts.md` | LRN-004 |
| BOOT-001 | Org bootstrap | 2026-02-11 | Success | LRN-001 |

---
*Update protocol: Add items with next available ID. Move items to "Completed" when done — always link to a LEARNINGS entry. Re-prioritize weekly during planning. CTO-Agent owns backlog grooming.*
