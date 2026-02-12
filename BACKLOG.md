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
| BL-001 | AI agent landscape research — survey frameworks (Claude Agent SDK, OpenAI Agents SDK, LangGraph, CrewAI, AutoGen, etc.), trade-offs, production readiness. Output: `research/ai-agent-landscape.md` | 5 | 4 | M | None | CTO-Agent |
| BL-002 | Claude Code & Agent SDK deep dive — tool use patterns, MCP server development, sub-agent orchestration, prompt engineering for agents. Output: `research/claude-agent-capabilities.md` | 5 | 4 | M | None | CTO-Agent |
| BL-004 | Technical standards & conventions — define coding standards, project structure, testing strategy, CI/CD patterns. Output: `standards/CONVENTIONS.md` | 5 | 3 | M | None | CTO-Agent |
| BL-005 | Developer tooling & environment setup — linting, formatting, CI pipeline (GitHub Actions), test runner config. Output: `.github/workflows/`, working CI/CD | 4 | 3 | M | BL-004 | CTO-Agent |

### Priority 2 — Do Soon
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-003 | Org talent & capability plan — propose which specialist agent roles the org needs first, update ROSTER.md, propose hiring sequence to CEO via CEO-INBOX.md | 4 | 3 | S | BL-001, BL-002 | CTO-Agent |
| BL-006 | Competitive & market landscape — survey AI agent product landscape, what exists, what's missing, where's the opportunity. Output: `research/market-landscape.md` | 4 | 3 | M | None | CTO-Agent |
| BL-007 | Product vision drafting — based on research, draft 2-3 concrete product concepts for CEO review. Output: `research/product-vision-draft.md` | 5 | 2 | S | BL-001, BL-002, BL-006 | CTO-Agent |
| BL-008 | Org process stress test — mini PB-013 audit, verify daemon/skills/cross-references all work end-to-end, find and fix gaps. Output: LEARNINGS.md entries, fixes | 3 | 3 | S | None | CTO-Agent |

### Priority 3 — Do Eventually
*(Empty)*

### Icebox
*(Ideas captured but not yet prioritized)*

## Completed
| ID | Description | Completed | Outcome | Learnings Ref |
|----|-------------|-----------|---------|---------------|
| BOOT-001 | Org bootstrap | 2026-02-11 | Success | LRN-001 |

---
*Update protocol: Add items with next available ID. Move items to "Completed" when done — always link to a LEARNINGS entry. Re-prioritize weekly during planning. CTO-Agent owns backlog grooming.*
