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
- **Status**: RETIRED
- **Issued**: 2026-02-11
- **Retired**: 2026-02-14 (DEC-009)
- **Context**: Org is bootstrapping. Need solid foundations before building product.
- **Directive**: Finish all org infrastructure (interfaces, governance, execution capability) before starting any product code.
- **Success looks like**: CEO can open repo, understand state, give direction, and see it executed through defined interfaces.
- **Expires**: ~~When CEO explicitly approves transition to product work.~~ **Retired** — org infrastructure is operational. CEO approved transition to product work.

### DIR-002: Build AI agent expertise before product work
- **Status**: RETIRED
- **Issued**: 2026-02-11
- **Retired**: 2026-02-14 (DEC-009)
- **Context**: Before building a product, the org needs deep expertise in AI agent building — frameworks, tools, patterns, and the latest developments. This is foundational regardless of what product we build.
- **Directive**: Research and develop organizational knowledge in AI agent technologies. Survey the landscape, go deep on our own stack (Claude Code, Agent SDK, MCP), and propose a talent/capability plan. Prioritize this over product work.
- **Success looks like**: Research docs produced (`research/ai-agent-landscape.md`, `research/claude-agent-capabilities.md`), org has informed perspective on tools and trade-offs, talent plan proposed.
- **Expires**: ~~When CEO approves transition to product work.~~ **Retired** — research complete (BL-001, BL-002 done). Learning by building now.

### DIR-003: CTO operates with ownership and bias for action
- **Status**: ACTIVE
- **Issued**: 2026-02-14
- **Context**: CEO directed a culture shift — CTO should operate as a true owner, not a task executor. Inspired by Amazon leadership principles: Customer Obsession, Ownership, Bias for Action, Think Big, Have Backbone.
- **Directive**: CTO owns outcomes, not tasks. Have a point of view on everything. Proactively identify problems and opportunities. Disagree respectfully when something doesn't make sense. Drive results without waiting to be asked. Think long-term. Never say "that's not my job."
- **Success looks like**: CEO sees the CTO driving the product and org forward independently, bringing strong recommendations (not just options), and pushing back when needed. The org moves faster and with more conviction.
- **Expires**: Never — this is a permanent operating principle.

---
*Update protocol: Only the CEO can add, modify, or retire directives. CTO-Agent reads during PB-001 and PB-003. CTO-Agent may propose new directives but must get CEO approval before recording them.*
