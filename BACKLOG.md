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

### Priority 2 — Do Soon
| ID | Description | Impact | Urgency | Effort | Dependencies | Owner |
|----|-------------|--------|---------|--------|-------------|-------|
| BL-003 | Org talent & capability plan — propose which specialist agent roles the org needs first, update ROSTER.md, propose hiring sequence to CEO via CEO-INBOX.md | 4 | 3 | S | BL-001, BL-002 | CTO-Agent |

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
