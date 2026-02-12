# CEO Directives

> **The CEO's standing orders to the org.**
> Directives persist between sessions. They are the CEO's voice when the CEO isn't in the room.
> Agents must read this during PB-001 (Session Startup) and treat active directives as constraints.

## How Directives Work
- The CEO writes directives here (or dictates them to CTO-Agent to record)
- Each directive has a status: `ACTIVE`, `PAUSED`, or `RETIRED`
- Active directives constrain all org behavior until changed
- CTO-Agent can propose changes but only CEO can modify directives
- Directives override backlog prioritization — if a directive conflicts with backlog order, the directive wins

## Format
```
### DIR-[NNN]: [Title]
- **Status**: ACTIVE | PAUSED | RETIRED
- **Issued**: YYYY-MM-DD
- **Context**: Why the CEO is issuing this
- **Directive**: What the org must do / stop doing / prioritize
- **Success looks like**: How we know this is satisfied
- **Expires**: [Date | Never | When condition met]
```

---

### DIR-001: Complete org infrastructure before product work
- **Status**: ACTIVE
- **Issued**: 2026-02-11
- **Context**: Org is bootstrapping. Need solid foundations before building product.
- **Directive**: Finish all org infrastructure (interfaces, governance, execution capability) before starting any product code.
- **Success looks like**: CEO can open repo, understand state, give direction, and see it executed through defined interfaces.
- **Expires**: When CEO explicitly approves transition to product work.

### DIR-002: Build AI agent expertise before product work
- **Status**: ACTIVE
- **Issued**: 2026-02-11
- **Context**: Before building a product, the org needs deep expertise in AI agent building — frameworks, tools, patterns, and the latest developments. This is foundational regardless of what product we build.
- **Directive**: Research and develop organizational knowledge in AI agent technologies. Survey the landscape, go deep on our own stack (Claude Code, Agent SDK, MCP), and propose a talent/capability plan. Prioritize this over product work.
- **Success looks like**: Research docs produced (`research/ai-agent-landscape.md`, `research/claude-agent-capabilities.md`), org has informed perspective on tools and trade-offs, talent plan proposed.
- **Expires**: When CEO approves transition to product work.

---
*Update protocol: Only the CEO can add, modify, or retire directives. CTO-Agent reads during PB-001 and PB-003. CTO-Agent may propose new directives but must get CEO approval before recording them.*
