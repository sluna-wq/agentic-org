"""Unit tests for SchemaYamlGenerator."""

import pytest
import yaml

from dbt_guardian.analyzers import ColumnGap, CoverageReport, TestType
from dbt_guardian.generators import SchemaYamlGenerator


@pytest.fixture
def sample_report():
    """Create a sample coverage report for testing."""
    gaps = [
        ColumnGap(
            model_name="users",
            column_name="id",
            column_type="integer",
            existing_tests=[],
            suggested_tests=[TestType.NOT_NULL, TestType.UNIQUE],
            priority=1,
            rationale="Primary key should be unique and not null",
        ),
        ColumnGap(
            model_name="users",
            column_name="email",
            column_type="varchar",
            existing_tests=[],
            suggested_tests=[TestType.NOT_NULL],
            priority=3,
            rationale="Email should not be null",
        ),
        ColumnGap(
            model_name="orders",
            column_name="status",
            column_type="varchar",
            existing_tests=[],
            suggested_tests=[TestType.NOT_NULL, TestType.ACCEPTED_VALUES],
            priority=3,
            rationale="Status column should have defined values",
        ),
        ColumnGap(
            model_name="orders",
            column_name="user_id",
            column_type="integer",
            existing_tests=[],
            suggested_tests=[TestType.NOT_NULL, TestType.RELATIONSHIPS],
            priority=2,
            rationale="Foreign key should reference parent table",
        ),
    ]

    return CoverageReport(
        total_models=2,
        total_columns=10,
        tested_columns=6,
        coverage_percentage=60.0,
        gaps=gaps,
    )


def test_generate_creates_valid_yaml(sample_report):
    """Test that generate creates valid YAML."""
    generator = SchemaYamlGenerator()
    yaml_content = generator.generate(sample_report)

    # Should be valid YAML
    parsed = yaml.safe_load(yaml_content)
    assert parsed is not None
    assert "version" in parsed
    assert parsed["version"] == 2
    assert "models" in parsed


def test_generate_includes_all_models(sample_report):
    """Test that all models with gaps are included."""
    generator = SchemaYamlGenerator()
    yaml_content = generator.generate(sample_report)

    parsed = yaml.safe_load(yaml_content)
    model_names = {m["name"] for m in parsed["models"]}
    assert "users" in model_names
    assert "orders" in model_names


def test_generate_includes_test_suggestions(sample_report):
    """Test that test suggestions are included."""
    generator = SchemaYamlGenerator()
    yaml_content = generator.generate(sample_report)

    parsed = yaml.safe_load(yaml_content)

    # Find users model
    users = next(m for m in parsed["models"] if m["name"] == "users")
    id_col = next(c for c in users["columns"] if c["name"] == "id")

    # Should have not_null and unique tests
    tests = id_col["tests"]
    assert "not_null" in tests
    assert "unique" in tests


def test_generate_includes_placeholders_for_complex_tests(sample_report):
    """Test that accepted_values and relationships have placeholders."""
    generator = SchemaYamlGenerator()
    yaml_content = generator.generate(sample_report)

    parsed = yaml.safe_load(yaml_content)

    # Find orders model
    orders = next(m for m in parsed["models"] if m["name"] == "orders")

    # Check accepted_values placeholder
    status_col = next(c for c in orders["columns"] if c["name"] == "status")
    accepted_values_test = next(
        (t for t in status_col["tests"] if isinstance(t, dict) and "accepted_values" in t),
        None,
    )
    assert accepted_values_test is not None
    assert "TODO" in str(accepted_values_test["accepted_values"]["values"])

    # Check relationships placeholder
    user_id_col = next(c for c in orders["columns"] if c["name"] == "user_id")
    relationships_test = next(
        (t for t in user_id_col["tests"] if isinstance(t, dict) and "relationships" in t),
        None,
    )
    assert relationships_test is not None
    assert "TODO" in relationships_test["relationships"]["to"]


def test_generate_respects_priority_threshold(sample_report):
    """Test that priority threshold filters gaps."""
    generator = SchemaYamlGenerator()

    # Only include priority 1-2
    yaml_content = generator.generate(sample_report, priority_threshold=2)
    parsed = yaml.safe_load(yaml_content)

    # Should only have users.id (priority 1) and orders.user_id (priority 2)
    total_columns = sum(len(m["columns"]) for m in parsed["models"])
    assert total_columns == 2  # id and user_id only


def test_generate_includes_header(sample_report):
    """Test that generated YAML includes header comment."""
    generator = SchemaYamlGenerator()
    yaml_content = generator.generate(sample_report)

    # Header should include coverage stats
    assert "dbt Guardian" in yaml_content
    assert "60.0%" in yaml_content
    assert "Coverage:" in yaml_content


def test_generate_includes_descriptions(sample_report):
    """Test that columns have descriptions with rationale."""
    generator = SchemaYamlGenerator()
    yaml_content = generator.generate(sample_report)

    parsed = yaml.safe_load(yaml_content)
    users = next(m for m in parsed["models"] if m["name"] == "users")
    id_col = next(c for c in users["columns"] if c["name"] == "id")

    # Description should include rationale
    assert "description" in id_col
    assert "[AUTO]" in id_col["description"]
    assert len(id_col["description"]) > 0


def test_generate_with_empty_report():
    """Test that generate handles empty report."""
    generator = SchemaYamlGenerator()
    empty_report = CoverageReport(
        total_models=0,
        total_columns=0,
        tested_columns=0,
        coverage_percentage=0,
        gaps=[],
    )

    yaml_content = generator.generate(empty_report)
    parsed = yaml.safe_load(yaml_content)

    assert parsed["models"] == []


def test_generate_writes_to_file(sample_report, tmp_path):
    """Test that generate can write to a file."""
    generator = SchemaYamlGenerator()
    output_path = tmp_path / "schema.yml"

    generator.generate(sample_report, output_path=output_path)

    assert output_path.exists()
    content = output_path.read_text()
    parsed = yaml.safe_load(content)
    assert parsed is not None


def test_generate_incremental_preserves_existing(sample_report, tmp_path):
    """Test that incremental generation preserves existing content."""
    # Create existing schema
    existing_schema = {
        "version": 2,
        "models": [
            {
                "name": "users",
                "columns": [
                    {
                        "name": "email",
                        "description": "User email address",
                        "tests": ["unique"],  # Existing test
                    }
                ],
            }
        ],
    }

    existing_path = tmp_path / "existing.yml"
    with open(existing_path, "w") as f:
        yaml.dump(existing_schema, f)

    # Generate incremental
    generator = SchemaYamlGenerator()
    output_path = tmp_path / "merged.yml"
    generator.generate_incremental(sample_report, existing_path, output_path)

    # Check merged content
    with open(output_path) as f:
        merged = yaml.safe_load(f)

    users = next(m for m in merged["models"] if m["name"] == "users")
    email_col = next(c for c in users["columns"] if c["name"] == "email")

    # Should preserve existing description and test
    assert email_col["description"] == "User email address"
    assert "unique" in email_col["tests"]
    # Should add new test
    assert "not_null" in email_col["tests"]


def test_generate_incremental_adds_new_models(sample_report, tmp_path):
    """Test that incremental generation adds new models."""
    # Existing schema with only one model
    existing_schema = {
        "version": 2,
        "models": [
            {
                "name": "users",
                "columns": [],
            }
        ],
    }

    existing_path = tmp_path / "existing.yml"
    with open(existing_path, "w") as f:
        yaml.dump(existing_schema, f)

    # Generate incremental
    generator = SchemaYamlGenerator()
    output_path = tmp_path / "merged.yml"
    generator.generate_incremental(sample_report, existing_path, output_path)

    # Check that orders model was added
    with open(output_path) as f:
        merged = yaml.safe_load(f)

    model_names = {m["name"] for m in merged["models"]}
    assert "users" in model_names
    assert "orders" in model_names
