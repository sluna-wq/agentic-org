# dbt Guardian

**Autonomous reliability agents for dbt projects.**

## What It Does

dbt Guardian keeps your data pipelines healthy with autonomous agents that:
- **Detect gaps** in test coverage
- **Generate fixes** automatically
- **Open PRs** for review

## Status

🚧 **Alpha** — First agent (Test Generator) in development.

## Vision

Today: Analyze dbt projects, suggest tests.
Tomorrow: Cross-stack remediation — dbt, Snowflake, Airflow, all in one agent.

## Target Users

Mid-market data teams (5-20 engineers) running dbt Core with Snowflake or Postgres.

## Quick Start (Coming Soon)

```bash
# Install
pip install dbt-guardian

# Analyze your project
dbt-guardian analyze /path/to/dbt/project

# Generate test suggestions
dbt-guardian generate-tests /path/to/dbt/project
```

## Roadmap

- [ ] **v0.1**: dbt project parser (manifest.json, catalog, YAML)
- [ ] **v0.2**: Test Generator agent (coverage gap analysis, test generation)
- [ ] **v0.3**: PR automation (GitHub integration, automated PRs)
- [ ] **v1.0**: Production-ready Test Generator
- [ ] **v2.0**: Cross-stack remediation (Snowflake, Postgres, Airflow)

## Development

See [CLAUDE.md](CLAUDE.md) for developer instructions.

## License

MIT
