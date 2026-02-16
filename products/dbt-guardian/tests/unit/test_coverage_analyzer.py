"""Unit tests for TestCoverageAnalyzer."""

import pytest

from dbt_guardian.analyzers import ColumnGap, TestCoverageAnalyzer, TestType
from dbt_guardian.parsers.manifest import DbtColumn, DbtManifest, DbtModel


@pytest.fixture
def sample_manifest():
    """Create a sample manifest for testing."""
    return DbtManifest(
        models={
            "model.project.users": DbtModel(
                unique_id="model.project.users",
                name="users",
                schema="public",
                columns={
                    "id": DbtColumn(name="id", data_type="integer", tests=["unique"]),
                    "email": DbtColumn(name="email", data_type="varchar", tests=[]),
                    "created_at": DbtColumn(
                        name="created_at", data_type="timestamp", tests=[]
                    ),
                    "status": DbtColumn(name="status", data_type="varchar", tests=[]),
                },
            ),
            "model.project.orders": DbtModel(
                unique_id="model.project.orders",
                name="orders",
                schema="public",
                columns={
                    "order_id": DbtColumn(
                        name="order_id",
                        data_type="integer",
                        tests=["unique", "not_null"],
                    ),
                    "user_id": DbtColumn(
                        name="user_id", data_type="integer", tests=[]
                    ),
                },
            ),
        }
    )


def test_analyze_returns_coverage_report(sample_manifest):
    """Test that analyze returns a CoverageReport."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    assert report.total_models == 2
    assert report.total_columns == 6
    assert report.tested_columns == 2  # id and order_id
    assert 0 <= report.coverage_percentage <= 100


def test_analyze_identifies_id_gaps(sample_manifest):
    """Test that ID columns without tests are identified."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    # users.id is missing not_null
    id_gap = next((g for g in report.gaps if g.column_name == "id"), None)
    assert id_gap is not None
    assert TestType.NOT_NULL in id_gap.suggested_tests
    assert id_gap.priority <= 2  # High priority


def test_analyze_identifies_foreign_key_gaps(sample_manifest):
    """Test that foreign key columns are identified correctly."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    # user_id should suggest not_null and relationships (NOT unique)
    user_id_gap = next((g for g in report.gaps if g.column_name == "user_id"), None)
    assert user_id_gap is not None
    assert TestType.NOT_NULL in user_id_gap.suggested_tests
    assert TestType.RELATIONSHIPS in user_id_gap.suggested_tests
    # Foreign keys should NOT suggest unique (they're not primary keys)
    assert TestType.UNIQUE not in user_id_gap.suggested_tests
    assert user_id_gap.priority == 2  # High priority for FKs


def test_analyze_identifies_timestamp_gaps(sample_manifest):
    """Test that timestamp columns are identified."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    # created_at should suggest not_null
    created_at_gap = next(
        (g for g in report.gaps if g.column_name == "created_at"), None
    )
    assert created_at_gap is not None
    assert TestType.NOT_NULL in created_at_gap.suggested_tests


def test_analyze_identifies_status_gaps(sample_manifest):
    """Test that status columns are identified."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    # status should suggest not_null and accepted_values
    status_gap = next((g for g in report.gaps if g.column_name == "status"), None)
    assert status_gap is not None
    assert TestType.NOT_NULL in status_gap.suggested_tests
    assert TestType.ACCEPTED_VALUES in status_gap.suggested_tests


def test_high_priority_gaps():
    """Test that high_priority_gaps property filters correctly."""
    analyzer = TestCoverageAnalyzer()

    manifest = DbtManifest(
        models={
            "model.project.test": DbtModel(
                unique_id="model.project.test",
                name="test",
                schema="public",
                columns={
                    "id": DbtColumn(name="id", tests=[]),
                    "other_column": DbtColumn(name="other_column", tests=[]),
                },
            )
        }
    )

    report = analyzer.analyze(manifest)

    # id should be high priority (1), other_column lower (5)
    high_priority = report.high_priority_gaps
    assert len(high_priority) >= 1
    assert all(g.priority <= 2 for g in high_priority)


def test_analyze_with_empty_manifest():
    """Test that analyze handles empty manifest gracefully."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(DbtManifest())

    assert report.total_models == 0
    assert report.total_columns == 0
    assert report.coverage_percentage == 0
    assert len(report.gaps) == 0


def test_analyze_respects_existing_tests(sample_manifest):
    """Test that columns with existing tests don't get duplicate suggestions."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    # order_id has unique and not_null, shouldn't suggest those
    order_id_gap = next(
        (g for g in report.gaps if g.column_name == "order_id"), None
    )
    # order_id is fully tested, should not appear in gaps
    assert order_id_gap is None


def test_priority_ordering():
    """Test that gaps are sorted by priority."""
    analyzer = TestCoverageAnalyzer()

    manifest = DbtManifest(
        models={
            "model.project.test": DbtModel(
                unique_id="model.project.test",
                name="test",
                schema="public",
                columns={
                    "id": DbtColumn(name="id", tests=[]),
                    "user_id": DbtColumn(name="user_id", tests=[]),
                    "random_field": DbtColumn(name="random_field", tests=[]),
                },
            )
        }
    )

    report = analyzer.analyze(manifest)

    # Verify gaps are sorted by priority
    priorities = [g.priority for g in report.gaps]
    assert priorities == sorted(priorities)


def test_rationale_generation():
    """Test that rationale strings are meaningful."""
    analyzer = TestCoverageAnalyzer()

    manifest = DbtManifest(
        models={
            "model.project.test": DbtModel(
                unique_id="model.project.test",
                name="test",
                schema="public",
                columns={
                    "id": DbtColumn(name="id", tests=[]),
                },
            )
        }
    )

    report = analyzer.analyze(manifest)
    id_gap = next(g for g in report.gaps if g.column_name == "id")

    # Rationale should mention why tests are suggested
    assert "unique" in id_gap.rationale.lower() or "primary key" in id_gap.rationale.lower()
    assert len(id_gap.rationale) > 0


def test_infer_parent_table():
    """Test that parent tables are correctly inferred from FK column names."""
    analyzer = TestCoverageAnalyzer()

    # Test common patterns
    assert analyzer.infer_parent_table("user_id") == "users"
    assert analyzer.infer_parent_table("customer_id") == "customers"
    assert analyzer.infer_parent_table("order_id") == "orders"
    assert analyzer.infer_parent_table("product_id") == "products"

    # Test edge cases
    assert analyzer.infer_parent_table("id") is None  # Primary key, not FK
    assert analyzer.infer_parent_table("email") is None  # Not an ID column
    assert analyzer.infer_parent_table("status") is None  # Not an ID column


def test_analyze_populates_inferred_parent_table(sample_manifest):
    """Test that inferred parent tables are populated for FK gaps."""
    analyzer = TestCoverageAnalyzer()
    report = analyzer.analyze(sample_manifest)

    # user_id in orders table should have inferred parent
    user_id_gap = next((g for g in report.gaps if g.column_name == "user_id"), None)
    assert user_id_gap is not None
    assert user_id_gap.inferred_parent_table == "users"
