"""Tests for ManifestParser."""

import json
from pathlib import Path
from tempfile import NamedTemporaryFile

import pytest

from dbt_guardian.parsers.manifest import ManifestParser, DbtManifest


@pytest.fixture
def sample_manifest():
    """Sample manifest.json data."""
    return {
        "metadata": {
            "dbt_version": "1.7.0",
            "generated_at": "2024-01-01T00:00:00Z",
        },
        "nodes": {
            "model.my_project.customers": {
                "resource_type": "model",
                "name": "customers",
                "schema": "analytics",
                "database": "prod",
                "description": "Customer dimension table",
                "columns": {
                    "customer_id": {
                        "name": "customer_id",
                        "description": "Primary key",
                        "type": "INTEGER",
                        "tests": ["unique", "not_null"],
                    },
                    "email": {
                        "name": "email",
                        "type": "VARCHAR",
                        "tests": [],
                    },
                },
                "depends_on": {"nodes": ["source.my_project.raw_customers"]},
                "tags": ["daily"],
                "config": {"materialized": "table"},
                "compiled_sql": "SELECT * FROM raw_customers",
            },
            "test.my_project.unique_customers_customer_id": {
                "resource_type": "test",
                "name": "unique_customers_customer_id",
                "column_name": "customer_id",
                "test_metadata": {"name": "unique"},
                "depends_on": {"nodes": ["model.my_project.customers"]},
                "config": {},
            },
        },
        "sources": {},
    }


def test_parse_manifest_success(sample_manifest):
    """Test successful manifest parsing."""
    # Write sample manifest to temp file
    with NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump(sample_manifest, f)
        temp_path = Path(f.name)

    try:
        parser = ManifestParser()
        manifest = parser.parse(temp_path)

        assert isinstance(manifest, DbtManifest)
        assert len(manifest.models) == 1
        assert len(manifest.tests) == 1
        assert "model.my_project.customers" in manifest.models

        # Check model details
        model = manifest.models["model.my_project.customers"]
        assert model.name == "customers"
        assert model.schema == "analytics"
        assert model.database == "prod"
        assert model.materialized == "table"
        assert len(model.columns) == 2
        assert "customer_id" in model.columns
        assert model.columns["customer_id"].data_type == "INTEGER"
        assert "unique" in model.columns["customer_id"].tests

    finally:
        temp_path.unlink()


def test_parse_manifest_file_not_found():
    """Test error when manifest doesn't exist."""
    parser = ManifestParser()
    with pytest.raises(FileNotFoundError):
        parser.parse(Path("/nonexistent/manifest.json"))


def test_parse_manifest_invalid_json():
    """Test error with invalid JSON."""
    with NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        f.write("invalid json {")
        temp_path = Path(f.name)

    try:
        parser = ManifestParser()
        with pytest.raises(json.JSONDecodeError):
            parser.parse(temp_path)
    finally:
        temp_path.unlink()


def test_parse_empty_manifest():
    """Test parsing manifest with no nodes."""
    empty_manifest = {"metadata": {}, "nodes": {}, "sources": {}}

    with NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump(empty_manifest, f)
        temp_path = Path(f.name)

    try:
        parser = ManifestParser()
        manifest = parser.parse(temp_path)

        assert len(manifest.models) == 0
        assert len(manifest.tests) == 0
    finally:
        temp_path.unlink()
