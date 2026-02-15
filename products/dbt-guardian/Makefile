.PHONY: help install test test-fast lint format type-check security audit clean run

help:  ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies with Poetry
	poetry install

test:  ## Run all tests with coverage
	poetry run pytest --cov --cov-report=term-missing

test-fast:  ## Run tests without coverage (faster)
	poetry run pytest -x

test-unit:  ## Run unit tests only
	poetry run pytest tests/unit/

test-integration:  ## Run integration tests only
	poetry run pytest tests/integration/

test-e2e:  ## Run end-to-end tests only
	poetry run pytest tests/e2e/

lint:  ## Run all linting checks
	poetry run ruff check .
	poetry run black --check .
	poetry run isort --check-only .

format:  ## Auto-format code
	poetry run black .
	poetry run isort .
	poetry run ruff check --fix .

type-check:  ## Run type checking with mypy
	poetry run mypy src/

security:  ## Run security audit
	poetry run pip-audit

audit: lint type-check security test  ## Run all quality checks

clean:  ## Remove build artifacts and cache
	rm -rf dist/
	rm -rf .pytest_cache/
	rm -rf .coverage
	rm -rf .mypy_cache/
	rm -rf .ruff_cache/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete

run:  ## Run the CLI (use 'make run ARGS="analyze /path"' to pass arguments)
	poetry run dbt-guardian $(ARGS)

build:  ## Build package for distribution
	poetry build

publish-test:  ## Publish to Test PyPI
	poetry config repositories.testpypi https://test.pypi.org/legacy/
	poetry publish -r testpypi

publish:  ## Publish to PyPI (use with caution)
	poetry publish

shell:  ## Open Poetry shell
	poetry shell
