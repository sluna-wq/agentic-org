# CLAUDE.md — dbt Guardian Product

> **Agent instructions for working in the dbt Guardian codebase.**
> Read this first. It defines tech stack, conventions, architecture, and how to contribute.

## What This Product Is

**dbt Guardian** — Autonomous reliability agents for dbt projects.

**Mission**: Keep data pipelines healthy 24/7 with agents that detect gaps, generate fixes, and open PRs. Starting with dbt Core users (not dbt Cloud). First agent: Test Generator.

**Strategic positioning**: Work with the data stack, then hollow it out. Start alongside dbt (and Snowflake, Postgres, etc.), make them interchangeable over time. Entry point: dbt test coverage. Moat: cross-stack remediation.

## Tech Stack

- **Language**: Python 3.11+ (latest stable)
- **Package manager**: Poetry
- **Agent framework**: Anthropic Claude Agent SDK
- **CLI**: click + rich (beautiful terminal UI)
- **Testing**: pytest + pytest-cov (aim for 80%+ coverage)
- **Linting**: ruff (fast, comprehensive)
- **Formatting**: black + isort
- **Type checking**: mypy (strict mode)
- **Security**: pip-audit (dependency scanning)
- **CI/CD**: GitHub Actions
- **Distribution**: PyPI (when ready)

## Project Structure

```
products/dbt-guardian/
├── CLAUDE.md              ← You are here (agent instructions)
├── README.md              ← User-facing product docs
├── LICENSE                ← MIT
├── pyproject.toml         ← Poetry config, dependencies, tooling
├── .github/workflows/     ← CI/CD pipelines
│   ├── test.yml           ← Run tests on every PR
│   ├── lint.yml           ← Code quality checks
│   └── release.yml        ← PyPI publishing (manual trigger)
├── src/dbt_guardian/      ← Source code
│   ├── __init__.py
│   ├── cli.py             ← Main CLI entrypoint
│   ├── parsers/           ← dbt project parsing (manifest, catalog, YAML)
│   ├── analyzers/         ← Gap detection, impact analysis
│   ├── generators/        ← Test generation, PR creation
│   ├── agents/            ← Autonomous agent orchestration
│   └── utils/             ← Shared utilities
└── tests/                 ← Test suite
    ├── unit/              ← Fast, isolated tests
    ├── integration/       ← Cross-module tests with fixtures
    └── e2e/               ← Full workflow tests with real dbt projects
```

## Code Conventions

### Python Style
- **PEP 8** compliance (enforced by ruff + black)
- **Type hints** on all functions (enforced by mypy)
- **Docstrings** on all public APIs (Google style)
- **Explicit over clever** — readability beats brevity
- **Functional where possible** — prefer pure functions, minimize state

### Naming
- `snake_case` for functions, variables, modules
- `PascalCase` for classes
- `UPPER_CASE` for constants
- Descriptive names — `parse_manifest_json()` not `parse()`

### Error Handling
- **Explicit exceptions** — never silently fail
- **Rich error context** — what failed, why, what to do
- **User-facing errors** — show in terminal with rich formatting
- **Agent-facing errors** — structured for retry/escalation

### Logging
- **Structured logging** — use Python `logging` module
- **Log levels**: DEBUG (internals), INFO (progress), WARNING (recoverable), ERROR (failures)
- **No secrets in logs** — sanitize credentials, tokens, PII

## Testing Strategy

### Test Pyramid
- **Unit tests** (70%): Fast, isolated, no I/O. Test individual functions.
- **Integration tests** (20%): Cross-module. Use fixtures for dbt projects.
- **E2E tests** (10%): Full workflows. Slow but high confidence.

### Fixtures
- Store sample dbt projects in `tests/fixtures/dbt_projects/`
- Include `manifest.json`, `catalog.json`, `dbt_project.yml` for various scenarios
- Small projects (<10 models) for fast tests

### Coverage
- **Target**: 80%+ overall, 90%+ for core parsers/generators
- **CI fails** if coverage drops below 70%
- **Focus**: Test behaviors, not implementation details

## CLI Interface

```bash
# Install
pip install dbt-guardian

# Analyze a dbt project
dbt-guardian analyze /path/to/dbt/project

# Generate test suggestions
dbt-guardian generate-tests /path/to/dbt/project --output schema.yml

# Run as agent (future)
dbt-guardian agent --config guardian.yml
```

### CLI Principles
- **Beautiful output** — use rich for progress bars, tables, colors
- **Helpful errors** — tell users exactly what's wrong and how to fix it
- **Non-intrusive** — read-only by default, explicit for writes
- **Fast feedback** — show progress for long operations

## dbt Integration

### What We Parse
1. **`manifest.json`** — dbt DAG (models, tests, columns, dependencies)
2. **`catalog.json`** — Warehouse metadata (actual columns, types)
3. **`schema.yml`** — Existing test definitions
4. **`dbt_project.yml`** — Project config
5. **SQL files** — Model definitions (via manifest)

### Where Files Live
- dbt project root: `dbt_project.yml`
- Target directory: `target/manifest.json`, `target/catalog.json`
- Models directory: `models/**/*.sql`, `models/**/*.yml`

### Key dbt Concepts
- **Models**: SQL transformations (tables/views)
- **Tests**: Data quality checks (schema.yml or tests/ directory)
- **Sources**: External tables
- **Refs**: Model dependencies (`{{ ref('model_name') }}`)
- **Tests types**: `not_null`, `unique`, `accepted_values`, `relationships`, custom

## Agent Architecture (Future)

When we add autonomous agent capabilities:
- **Orchestration**: Claude Agent SDK
- **MCP servers**: dbt, GitHub, Snowflake, Postgres
- **State management**: Persistent session storage
- **Error handling**: Retry with exponential backoff
- **Observability**: OpenTelemetry tracing

## Security

- **No credentials in code** — use environment variables
- **Audit dependencies** — `pip-audit` in CI
- **Minimal permissions** — read-only unless explicitly writing
- **Input validation** — sanitize all file paths, SQL, YAML
- **SQL injection prevention** — parameterized queries only

## Performance

- **Lazy loading** — parse manifest only when needed
- **Caching** — cache parsed manifest between operations
- **Streaming** — process large files in chunks
- **Parallelization** — analyze models concurrently where safe

## Development Workflow

### Setup
```bash
cd products/dbt-guardian
make install               # OR: poetry install
poetry shell
```

### Run tests
```bash
make test                  # All tests with coverage
make test-fast             # Without coverage (faster)
make test-unit             # Unit tests only
make test-integration      # Integration tests only
make test-e2e              # E2E tests only
```

### Quality checks
```bash
make lint                  # All linting checks
make format                # Auto-format code
make type-check            # Type checking with mypy
make security              # Security audit
make audit                 # Run all checks
```

### Run CLI locally
```bash
make run                   # Show help
make run ARGS="analyze /path/to/dbt/project"
# OR: poetry run dbt-guardian --help
```

### VS Code Setup
The `.vscode/` directory contains:
- **settings.json** - Python interpreter, formatters, linters
- **extensions.json** - Recommended extensions
- **launch.json** - Debug configurations

Open the project in VS Code and install recommended extensions when prompted.

### Pre-commit Hooks (Optional)
```bash
poetry add --group dev pre-commit
poetry run pre-commit install
poetry run pre-commit run --all-files
```

## CI/CD

GitHub Actions workflows in `.github/workflows/`:

- **test.yml** - Runs on every PR and push to main
  - Tests on Python 3.11 and 3.12
  - Coverage reporting to Codecov
  - Caches dependencies for faster runs

- **lint.yml** - Runs on every PR and push to main
  - ruff (linting)
  - black (formatting)
  - isort (import sorting)
  - mypy (type checking)
  - pip-audit (security)

- **release.yml** - Manual trigger only
  - Runs full test suite
  - Builds package
  - Publishes to PyPI with trusted publishing
  - Creates GitHub release with artifacts

## Distribution

- **Package name**: `dbt-guardian`
- **PyPI**: https://pypi.org/project/dbt-guardian/ (when released)
- **Versioning**: Semantic versioning (0.1.0 → 0.2.0 → 1.0.0)
- **Changelog**: Keep updated in README.md

## What's Next

See the org-level `BACKLOG.md` for prioritized work. Current focus:
1. **BL-015**: dbt project parser (manifest.json, catalog, YAML)
2. **BL-016**: Test Generator agent v0
3. **BL-017**: Pilot plan

---
*Update protocol: Update when tech stack changes, architecture evolves, or new conventions are established. This is the single source of truth for "how to work in this codebase." Keep it comprehensive but scannable.*
