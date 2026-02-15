# Contributing to dbt Guardian

Thank you for considering contributing to dbt Guardian! This document outlines the development workflow and standards.

## Development Setup

### Prerequisites
- Python 3.11 or 3.12
- [Poetry](https://python-poetry.org/) for dependency management
- Git

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/agentic-org/dbt-guardian.git
cd dbt-guardian

# Install dependencies
make install
# OR: poetry install

# Activate virtual environment
poetry shell
```

### Optional: Pre-commit Hooks

Pre-commit hooks run linting and formatting checks before each commit:

```bash
# Install pre-commit
poetry add --group dev pre-commit

# Set up git hooks
poetry run pre-commit install

# Run hooks manually on all files
poetry run pre-commit run --all-files
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# OR: git checkout -b fix/bug-description
```

### 2. Write Code

Follow the conventions in `CLAUDE.md`:
- Type hints on all functions
- Docstrings on public APIs (Google style)
- PEP 8 compliance
- Explicit error handling
- No secrets in code

### 3. Write Tests

We follow the test pyramid:
- **Unit tests** (70%): Fast, isolated, no I/O → `tests/unit/`
- **Integration tests** (20%): Cross-module → `tests/integration/`
- **E2E tests** (10%): Full workflows → `tests/e2e/`

```bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-e2e

# Run tests without coverage (faster)
make test-fast
```

**Coverage requirement**: 80%+ overall, 90%+ for core parsers/generators.

### 4. Quality Checks

```bash
# Format code
make format

# Run all linting
make lint

# Type check
make type-check

# Security audit
make security

# Run everything
make audit
```

### 5. Commit Changes

```bash
git add .
git commit -m "feat: add your feature description"
# OR: git commit -m "fix: fix bug description"
```

**Commit message format**:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Code Style

### Python Style
- **Line length**: 100 characters
- **Type hints**: Required on all functions
- **Docstrings**: Google style for public APIs
- **Naming**:
  - `snake_case` for functions, variables, modules
  - `PascalCase` for classes
  - `UPPER_CASE` for constants

### Example

```python
from typing import Dict, List, Optional
from pydantic import BaseModel


class TestConfig(BaseModel):
    """Configuration for test generation.

    Attributes:
        column_patterns: Patterns to match for test generation
        max_tests_per_model: Maximum number of tests to generate per model
    """
    column_patterns: List[str]
    max_tests_per_model: int = 10


def generate_tests(
    manifest_path: str,
    config: Optional[TestConfig] = None
) -> Dict[str, List[str]]:
    """Generate dbt tests based on manifest analysis.

    Args:
        manifest_path: Path to dbt manifest.json file
        config: Optional configuration for test generation

    Returns:
        Dictionary mapping model names to generated test definitions

    Raises:
        FileNotFoundError: If manifest file doesn't exist
        ValidationError: If manifest format is invalid
    """
    if not os.path.exists(manifest_path):
        raise FileNotFoundError(f"Manifest not found: {manifest_path}")

    # Implementation...
    return {}
```

## Testing Guidelines

### Unit Test Example

```python
import pytest
from dbt_guardian.parsers.manifest import ManifestParser


def test_parse_manifest_valid():
    """Test parsing a valid manifest.json file."""
    parser = ManifestParser("tests/fixtures/valid_manifest.json")
    result = parser.parse()

    assert result is not None
    assert len(result.models) > 0


def test_parse_manifest_missing_file():
    """Test error handling for missing manifest file."""
    parser = ManifestParser("nonexistent.json")

    with pytest.raises(FileNotFoundError):
        parser.parse()
```

### Integration Test Example

```python
import pytest
from dbt_guardian.cli import cli
from click.testing import CliRunner


@pytest.fixture
def sample_project(tmp_path):
    """Create a sample dbt project for testing."""
    # Setup code...
    return project_path


def test_analyze_command_e2e(sample_project):
    """Test the full analyze command workflow."""
    runner = CliRunner()
    result = runner.invoke(cli, ["analyze", str(sample_project)])

    assert result.exit_code == 0
    assert "Coverage Analysis" in result.output
```

## Making Changes to Core Components

### Parsers (`src/dbt_guardian/parsers/`)
- Maintain backwards compatibility with dbt manifest/catalog formats
- Add schema validation for new fields
- Update corresponding Pydantic models
- Add unit tests for each parser function

### Generators (`src/dbt_guardian/generators/`)
- Generate valid YAML that passes dbt parse
- Include clear comments in generated output
- Test with real dbt projects in CI

### CLI (`src/dbt_guardian/cli.py`)
- Use rich for beautiful terminal output
- Provide helpful error messages
- Add `--help` text for new commands
- Test with CliRunner

## CI/CD

All PRs run:
1. **Test workflow** - Tests on Python 3.11 and 3.12
2. **Lint workflow** - ruff, black, isort, mypy, pip-audit

CI must pass before merging.

## Release Process

Releases are handled by maintainers:

1. Update version in `pyproject.toml`
2. Update `CHANGELOG.md`
3. Create release via GitHub Actions workflow
4. Package automatically published to PyPI

## Questions?

- **Bugs**: Open an issue on GitHub
- **Features**: Open an issue for discussion first
- **Questions**: Check existing issues or open a new one

## Code of Conduct

Be respectful and constructive. We're all here to build something useful.

---

Thank you for contributing! 🚀
