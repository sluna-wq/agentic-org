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

### Priority 1 — Do Next
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-004 | Technical standards & conventions — define coding standards, project structure, testing strategy, CI/CD patterns. Output: `standards/CONVENTIONS.md` | 5 | 3 | M | None | CTO-Agent |
| BL-005 | Developer tooling & environment setup — linting, formatting, CI pipeline (GitHub Actions), test runner config. Output: `.github/workflows/`, working CI/CD | 4 | 3 | M | BL-004 | CTO-Agent |

### Priority 1.5 — Product Exploration (CEO-directed, DEC-006)
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-009 | Data stack competitive landscape — map existing players (Monte Carlo, Datafold, Atlan, Sifflet, Great Expectations, Elementary, Metaplane, etc.), their positioning, gaps, and where an agentic approach is differentiated. Output: `research/data-stack-competitive-landscape.md` | 5 | 5 | M | None | CTO-Agent |
| BL-010 | Modern data stack pain points & agent opportunities — map the full data stack (ingestion → transformation → warehouse → orchestration → BI → reverse ETL), identify top pain points at each layer, and assess which are most amenable to autonomous agent intervention. Output: `research/data-stack-pain-points.md` | 5 | 5 | M | None | CTO-Agent |
| BL-011 | Agent architecture for data stack — design patterns for specialized agents (what agents, what they own, how they coordinate, what tools/access they need, safety model). Output: `research/agent-architecture-for-data.md` | 5 | 4 | M | BL-001, BL-010 | CTO-Agent |
| BL-012 | Product concept synthesis — combine research into 2-3 concrete product concepts with positioning, MVP scope, go-to-market angle. For CEO review. Output: `research/product-concepts.md` | 5 | 4 | M | BL-009, BL-010, BL-011 | CTO-Agent |

### Priority 2 — Do Soon
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-003 | Org talent & capability plan — propose which specialist agent roles the org needs first, update ROSTER.md, propose hiring sequence to CEO via CEO-INBOX.md | 4 | 3 | S | BL-001, BL-002 | CTO-Agent |
| BL-006 | Competitive & market landscape — survey AI agent product landscape, what exists, what's missing, where's the opportunity. Output: `research/market-landscape.md` | 4 | 3 | M | None | CTO-Agent |
| BL-007 | Product vision drafting — based on research, draft 2-3 concrete product concepts for CEO review. Output: `research/product-vision-draft.md` | 5 | 2 | S | BL-001, BL-002, BL-006 | CTO-Agent |
| BL-008 | Org process stress test — mini PB-013 audit, verify daemon/skills/cross-references all work end-to-end, find and fix gaps. Output: LEARNINGS.md entries, fixes | 3 | 3 | S | None | CTO-Agent |

### Priority 3 — Do Eventually
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-013 | Cloud deployment — move daemon to cloud VM for 24/7 operation. CEO interacts via GitHub mobile. Output: working cloud VM, documented setup in `daemon/README.md` | 4 | 2 | M | Product shipping | CTO-Agent |

### Icebox
*(Ideas captured but not yet prioritized)*

## Completed
| ID | Description | Completed | Outcome | Learnings Ref |
|----|-------------|-----------|---------|---------------|
| BL-002 | Claude Code & Agent SDK deep dive | 2026-02-14 | Success — `research/claude-agent-capabilities.md` (2,711 lines) | LRN-008 |
| BL-001 | AI agent landscape research | 2026-02-12 | Success — `research/ai-agent-landscape.md` | LRN-006 |
| BL-009 | Data stack competitive landscape | 2026-02-11 | Success — `research/data-stack-competitive-landscape.md` | LRN-004 |
| BL-010 | Data stack pain points & agent opportunities | 2026-02-11 | Success — `research/modern-data-stack-agent-opportunity.md` | LRN-004 |
| BL-011 | Agent architecture for data stack | 2026-02-11 | Success — `research/data-stack-agent-architecture.md` | LRN-004 |
| BL-012 | Product concept synthesis | 2026-02-11 | Success — `research/product-concepts.md` | LRN-004 |
| BOOT-001 | Org bootstrap | 2026-02-11 | Success | LRN-001 |

---
*Update protocol: Add items with next available ID. Move items to "Completed" when done — always link to a LEARNINGS entry. Re-prioritize weekly during planning. CTO-Agent owns backlog grooming.*
