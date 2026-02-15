"""Parse dbt_project.yml and schema.yml files.

Project files contain configuration and test definitions.
"""

from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml
from pydantic import BaseModel, Field


class DbtProjectConfig(BaseModel):
    """Parsed dbt_project.yml."""

    name: str
    version: str = "1.0.0"
    profile: Optional[str] = None
    model_paths: List[str] = Field(default_factory=lambda: ["models"])
    test_paths: List[str] = Field(default_factory=lambda: ["tests"])
    target_path: str = "target"
    vars: Dict[str, Any] = Field(default_factory=dict)
    models: Dict[str, Any] = Field(default_factory=dict)


class SchemaTest(BaseModel):
    """A test definition from schema.yml."""

    name: str
    column: Optional[str] = None
    config: Dict[str, Any] = Field(default_factory=dict)


class SchemaModel(BaseModel):
    """A model definition from schema.yml."""

    name: str
    description: Optional[str] = None
    columns: List[Dict[str, Any]] = Field(default_factory=list)
    tests: List[SchemaTest] = Field(default_factory=list)


class SchemaFile(BaseModel):
    """Parsed schema.yml file."""

    models: List[SchemaModel] = Field(default_factory=list)
    sources: List[Dict[str, Any]] = Field(default_factory=list)


class ProjectParser:
    """Parse dbt project configuration files."""

    def parse_project(self, project_path: Path) -> DbtProjectConfig:
        """Parse dbt_project.yml.

        Args:
            project_path: Path to dbt_project.yml

        Returns:
            Parsed project config

        Raises:
            FileNotFoundError: If project file doesn't exist
            yaml.YAMLError: If YAML is invalid
        """
        if not project_path.exists():
            raise FileNotFoundError(f"Project file not found: {project_path}")

        with open(project_path, "r") as f:
            raw = yaml.safe_load(f)

        return DbtProjectConfig(
            name=raw.get("name", ""),
            version=raw.get("version", "1.0.0"),
            profile=raw.get("profile"),
            model_paths=raw.get("model-paths", ["models"]),
            test_paths=raw.get("test-paths", ["tests"]),
            target_path=raw.get("target-path", "target"),
            vars=raw.get("vars", {}),
            models=raw.get("models", {}),
        )

    def parse_schema(self, schema_path: Path) -> SchemaFile:
        """Parse a schema.yml file.

        Args:
            schema_path: Path to schema.yml

        Returns:
            Parsed schema file

        Raises:
            FileNotFoundError: If schema file doesn't exist
            yaml.YAMLError: If YAML is invalid
        """
        if not schema_path.exists():
            raise FileNotFoundError(f"Schema file not found: {schema_path}")

        with open(schema_path, "r") as f:
            raw = yaml.safe_load(f)

        return SchemaFile(
            models=self._parse_models(raw.get("models", [])),
            sources=raw.get("sources", []),
        )

    def _parse_models(self, models: List[Dict[str, Any]]) -> List[SchemaModel]:
        """Parse model definitions from schema file."""
        parsed = []
        for model in models:
            parsed.append(
                SchemaModel(
                    name=model.get("name", ""),
                    description=model.get("description"),
                    columns=model.get("columns", []),
                    tests=self._parse_tests(model.get("tests", [])),
                )
            )
        return parsed

    def _parse_tests(self, tests: List[Any]) -> List[SchemaTest]:
        """Parse test definitions."""
        parsed = []
        for test in tests:
            if isinstance(test, str):
                parsed.append(SchemaTest(name=test))
            elif isinstance(test, dict):
                # Handle {test_name: {config}} format
                for name, config in test.items():
                    parsed.append(
                        SchemaTest(
                            name=name,
                            config=config if isinstance(config, dict) else {},
                        )
                    )
        return parsed

    def find_schema_files(self, project_root: Path) -> List[Path]:
        """Find all schema.yml files in a dbt project.

        Args:
            project_root: Root directory of dbt project

        Returns:
            List of schema.yml file paths
        """
        schema_files = []
        for pattern in ["schema.yml", "schema.yaml", "**/schema.yml", "**/schema.yaml"]:
            schema_files.extend(project_root.glob(pattern))
        return list(set(schema_files))  # Deduplicate
