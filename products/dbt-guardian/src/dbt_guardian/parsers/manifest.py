"""Parse dbt manifest.json files.

The manifest contains the full dbt DAG: models, tests, dependencies, columns, SQL.
This is the primary artifact for understanding a dbt project.
"""

import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class DbtColumn(BaseModel):
    """A column in a dbt model."""

    name: str
    description: Optional[str] = None
    data_type: Optional[str] = Field(None, alias="type")
    tests: List[str] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)


class DbtModel(BaseModel):
    """A dbt model (table, view, or incremental)."""

    unique_id: str
    name: str
    schema: str
    database: Optional[str] = None
    alias: Optional[str] = None
    description: Optional[str] = None
    columns: Dict[str, DbtColumn] = Field(default_factory=dict)
    depends_on: List[str] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)
    materialized: str = "view"
    sql: Optional[str] = Field(None, alias="compiled_sql")


class DbtTest(BaseModel):
    """A dbt test (schema test or custom test)."""

    unique_id: str
    name: str
    test_type: str  # 'not_null', 'unique', 'accepted_values', 'relationships', 'custom'
    model: str  # Model this test applies to
    column: Optional[str] = None
    config: Dict[str, Any] = Field(default_factory=dict)


class DbtManifest(BaseModel):
    """Parsed dbt manifest.json."""

    models: Dict[str, DbtModel] = Field(default_factory=dict)
    tests: Dict[str, DbtTest] = Field(default_factory=dict)
    sources: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ManifestParser:
    """Parse dbt manifest.json files."""

    def parse(self, manifest_path: Path) -> DbtManifest:
        """Parse a manifest.json file.

        Args:
            manifest_path: Path to manifest.json

        Returns:
            Parsed manifest

        Raises:
            FileNotFoundError: If manifest doesn't exist
            json.JSONDecodeError: If manifest is invalid JSON
            ValueError: If manifest structure is unexpected
        """
        if not manifest_path.exists():
            raise FileNotFoundError(f"Manifest not found: {manifest_path}")

        with open(manifest_path, "r") as f:
            raw = json.load(f)

        return DbtManifest(
            models=self._parse_models(raw.get("nodes", {})),
            tests=self._parse_tests(raw.get("nodes", {})),
            sources=raw.get("sources", {}),
            metadata=raw.get("metadata", {}),
        )

    def _parse_models(self, nodes: Dict[str, Any]) -> Dict[str, DbtModel]:
        """Extract models from manifest nodes."""
        models = {}
        for unique_id, node in nodes.items():
            if node.get("resource_type") == "model":
                models[unique_id] = DbtModel(
                    unique_id=unique_id,
                    name=node.get("name", ""),
                    schema=node.get("schema", ""),
                    database=node.get("database"),
                    alias=node.get("alias"),
                    description=node.get("description"),
                    columns=self._parse_columns(node.get("columns", {})),
                    depends_on=node.get("depends_on", {}).get("nodes", []),
                    tags=node.get("tags", []),
                    materialized=node.get("config", {}).get("materialized", "view"),
                    sql=node.get("compiled_sql"),
                )
        return models

    def _parse_columns(self, columns: Dict[str, Any]) -> Dict[str, DbtColumn]:
        """Extract columns from model definition."""
        parsed = {}
        for col_name, col_data in columns.items():
            parsed[col_name] = DbtColumn(
                name=col_name,
                description=col_data.get("description"),
                data_type=col_data.get("data_type") or col_data.get("type"),
                tests=self._extract_column_tests(col_data),
                tags=col_data.get("tags", []),
            )
        return parsed

    def _extract_column_tests(self, column: Dict[str, Any]) -> List[str]:
        """Extract test names from column definition."""
        tests = []
        for test in column.get("tests", []):
            if isinstance(test, str):
                tests.append(test)
            elif isinstance(test, dict):
                # Handle {'not_null': {...}} format
                tests.extend(test.keys())
        return tests

    def _parse_tests(self, nodes: Dict[str, Any]) -> Dict[str, DbtTest]:
        """Extract tests from manifest nodes."""
        tests = {}
        for unique_id, node in nodes.items():
            if node.get("resource_type") == "test":
                test_type = self._infer_test_type(node)
                tests[unique_id] = DbtTest(
                    unique_id=unique_id,
                    name=node.get("name", ""),
                    test_type=test_type,
                    model=self._extract_test_model(node),
                    column=node.get("column_name"),
                    config=node.get("config", {}),
                )
        return tests

    def _infer_test_type(self, test_node: Dict[str, Any]) -> str:
        """Infer test type from test node."""
        test_metadata = test_node.get("test_metadata", {})
        if test_metadata:
            return test_metadata.get("name", "custom")

        # Fallback: parse from test name
        name = test_node.get("name", "").lower()
        if "not_null" in name:
            return "not_null"
        elif "unique" in name:
            return "unique"
        elif "accepted_values" in name:
            return "accepted_values"
        elif "relationships" in name:
            return "relationships"
        else:
            return "custom"

    def _extract_test_model(self, test_node: Dict[str, Any]) -> str:
        """Extract the model name this test applies to."""
        depends_on = test_node.get("depends_on", {}).get("nodes", [])
        # First dependency is typically the model
        if depends_on:
            return depends_on[0]
        return ""
