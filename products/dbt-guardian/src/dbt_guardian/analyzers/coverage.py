"""Analyze test coverage gaps in dbt projects.

Identifies columns that lack tests (not_null, unique, etc.) and prioritizes them
based on column type, position, and model importance.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Set

from ..parsers.catalog import CatalogColumn, DbtCatalog
from ..parsers.manifest import DbtColumn, DbtManifest, DbtModel


class TestType(str, Enum):
    """Types of dbt schema tests."""

    NOT_NULL = "not_null"
    UNIQUE = "unique"
    ACCEPTED_VALUES = "accepted_values"
    RELATIONSHIPS = "relationships"


@dataclass
class ColumnGap:
    """A column that lacks test coverage."""

    model_name: str
    column_name: str
    column_type: Optional[str]
    existing_tests: List[str]
    suggested_tests: List[TestType]
    priority: int  # 1 (high) to 5 (low)
    rationale: str


@dataclass
class CoverageReport:
    """Test coverage analysis for a dbt project."""

    total_models: int
    total_columns: int
    tested_columns: int
    coverage_percentage: float
    gaps: List[ColumnGap]

    @property
    def high_priority_gaps(self) -> List[ColumnGap]:
        """Return gaps with priority 1-2."""
        return [g for g in self.gaps if g.priority <= 2]


class TestCoverageAnalyzer:
    """Analyze test coverage gaps in dbt projects."""

    # Column name patterns that suggest specific tests
    # Note: Foreign key check (ends_with "_id") runs first, so this catches primary keys
    ID_PATTERNS = {"id", "_id", "uuid", "_key"}
    TIMESTAMP_PATTERNS = {"created_at", "updated_at", "deleted_at", "timestamp"}
    STATUS_PATTERNS = {"status", "state", "type", "_type"}

    # Data types that suggest specific tests
    NULLABLE_TYPES = {"string", "text", "varchar", "timestamp", "date", "number", "float"}
    ID_TYPES = {"int", "integer", "bigint", "uuid"}

    def analyze(
        self, manifest: DbtManifest, catalog: Optional[DbtCatalog] = None
    ) -> CoverageReport:
        """Analyze test coverage for a dbt project.

        Args:
            manifest: Parsed dbt manifest
            catalog: Optional parsed catalog (for warehouse column types)

        Returns:
            Coverage report with gaps and suggestions
        """
        gaps: List[ColumnGap] = []
        total_columns = 0
        tested_columns = 0

        for model_id, model in manifest.models.items():
            # Get catalog data if available
            catalog_table = None
            if catalog:
                catalog_table = catalog.tables.get(model_id)

            # Analyze each column
            for col_name, column in model.columns.items():
                total_columns += 1

                # Get actual column type from catalog
                col_type = column.data_type
                if catalog_table and col_name in catalog_table.columns:
                    col_type = catalog_table.columns[col_name].type

                # Check if column has tests
                existing_tests = column.tests
                if existing_tests:
                    tested_columns += 1

                # Identify test gaps
                suggested_tests = self._suggest_tests(
                    col_name, col_type, existing_tests, model
                )

                if suggested_tests:
                    gaps.append(
                        ColumnGap(
                            model_name=model.name,
                            column_name=col_name,
                            column_type=col_type,
                            existing_tests=existing_tests,
                            suggested_tests=suggested_tests,
                            priority=self._calculate_priority(
                                col_name, col_type, suggested_tests, model
                            ),
                            rationale=self._build_rationale(
                                col_name, col_type, suggested_tests
                            ),
                        )
                    )

        # Calculate coverage
        coverage_pct = (tested_columns / total_columns * 100) if total_columns > 0 else 0

        # Sort gaps by priority
        gaps.sort(key=lambda g: (g.priority, g.model_name, g.column_name))

        return CoverageReport(
            total_models=len(manifest.models),
            total_columns=total_columns,
            tested_columns=tested_columns,
            coverage_percentage=coverage_pct,
            gaps=gaps,
        )

    def _suggest_tests(
        self,
        col_name: str,
        col_type: Optional[str],
        existing_tests: List[str],
        model: DbtModel,
    ) -> List[TestType]:
        """Suggest tests for a column based on name and type.

        Args:
            col_name: Column name
            col_type: Column data type (from catalog or manifest)
            existing_tests: Tests already defined
            model: The model this column belongs to

        Returns:
            List of suggested test types
        """
        suggestions: Set[TestType] = set()
        col_lower = col_name.lower()
        type_lower = (col_type or "").lower()
        model_lower = model.name.lower()

        # Foreign key patterns: ends with _id but prefix doesn't match model name
        # (e.g., user_id in orders table is FK, but order_id in orders table is PK)
        # Extract prefix before _id (e.g., "user" from "user_id")
        col_prefix = col_lower[:-3] if col_lower.endswith("_id") else ""

        # Check if this is a foreign key (prefix doesn't match model name)
        # Handle both singular and plural model names (orders/order, users/user)
        is_foreign_key = (
            col_lower.endswith("_id")
            and col_lower != "id"
            and col_prefix != model_lower  # exact match
            and col_prefix != model_lower.rstrip('s')  # orders -> order
            and col_prefix + 's' != model_lower  # user -> users
        )

        if is_foreign_key:
            if TestType.NOT_NULL.value not in existing_tests:
                suggestions.add(TestType.NOT_NULL)
            # Relationships test is more complex - needs target model
            # We'll suggest it but note it requires configuration
            if TestType.RELATIONSHIPS.value not in existing_tests:
                suggestions.add(TestType.RELATIONSHIPS)

        # ID columns should be unique and not null (primary keys)
        # This catches "id", "order_id" in orders table, "uuid", "_key" suffix
        elif any(pattern in col_lower for pattern in self.ID_PATTERNS):
            if TestType.NOT_NULL.value not in existing_tests:
                suggestions.add(TestType.NOT_NULL)
            if TestType.UNIQUE.value not in existing_tests:
                suggestions.add(TestType.UNIQUE)

        # Timestamp columns should typically be not null
        elif any(pattern in col_lower for pattern in self.TIMESTAMP_PATTERNS):
            if TestType.NOT_NULL.value not in existing_tests:
                suggestions.add(TestType.NOT_NULL)

        # Status/type columns are good candidates for accepted_values
        elif any(pattern in col_lower for pattern in self.STATUS_PATTERNS):
            if TestType.NOT_NULL.value not in existing_tests:
                suggestions.add(TestType.NOT_NULL)
            if TestType.ACCEPTED_VALUES.value not in existing_tests:
                suggestions.add(TestType.ACCEPTED_VALUES)

        # Generic nullability check for important types
        elif any(t in type_lower for t in self.NULLABLE_TYPES):
            # Don't suggest not_null for every column - only high-value ones
            pass

        return list(suggestions)

    def _calculate_priority(
        self,
        col_name: str,
        col_type: Optional[str],
        suggested_tests: List[TestType],
        model: DbtModel,
    ) -> int:
        """Calculate priority score (1=high, 5=low).

        Args:
            col_name: Column name
            col_type: Column data type
            suggested_tests: Suggested test types
            model: The model this column belongs to

        Returns:
            Priority score
        """
        col_lower = col_name.lower()
        model_lower = model.name.lower()

        # Priority 1: Primary keys (id, uuid) - high priority even if just missing one test
        if col_lower in {"id", "uuid"}:
            return 1

        # Also priority 1: table_id in its own table (e.g., order_id in orders)
        col_prefix = col_lower[:-3] if col_lower.endswith("_id") else ""
        if col_prefix and (col_prefix == model_lower or col_prefix == model_lower.rstrip('s') or col_prefix + 's' == model_lower):
            return 1

        # Priority 2: Foreign keys and critical timestamps
        if col_lower.endswith("_id") or col_lower in {"created_at", "updated_at"}:
            return 2

        # Priority 3: Status/type columns
        if any(pattern in col_lower for pattern in self.STATUS_PATTERNS):
            return 3

        # Priority 4: Other timestamp columns
        if any(pattern in col_lower for pattern in self.TIMESTAMP_PATTERNS):
            return 4

        # Priority 5: Everything else
        return 5

    def _build_rationale(
        self, col_name: str, col_type: Optional[str], suggested_tests: List[TestType]
    ) -> str:
        """Build human-readable rationale for test suggestions.

        Args:
            col_name: Column name
            col_type: Column data type
            suggested_tests: Suggested test types

        Returns:
            Rationale string
        """
        col_lower = col_name.lower()
        reasons = []

        if TestType.UNIQUE in suggested_tests:
            if col_lower in {"id", "uuid"}:
                reasons.append("Primary key should be unique")
            else:
                reasons.append("ID column should be unique")

        if TestType.NOT_NULL in suggested_tests:
            if col_lower in {"id", "uuid"}:
                reasons.append("Primary key cannot be null")
            elif col_lower.endswith("_id"):
                reasons.append("Foreign key should not be null")
            elif any(p in col_lower for p in self.TIMESTAMP_PATTERNS):
                reasons.append("Timestamp columns are typically required")
            elif any(p in col_lower for p in self.STATUS_PATTERNS):
                reasons.append("Status column should have a value")

        if TestType.ACCEPTED_VALUES in suggested_tests:
            reasons.append("Status/type column should have defined values")

        if TestType.RELATIONSHIPS in suggested_tests:
            reasons.append("Foreign key should reference parent table")

        return "; ".join(reasons) if reasons else "Missing test coverage"
