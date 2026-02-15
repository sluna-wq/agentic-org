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
| BL-015 | **dbt project parser** — Build core capability to parse dbt `manifest.json`, `catalog.json`, and project YAML files. Extract models, tests, columns, lineage, SQL. This is the foundation everything else builds on. | 5 | 5 | M | BL-014 ✓ | CTO-Agent |
| BL-016 | **Test Generator agent v0** — Analyze dbt project for test coverage gaps. Generate `schema.yml` test suggestions (not_null, unique, accepted_values, relationships). Output as PR-ready YAML. Target: works on any dbt Core project with a manifest.json. | 5 | 5 | L | BL-015 | CTO-Agent |
| BL-017 | **Pilot plan & design partner outreach** — Write formal pilot plan (scope, success metrics, timeline, selection criteria). Identify channels for finding dbt Core design partners. For CEO review. Output: `product/pilot-plan.md` | 5 | 4 | S | BL-014 | CTO-Agent |
| BL-018 | **Defensibility analysis** — Deep dive on dbt Labs roadmap (Copilot, Explorer, Semantic Layer), what they're likely to build vs not, where our cross-stack story creates a moat. Inform product positioning. Output: `research/defensibility-analysis.md` | 4 | 4 | M | None | CTO-Agent |

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
