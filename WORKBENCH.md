# Workbench — Org ↔ Product Execution Interface

> **How agents execute changes on the product codebase.**
> This defines the boundary between "org thinking" (planning, decisions, backlog) and "product doing" (code, tests, builds, deploys).

## Product Location
```
agentic-org/
├── [org artifacts]     ← CHARTER.md, STATE.md, etc. (the org)
└── product/            ← The actual product codebase (the work)
    ├── CLAUDE.md       ← Product-level agent instructions (tech stack, conventions, etc.)
    ├── src/            ← Source code
    ├── tests/          ← Test suite
    └── ...             ← Whatever the product needs
```

The `product/` directory is created when the CEO sets product direction. Until then it doesn't exist.

## Execution Protocol

### Making a Change
Every code change traces back to a backlog item. The flow:

```
BACKLOG item → Agent picks up (STATE.md) → Branch → Code → Test → Review → Merge → STATE.md update
```

**Steps**:
1. **Claim**: Agent updates STATE.md active work table with the backlog item ID
2. **Branch**: Create a git branch named `[BACKLOG-ID]/short-description` (e.g., `FEAT-001/add-login`)
3. **Implement**: Write code in `product/` following product CLAUDE.md conventions
4. **Test**: Run the test suite. All tests must pass. Add tests for new functionality.
5. **Validate**: Run any defined quality checks (lint, type check, build)
6. **Commit**: Descriptive commit messages referencing the backlog item ID
7. **Review**: CTO-Agent reviews (or self-reviews with checklist if solo)
8. **Merge**: Merge to main branch
9. **Close**: Follow PB-002 (Completing Work) — update STATE.md, BACKLOG.md, LEARNINGS.md

### Review Checklist
Before any merge, verify:
- [ ] Tests pass
- [ ] No regressions (existing tests still pass)
- [ ] Code follows product CLAUDE.md conventions
- [ ] No security vulnerabilities introduced
- [ ] Backlog item ID referenced in commits
- [ ] Rollback path is clear (what to revert if this breaks)

### Running the Product
Agents use these standard commands (defined in `product/CLAUDE.md` once the product exists):
```
# These are placeholders — actual commands defined per product
npm install          # or equivalent: install dependencies
npm test             # or equivalent: run test suite
npm run build        # or equivalent: build the product
npm run lint         # or equivalent: check code quality
npm start            # or equivalent: run locally
```

## Traceability
Every line of product code should be traceable:
```
Code change ← Git commit ← Branch name ← Backlog item ID ← Decision/Directive
```

This means:
- Commits reference backlog IDs
- Branches are named with backlog IDs
- Backlog items link to decisions or directives that motivated them
- The CEO can follow the chain from any piece of code back to "why"

## Quality Gates
No code merges to main without:
1. All tests passing
2. Review checklist completed
3. Backlog item properly tracked

Production deployments additionally require CEO approval per CHARTER.md.

## Environments
*(To be defined when product exists)*
| Environment | Purpose | Who can deploy |
|-------------|---------|---------------|
| Local | Development and testing | Any agent |
| Staging | Pre-production validation | CTO-Agent |
| Production | Live product | CTO-Agent with CEO approval |

---
*Update protocol: Update when product tech stack is chosen, when new quality gates are added, or when execution patterns change based on LEARNINGS.md. Product-specific commands go in `product/CLAUDE.md`, not here.*
