"""Generate schema.yml files with test suggestions.

Converts test coverage gaps into PR-ready dbt schema.yml format.
"""

from pathlib import Path
from typing import Dict, List, Optional

import yaml

from ..analyzers.coverage import ColumnGap, CoverageReport, TestType


class SchemaYamlGenerator:
    """Generate dbt schema.yml files from test suggestions."""

    def generate(
        self,
        report: CoverageReport,
        output_path: Optional[Path] = None,
        priority_threshold: int = 5,
    ) -> str:
        """Generate schema.yml content from coverage report.

        Args:
            report: Coverage analysis report
            output_path: Optional path to write YAML file
            priority_threshold: Only include gaps with priority <= threshold (1-5)

        Returns:
            Generated YAML content as string
        """
        # Filter gaps by priority
        gaps = [g for g in report.gaps if g.priority <= priority_threshold]

        # Group gaps by model
        gaps_by_model: Dict[str, List[ColumnGap]] = {}
        for gap in gaps:
            if gap.model_name not in gaps_by_model:
                gaps_by_model[gap.model_name] = []
            gaps_by_model[gap.model_name].append(gap)

        # Build schema structure
        models = []
        for model_name, model_gaps in sorted(gaps_by_model.items()):
            columns = []
            for gap in sorted(model_gaps, key=lambda g: g.column_name):
                tests = self._generate_tests_for_column(gap)
                if tests:
                    columns.append(
                        {
                            "name": gap.column_name,
                            "description": f"[AUTO] {gap.rationale}",
                            "tests": tests,
                        }
                    )

            if columns:
                models.append({"name": model_name, "columns": columns})

        schema = {"version": 2, "models": models}

        # Convert to YAML with nice formatting
        yaml_content = yaml.dump(
            schema,
            default_flow_style=False,
            sort_keys=False,
            allow_unicode=True,
            width=100,
        )

        # Add header comment
        header = self._generate_header(report, priority_threshold)
        full_content = f"{header}\n{yaml_content}"

        # Write to file if path provided
        if output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "w") as f:
                f.write(full_content)

        return full_content

    def _generate_tests_for_column(self, gap: ColumnGap) -> List[Dict]:
        """Generate test configurations for a column.

        Args:
            gap: Column gap with suggested tests

        Returns:
            List of test configurations
        """
        tests = []

        for test_type in gap.suggested_tests:
            if test_type == TestType.NOT_NULL:
                tests.append("not_null")

            elif test_type == TestType.UNIQUE:
                tests.append("unique")

            elif test_type == TestType.ACCEPTED_VALUES:
                # For accepted_values, we add a placeholder
                tests.append(
                    {
                        "accepted_values": {
                            "values": ["TODO: Add valid values"],
                            "config": {"severity": "warn"},
                        }
                    }
                )

            elif test_type == TestType.RELATIONSHIPS:
                # For relationships, use inferred parent table if available
                parent_model = gap.inferred_parent_table or "TODO_parent_model"
                # Infer parent column (usually "id")
                parent_field = "id"

                tests.append(
                    {
                        "relationships": {
                            "to": f"ref('{parent_model}')",
                            "field": parent_field,
                            "config": {"severity": "warn"},
                        }
                    }
                )

        return tests

    def _generate_header(self, report: CoverageReport, priority_threshold: int) -> str:
        """Generate header comment with coverage stats.

        Args:
            report: Coverage analysis report
            priority_threshold: Priority threshold used

        Returns:
            Header comment
        """
        header_lines = [
            "# dbt Guardian - Test Coverage Suggestions",
            "#",
            f"# Coverage: {report.coverage_percentage:.1f}% ({report.tested_columns}/{report.total_columns} columns)",
            f"# Models analyzed: {report.total_models}",
            f"# Gaps found: {len(report.gaps)} (showing priority <= {priority_threshold})",
            "#",
            "# This file contains AI-generated test suggestions. Review and customize before use.",
            "# - For 'accepted_values', replace TODO with actual valid values",
            "# - For 'relationships', parent tables are auto-inferred (e.g., user_id -> users)",
            "#   Verify the inferred parent model and field are correct",
            "# - Remove [AUTO] prefix from descriptions and add domain context",
        ]
        return "\n".join(header_lines)

    def generate_incremental(
        self,
        report: CoverageReport,
        existing_schema_path: Path,
        output_path: Optional[Path] = None,
        priority_threshold: int = 5,
    ) -> str:
        """Merge suggestions into existing schema.yml.

        Args:
            report: Coverage analysis report
            existing_schema_path: Path to existing schema.yml
            output_path: Optional path to write merged YAML
            priority_threshold: Only include gaps with priority <= threshold

        Returns:
            Merged YAML content as string

        Raises:
            FileNotFoundError: If existing schema doesn't exist
            yaml.YAMLError: If existing schema is invalid
        """
        # Load existing schema
        if not existing_schema_path.exists():
            raise FileNotFoundError(f"Schema not found: {existing_schema_path}")

        with open(existing_schema_path, "r") as f:
            existing = yaml.safe_load(f)

        if not existing or "models" not in existing:
            # If empty or invalid, generate from scratch
            return self.generate(report, output_path, priority_threshold)

        # Build index of existing models and columns
        existing_models = {m["name"]: m for m in existing.get("models", [])}

        # Filter gaps by priority
        gaps = [g for g in report.gaps if g.priority <= priority_threshold]

        # Merge suggestions
        for gap in gaps:
            if gap.model_name not in existing_models:
                # Add new model
                existing_models[gap.model_name] = {
                    "name": gap.model_name,
                    "columns": [],
                }

            model = existing_models[gap.model_name]
            if "columns" not in model:
                model["columns"] = []

            # Find or create column
            existing_cols = {c["name"]: c for c in model["columns"]}
            if gap.column_name not in existing_cols:
                # Add new column
                tests = self._generate_tests_for_column(gap)
                model["columns"].append(
                    {
                        "name": gap.column_name,
                        "description": f"[AUTO] {gap.rationale}",
                        "tests": tests,
                    }
                )
            else:
                # Append tests to existing column
                column = existing_cols[gap.column_name]
                if "tests" not in column:
                    column["tests"] = []

                existing_test_names = self._extract_test_names(column["tests"])
                new_tests = self._generate_tests_for_column(gap)

                for test in new_tests:
                    test_name = test if isinstance(test, str) else list(test.keys())[0]
                    if test_name not in existing_test_names:
                        column["tests"].append(test)

        # Rebuild models list
        existing["models"] = list(existing_models.values())

        # Convert to YAML
        yaml_content = yaml.dump(
            existing,
            default_flow_style=False,
            sort_keys=False,
            allow_unicode=True,
            width=100,
        )

        # Add header
        header = self._generate_header(report, priority_threshold)
        full_content = f"{header}\n{yaml_content}"

        # Write to file if path provided
        if output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "w") as f:
                f.write(full_content)

        return full_content

    def _extract_test_names(self, tests: List) -> set:
        """Extract test names from test definitions.

        Args:
            tests: List of test definitions (strings or dicts)

        Returns:
            Set of test names
        """
        names = set()
        for test in tests:
            if isinstance(test, str):
                names.add(test)
            elif isinstance(test, dict):
                names.update(test.keys())
        return names
