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

### Priority 0 — Product (dbt Guardian)
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-019 | **Pilot execution (Week 0 prep)** — Create pilot onboarding doc, set up feedback infrastructure, test on sample projects, get CEO approval. Output: `product/pilot-onboarding.md` + pilot-ready package | 5 | 5 | S | BL-017 ✓ | CTO-Agent |

### Priority 1 — Infrastructure (do alongside product)
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-005 | Developer tooling & environment setup — linting, formatting, CI pipeline (GitHub Actions), test runner config. Output: `.github/workflows/` in product repo | 4 | 3 | M | BL-004 | CTO-Agent |
| BL-013 | Cloud daemon — fix credits + PAT, get daemon running again for autonomous product work | 4 | 3 | S | Credits + PAT | CTO-Agent |

### Priority 2 — Do Soon
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-003 | Org talent & capability plan — what specialist agents do we need to ship dbt Guardian? | 4 | 3 | S | BL-014 | CTO-Agent |
| BL-008 | Org process stress test — mini PB-013 audit | 3 | 2 | S | None | CTO-Agent |

### Icebox
*(Ideas captured but not yet prioritized)*
- BL-006: Broader market landscape (superseded by product-specific research)
- BL-007: Product vision drafting (superseded by DEC-009, product direction confirmed)

## Completed
| ID | Description | Completed | Outcome | Learnings Ref |
|----|-------------|-----------|---------|---------------|
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
