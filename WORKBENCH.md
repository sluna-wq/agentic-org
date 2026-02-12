# Workbench — Org ↔ Product Execution Interface

> **How agents execute changes on the product codebase.**
> This defines the boundary between "org thinking" (planning, decisions, backlog) and "product doing" (code, tests, builds, deploys).

## Product Location

Products live in **separate git repositories**, not subdirectories of this org repo.

```
agentic-org/              ← Management/org layer (THIS repo)
├── [org artifacts]       ← CHARTER.md, STATE.md, BACKLOG.md, etc.
└── .product-repos.md     ← Registry of product repos this org manages

product-repo-name/        ← Separate repo (actual product code)
├── CLAUDE.md             ← Product-level agent instructions
├── src/
├── tests/
└── ...
```

**Why separate repos?**
- Clear separation: org management vs. product code
- Independent versioning and CI/CD per product
- Enables managing multiple products from one org
- Product repos can be private even if org repo is public

Product repos are created via PB-019 (Product Repo Bootstrap) when the CEO sets a product direction. The registry in `.product-repos.md` tracks all product repos.

## Execution Protocol

### Making a Change
Every code change traces back to a backlog item. The flow:

```
BACKLOG item → Agent picks up (STATE.md) → Branch → Code → Test → Review → Merge → STATE.md update
```

**Steps**:
1. **Claim**: Agent updates STATE.md active work table with the backlog item ID
2. **Navigate**: Switch to the product repo (see `.product-repos.md` for local path)
3. **Branch**: Create a git branch named `[BACKLOG-ID]/short-description` (e.g., `FEAT-001/add-login`) in the product repo
4. **Implement**: Write code following the product repo's CLAUDE.md conventions
5. **Test**: Run the test suite. All tests must pass. Add tests for new functionality.
6. **Validate**: Run any defined quality checks (lint, type check, build)
7. **Commit**: Descriptive commit messages referencing the backlog item ID
8. **Review**: CTO-Agent reviews (or self-reviews with checklist if solo)
9. **Merge**: Merge to main branch in the product repo
10. **Return**: Switch back to the org repo
11. **Close**: Follow PB-002 (Completing Work) — update STATE.md, BACKLOG.md, LEARNINGS.md in the org repo

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
