"""Parse dbt catalog.json files.

The catalog contains warehouse metadata: actual columns, types, row counts, freshness.
This complements the manifest with real data warehouse state.
"""

import json
from pathlib import Path
from typing import Any, Dict, Optional

from pydantic import BaseModel, Field


class CatalogColumn(BaseModel):
    """A column from the data warehouse catalog."""

    name: str
    type: str
    index: int
    comment: Optional[str] = None


class CatalogTable(BaseModel):
    """A table from the data warehouse catalog."""

    unique_id: str
    name: str
    schema: str
    database: Optional[str] = None
    columns: Dict[str, CatalogColumn] = Field(default_factory=dict)
    stats: Dict[str, Any] = Field(default_factory=dict)  # row_count, bytes, etc.
    metadata: Dict[str, Any] = Field(default_factory=dict)


class DbtCatalog(BaseModel):
    """Parsed dbt catalog.json."""

    tables: Dict[str, CatalogTable] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class CatalogParser:
    """Parse dbt catalog.json files."""

    def parse(self, catalog_path: Path) -> DbtCatalog:
        """Parse a catalog.json file.

        Args:
            catalog_path: Path to catalog.json

        Returns:
            Parsed catalog

        Raises:
            FileNotFoundError: If catalog doesn't exist
            json.JSONDecodeError: If catalog is invalid JSON
        """
        if not catalog_path.exists():
            raise FileNotFoundError(f"Catalog not found: {catalog_path}")

        with open(catalog_path, "r") as f:
            raw = json.load(f)

        return DbtCatalog(
            tables=self._parse_tables(raw.get("nodes", {}), raw.get("sources", {})),
            metadata=raw.get("metadata", {}),
        )

    def _parse_tables(
        self, nodes: Dict[str, Any], sources: Dict[str, Any]
    ) -> Dict[str, CatalogTable]:
        """Extract tables from catalog nodes and sources."""
        tables = {}

        # Parse model tables
        for unique_id, node in nodes.items():
            tables[unique_id] = self._parse_table(unique_id, node)

        # Parse source tables
        for unique_id, source in sources.items():
            tables[unique_id] = self._parse_table(unique_id, source)

        return tables

    def _parse_table(self, unique_id: str, data: Dict[str, Any]) -> CatalogTable:
        """Parse a single table from catalog data."""
        metadata = data.get("metadata", {})
        return CatalogTable(
            unique_id=unique_id,
            name=metadata.get("name", ""),
            schema=metadata.get("schema", ""),
            database=metadata.get("database"),
            columns=self._parse_columns(data.get("columns", {})),
            stats=data.get("stats", {}),
            metadata=metadata,
        )

    def _parse_columns(self, columns: Dict[str, Any]) -> Dict[str, CatalogColumn]:
        """Extract columns from catalog table."""
        parsed = {}
        for col_name, col_data in columns.items():
            parsed[col_name] = CatalogColumn(
                name=col_data.get("name", col_name),
                type=col_data.get("type", "unknown"),
                index=col_data.get("index", 0),
                comment=col_data.get("comment"),
            )
        return parsed
