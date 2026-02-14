# Technical Standards & Conventions

> **The technical foundation for all code produced by this organization.**
> Applies to both org infrastructure (this repo) and product code (separate repos).
> Last updated: 2026-02-14

## Purpose

This document defines coding standards, project structure, testing strategy, and CI/CD patterns that ensure:
1. **Consistency** — any agent can read and contribute to any codebase
2. **Quality** — every change meets minimum quality bars
3. **AI-native operation** — conventions optimize for agent authorship and maintenance
4. **Maintainability** — code is comprehensible 6 months later

## Philosophy

### AI-Native Development
Code in this organization is written by AI agents for AI agents (and humans). This informs our conventions:

- **Explicit over clever**: Prefer readable, verbose code over terse idioms
- **Comments explain *why*, not *what***: Agents can read the code; explain the reasoning
- **Self-documenting names**: `getUserAuthenticationToken()` not `getToken()`
- **Type annotations everywhere**: Types are documentation that machines verify
- **Consistent patterns**: One way to do common tasks, documented and referenced

### Repository Architecture

```
Management Repo (agentic-org/):
├── .claude/              ← Skills, hooks, MCP config
│   ├── skills/           ← Org capabilities (/cto, /status, /sync, etc.)
│   └── mcp.json          ← MCP server configurations
├── .cto-private/         ← CEO↔CTO private channel
│   ├── CEO-INBOX.md      ← Notifications to CEO
│   └── THREAD.md         ← Strategic discussions
├── .github/              ← CI/CD workflows
│   └── workflows/        ← GitHub Actions (daemon, CI checks)
├── daemon/               ← Autonomous operation
│   ├── harness.js        ← Daemon entry point
│   ├── CYCLE-LOG.md      ← Cycle history
│   └── README.md         ← Daemon documentation
├── research/             ← Research artifacts
├── standards/            ← THIS FILE
├── [artifacts]           ← CHARTER.md, STATE.md, etc.
└── package.json          ← Node dependencies

Product Repos (separate):
├── CLAUDE.md             ← Product-specific agent instructions
├── src/                  ← Source code
├── tests/                ← Test suite
├── .github/workflows/    ← Product CI/CD
└── package.json          ← Product dependencies
```

**Key principles**:
- **Management/product separation**: Org thinking stays in management repo, product code in separate repos
- **Registry pattern**: `.product-repos.md` tracks all product repos
- **Per-repo conventions**: Each product repo has `CLAUDE.md` for product-specific patterns

## Language & Framework Standards

### JavaScript/TypeScript (Primary)
Our current stack is Node.js. Future products may add TypeScript.

**File naming**:
- `kebab-case.js` for files
- `PascalCase.js` for classes/components if using frameworks
- Test files: `my-module.test.js` (colocated with source)

**Code style**:
- **Indentation**: 2 spaces (no tabs)
- **Line length**: 100 characters max (readability for agents and humans)
- **Semicolons**: Always use them (avoid ASI ambiguity)
- **Quotes**: Single quotes for strings, double for JSON/attributes
- **Trailing commas**: Always (cleaner diffs)

**Formatting**: Use Prettier with this config:
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2
}
```

**Linting**: Use ESLint with `eslint:recommended`:
```json
{
  "extends": ["eslint:recommended"],
  "env": { "node": true, "es2022": true },
  "parserOptions": { "ecmaVersion": 2022, "sourceType": "module" }
}
```

**Modules**: Use ES6 modules (`import`/`export`), not CommonJS (`require`), for all new code.

### TypeScript (When Adopted)
When a product adopts TypeScript:
- **Strict mode**: `"strict": true` in `tsconfig.json`
- **No implicit any**: Every value has an explicit type or inference
- **Interfaces over types**: Use `interface` for object shapes, `type` for unions/intersections
- **Type imports**: Use `import type { Foo } from './foo'` for type-only imports

### Python (If Needed)
If a product uses Python (e.g., data agents):
- **Version**: Python 3.11+
- **Style**: PEP 8 with Black formatter (line length: 100)
- **Type hints**: Required for all functions
- **Linting**: Ruff (modern, fast alternative to flake8/pylint)
- **Package management**: Poetry (for reproducibility)

## Project Structure Conventions

### Org Repo (This Repo)
Follows the structure defined in CLAUDE.md. Key files:

**Entry points**:
- `CLAUDE.md` — agent bootstrap instructions
- `STATE.md` — live dashboard (read first)
- `CEO-GUIDE.md` — CEO quick reference

**Interfaces**:
- `.cto-private/` — CEO↔CTO private
- `DIRECTIVES.md`, `BRIEFING.md`, `STATE.md` — CEO↔Org public
- `WORKBENCH.md`, `.product-repos.md` — Org↔Product execution

**Knowledge**:
- `CHARTER.md`, `DECISIONS.md`, `BACKLOG.md`, `LEARNINGS.md`, `METRICS.md`, `PLAYBOOKS.md`, `ROSTER.md`

**Skills & Automation**:
- `.claude/skills/` — Claude Code skills
- `daemon/` — autonomous operation

### Product Repos
Each product repo must include:

**Required**:
- `CLAUDE.md` — product-specific agent instructions (architecture, commands, conventions)
- `README.md` — human-readable product overview
- `package.json` or equivalent — dependency manifest
- `.gitignore` — standard ignores for the language/framework
- `src/` — source code
- `tests/` — test suite
- `.github/workflows/ci.yml` — CI pipeline (tests, lint, build)

**Recommended**:
- `docs/` — architecture decision records, API docs
- `scripts/` — build/deploy scripts
- `CHANGELOG.md` — versioned change history

## Testing Strategy

### Philosophy
- **Test behavior, not implementation**: Tests should verify "what" the code does, not "how"
- **Fast feedback**: Unit tests run in <5s, integration tests in <30s
- **Deterministic**: No flaky tests; all tests pass 100% of the time or are fixed/deleted
- **Coverage as a guide**: Aim for 80%+ line coverage, but quality > quantity

### Test Types

#### Unit Tests
- **Scope**: Single function/class, mocked dependencies
- **Location**: Colocated with source (`my-module.test.js` next to `my-module.js`)
- **Naming**: `describe('functionName', () => { it('should do X when Y', ...) })`
- **Framework**: Jest (JavaScript/TypeScript) or pytest (Python)

#### Integration Tests
- **Scope**: Multiple components, real dependencies (DB, APIs, file system)
- **Location**: `tests/integration/`
- **Naming**: `describe('Feature X integration', ...)`
- **Data**: Use test fixtures, tear down after each test

#### End-to-End Tests
- **Scope**: Full user flows through the system
- **Location**: `tests/e2e/`
- **When**: For products with user interfaces or critical workflows
- **Framework**: Playwright (web) or similar

### Test Execution

**Local development**:
```bash
npm test              # Run all tests
npm test -- --watch   # Watch mode
npm run test:unit     # Unit tests only
npm run test:integration  # Integration tests only
```

**CI pipeline** (see CI/CD section):
- Unit tests run on every commit
- Integration tests run on every PR
- E2E tests run on merge to main

### Test Quality Standards
Every test must:
- Have a clear, descriptive name explaining what it verifies
- Be isolated (no shared state between tests)
- Be deterministic (same input → same output, always)
- Clean up resources (files, DB records, network connections)

## Code Quality & Review

### Pre-Commit Checks
Run these before every commit (automated via git hooks or CI):
1. **Lint**: `npm run lint` (ESLint/Ruff)
2. **Format**: `npm run format` (Prettier/Black)
3. **Type check**: `npm run typecheck` (TypeScript, if applicable)
4. **Unit tests**: `npm test`

### Review Checklist
Before merging any PR (agent self-reviews if solo, CTO reviews specialist work):

**Functionality**:
- [ ] Does the code do what the backlog item requires?
- [ ] Are edge cases handled?
- [ ] Are error conditions handled gracefully?

**Quality**:
- [ ] All tests pass (unit, integration)
- [ ] No regressions (existing tests still pass)
- [ ] Code follows conventions in this document
- [ ] New functionality has tests
- [ ] No linter errors or warnings

**Security**:
- [ ] No secrets in code (API keys, passwords, tokens)
- [ ] User input is validated
- [ ] Dependencies are up to date (no critical CVEs)

**Documentation**:
- [ ] Complex logic has explanatory comments
- [ ] Public APIs have docstrings/JSDoc
- [ ] README updated if user-facing changes

**Traceability**:
- [ ] Commits reference backlog item ID
- [ ] Branch named `[BACKLOG-ID]/description`
- [ ] Backlog item updated in org repo

### Rollback Path
Every change must have a clear rollback strategy. Document in the PR or commit message:
- "Rollback: Revert this commit"
- "Rollback: Restore DB from backup before [timestamp]"
- "Rollback: Redeploy previous Docker image [tag]"

## CI/CD Patterns

### Continuous Integration

**Triggers**:
- **On push to any branch**: Lint, format check, unit tests
- **On PR to main**: Full test suite (unit + integration), build verification
- **On merge to main**: Full test suite, build, tag release

**GitHub Actions workflow** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run lint
      - run: npm run format:check
      - run: npm test
      - run: npm run build
```

**Failure policy**:
- Any CI failure blocks merge
- Flaky tests are treated as failures (fix or delete, never ignore)

### Continuous Deployment

**Environments**:
| Environment | Trigger | Approval | Purpose |
|-------------|---------|----------|---------|
| Local | Manual | None | Agent development |
| Staging | Merge to `main` | Auto | Pre-production validation |
| Production | Manual trigger | CEO | Live product |

**Deployment checklist**:
1. All CI checks pass
2. Staging deployment successful
3. Smoke tests pass in staging
4. CEO approval obtained (production only)
5. Rollback plan documented
6. Deploy
7. Monitor for 15 minutes
8. Update STATE.md with deployment status

**Rollback procedure**:
1. Identify last known good version
2. Trigger rollback deployment (should take <5 minutes)
3. Verify rollback successful
4. Post-mortem: why did this happen? (update LEARNINGS.md)

## Dependency Management

### Node.js
- **Lock file**: Always commit `package-lock.json`
- **Updates**: Review dependencies quarterly (PB-013 quarterly audit)
- **Security**: Run `npm audit` on every CI run; fix critical/high CVEs within 1 week
- **Pinning**: Pin exact versions for production dependencies, allow ranges for dev dependencies

### Python (if used)
- **Lock file**: Always commit `poetry.lock`
- **Updates**: Review dependencies quarterly
- **Security**: Run `pip-audit` on every CI run

### Version constraints
- **Production**: Exact pins (`"express": "4.18.2"`)
- **Development**: Caret ranges (`"prettier": "^3.0.0"`)
- **Rationale**: Production stability > cutting edge; dev tools can float

## Security Standards

### Secrets Management
- **NEVER commit secrets**: API keys, passwords, tokens, certificates
- **Use environment variables**: `.env` files locally (in `.gitignore`), GitHub Secrets for CI, secret manager for production
- **Rotate regularly**: API keys rotated every 90 days, document in LEARNINGS.md

### Input Validation
- **Validate all external input**: User input, API responses, file uploads
- **Use allowlists, not blocklists**: Define what's allowed, reject everything else
- **Sanitize before use**: SQL queries (use parameterized queries), shell commands (avoid `exec` with user input), HTML output (escape or use frameworks that auto-escape)

### Authentication & Authorization
*(Will be defined when first product implements auth)*
- **Authentication**: Who are you?
- **Authorization**: What can you do?
- **Principle of least privilege**: Grant minimum permissions needed

## Documentation Standards

### Code Comments
**When to comment**:
- Complex algorithms: Explain the approach and why it works
- Non-obvious decisions: Why this solution over alternatives
- TODOs: `// TODO(CTO-Agent): Refactor this after BL-XXX completes`
- Workarounds: `// HACK: API v1 doesn't support X, remove after v2 migration`

**When NOT to comment**:
- Obvious code: `i++; // increment i` ← No
- Redundant docstrings: If the function name and types are self-explanatory, skip the docstring

### README Files
Every repo and major directory should have a README with:
1. **Purpose**: What is this?
2. **Quick start**: How do I run it?
3. **Commands**: Common tasks (`npm test`, `npm run build`, etc.)
4. **Architecture**: High-level structure (link to `docs/` for details)

### API Documentation
For public APIs (if product has them):
- **OpenAPI/Swagger**: Machine-readable API spec
- **Examples**: Show common use cases with cURL/code samples
- **Errors**: Document error codes and meanings

## Git Conventions

### Branching Strategy
- **Main branch**: `main` (always deployable)
- **Feature branches**: `[BACKLOG-ID]/short-description` (e.g., `BL-015/add-user-auth`)
- **Hotfix branches**: `hotfix/description` (for production emergencies)

**Lifetime**: Feature branches live for 1-5 days. Merge frequently, avoid long-lived branches.

### Commit Messages
Format:
```
[BACKLOG-ID] Short summary (50 chars max)

Longer explanation if needed (wrap at 72 chars). Explain what changed
and why, not how (the diff shows how).

Refs: BL-XXX (if related to multiple backlog items)
```

Examples:
- ✅ `[BL-004] Add technical standards document`
- ✅ `[BL-013] Deploy daemon to GitHub Actions`
- ❌ `Fixed stuff` (no context, no traceability)
- ❌ `Updated code` (what changed? why?)

**Rationale**: Commits should tell a story. Six months from now, an agent (or CEO) should be able to read the log and understand why every change happened.

### Merge Strategy
- **Squash and merge**: For feature branches (clean history on main)
- **Regular merge**: For hotfixes (preserve urgency context)
- **No force push**: To main, ever. To feature branches, only if you're the only author.

## Error Handling & Logging

### Error Handling Philosophy
- **Fail fast**: If something is wrong, throw/reject immediately (don't propagate bad state)
- **Fail gracefully**: Catch errors at boundaries (API routes, cron jobs), return meaningful messages
- **No silent failures**: Every error is logged; every user-facing error has a clear message

### Error Handling Patterns

**JavaScript/TypeScript**:
```javascript
// Bad: Silent failure
function getUser(id) {
  try {
    return db.query('SELECT * FROM users WHERE id = ?', [id]);
  } catch (err) {
    return null; // Lost error context!
  }
}

// Good: Propagate with context
function getUser(id) {
  try {
    return db.query('SELECT * FROM users WHERE id = ?', [id]);
  } catch (err) {
    throw new Error(`Failed to get user ${id}: ${err.message}`);
  }
}

// Better: Let caller decide
async function getUser(id) {
  // No try/catch here; let caller handle errors appropriately
  return await db.query('SELECT * FROM users WHERE id = ?', [id]);
}
```

### Logging Standards
**Levels**:
- `DEBUG`: Verbose info for debugging (not in production)
- `INFO`: Normal operations (startup, shutdown, key events)
- `WARN`: Something unexpected but handled (deprecated API used, retrying request)
- `ERROR`: Something failed (log the error, stack trace, and context)

**Structure**: Use structured logging (JSON) for machine parsing:
```javascript
logger.info('User logged in', { userId: 123, ip: '1.2.3.4' });
logger.error('Database query failed', { query: '...', error: err.message, stack: err.stack });
```

**What to log**:
- Request/response at API boundaries
- All errors (with context)
- Key state transitions (job started, completed, failed)
- Security events (auth failures, rate limit hits)

**What NOT to log**:
- Secrets (API keys, passwords, tokens)
- PII without consent (emails, addresses, etc.)
- Full request bodies in production (could contain sensitive data)

## Performance Standards

### Response Time Targets
*(To be refined per product)*
- **API endpoints**: p95 < 200ms for queries, < 500ms for mutations
- **Background jobs**: Complete within 5 minutes or report progress
- **UI interactions**: Respond within 100ms (perceived as instant)

### Resource Limits
- **Memory**: Node processes < 512MB baseline, < 2GB under load
- **CPU**: Background jobs should not peg CPU for >10s continuously
- **Database**: Queries < 100ms p95; use indexes, avoid N+1 queries

### Monitoring
*(To be defined when product ships)*
- **Metrics**: Response times, error rates, throughput
- **Alerts**: Error rate > 1%, p95 latency > 2x baseline
- **Dashboards**: Real-time view of system health

## Accessibility Standards

*(Applicable if product has a web UI)*

- **WCAG 2.1 Level AA**: Minimum compliance target
- **Keyboard navigation**: All features accessible without mouse
- **Screen reader support**: Semantic HTML, ARIA labels where needed
- **Color contrast**: 4.5:1 for text, 3:1 for UI elements
- **Testing**: Run Lighthouse accessibility audit on every PR

## Change Management

### When to Update This Document
Update CONVENTIONS.md when:
1. Adopting a new language or framework (add new section)
2. Changing a standard (update section, log in Changelog below)
3. Discovering a pattern through LEARNINGS.md (codify it here)
4. Quarterly audit (PB-013) identifies gaps or conflicts

### Update Protocol
1. CTO-Agent proposes change with rationale
2. Update this document
3. Notify all active agents (if any) — re-read required
4. Update affected code in next sprint

### Changelog
| Date | Change | Decision Ref |
|------|--------|--------------|
| 2026-02-14 | Initial version — established standards for JS/TS, testing, CI/CD, git, security, docs | BL-004 |

---

*Update protocol: Update whenever adopting new tech, changing a standard, or during quarterly audits (PB-013). All agents must follow these conventions. Product-specific additions go in `[product-repo]/CLAUDE.md`, not here.*
