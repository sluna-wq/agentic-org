# Agent Toolset Specification — Agent Data Engineer

**Version:** 1.0
**Date:** 2026-02-19
**Status:** Draft — feeds implementation phase
**Depends On:** research/sdkification.md (BL-023)
**Related:** research/product-thesis-v1.md (BL-024)

---

## Purpose

This document defines the concrete MCP tool signatures an Agent Data Engineer needs to operate a modern data stack (dbt + Snowflake/BigQuery + Airflow/Prefect + Looker/Metabase) entirely through structured SDK and API calls — no browser automation, no HTML parsing, no screenshots. It is the direct translation of the seven tool categories identified in the SDKification research (BL-023) into implementable specifications: every tool is named, every parameter is typed, every return shape is shown with realistic data. The primary audience is the developer building the MCP server(s). The secondary audience is the CTO-Agent selecting which tools to build first and in what order. Nothing in this document is aspirational — every tool described here has a concrete API or SDK backing it, as documented in sdkification.md.

---

## Design Principles

- **Tool granularity:** One tool per atomic operation. Not one tool for "investigate a pipeline failure" — that is an agent workflow, not a tool. Tools are the primitives; the agent composes them.
- **Return types:** Always structured data (dicts, lists of dicts, typed fields). Never raw HTML, never screenshots, never unstructured log blobs (logs are returned as text, but errors within them are structured by separate tools like `orchestrator_detect_patterns`).
- **Error handling:** Tools must return errors as structured data. A tool that cannot connect to Snowflake returns `{"error": "connection_failed", "detail": "..."}` — it does not raise an unhandled exception and crash the agent. The agent needs to be able to reason about tool failures.
- **MCP annotations:** All tools annotated per the Agent Skills Open Standard (agentskills.io, Dec 2025): `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`. These annotations allow the agent runtime to reason about tool safety before execution.
- **Credential management:** Connection details (host, account, database, API keys) are passed at MCP server initialization — not per tool call. Tool calls contain only operational parameters. This keeps secrets out of agent context windows and audit logs.

---

## Tool Catalog

---

### Category 1: dbt Artifact Tools

**MCP Server name:** `dbt-artifacts`

**What this server does:** Reads and interprets the four dbt artifact files (`manifest.json`, `catalog.json`, `run_results.json`, `sources.json`). All operations are local filesystem reads and JSON parsing — no network calls, no warehouse connection. This is the fastest and most reliable tool category; these artifacts are the ground truth for dbt project structure, lineage, schema, test definitions, and run outcomes.

**Server init parameters:**
- `project_path: str` — absolute path to the dbt project root
- `target_path: str` — path to the `target/` directory containing compiled artifacts (defaults to `{project_path}/target`)

---

#### `dbt_get_lineage`

**Description:** Returns the dependency graph for a given dbt node, traversing upstream (dependencies) or downstream (dependents) to a specified depth. Reads `manifest.json`. Useful for understanding blast radius before making a change, or for tracing a data quality issue back to its source.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_id` | `str` | Yes | The dbt unique node ID. Format: `model.project_name.model_name` or `source.project_name.source_name.table_name`. Example: `model.jaffle_shop.orders` |
| `direction` | `"upstream" \| "downstream"` | Yes | `upstream` returns nodes this node depends on. `downstream` returns nodes that depend on this node. |
| `depth` | `int \| None` | No | How many hops to traverse. `None` means full traversal (entire upstream/downstream tree). Default: `None`. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_get_lineage",
  "params": {
    "node_id": "model.jaffle_shop.orders",
    "direction": "downstream",
    "depth": 2
  }
}
```

**Example response shape:**
```json
{
  "root_node": "model.jaffle_shop.orders",
  "direction": "downstream",
  "depth": 2,
  "nodes": [
    {
      "node_id": "model.jaffle_shop.orders",
      "resource_type": "model",
      "name": "orders",
      "schema": "dbt_prod",
      "materialization": "table",
      "depth": 0
    },
    {
      "node_id": "model.jaffle_shop.fct_orders",
      "resource_type": "model",
      "name": "fct_orders",
      "schema": "dbt_prod",
      "materialization": "table",
      "depth": 1
    },
    {
      "node_id": "model.jaffle_shop.revenue_by_month",
      "resource_type": "model",
      "name": "revenue_by_month",
      "schema": "dbt_prod",
      "materialization": "view",
      "depth": 2
    }
  ],
  "edges": [
    {"from": "model.jaffle_shop.orders", "to": "model.jaffle_shop.fct_orders"},
    {"from": "model.jaffle_shop.fct_orders", "to": "model.jaffle_shop.revenue_by_month"}
  ],
  "total_nodes": 3,
  "truncated": false
}
```

**Notes:**
- When `depth=None` on a large project, traversal can return hundreds of nodes. The agent should use `depth=1` or `depth=2` for targeted investigations and `depth=None` only for full lineage mapping.
- `truncated: true` is set if the result was cut short due to a hard node limit (configurable at server init, default 500 nodes).
- Exposure nodes (Looker explores, etc.) are included when present in the manifest.

---

#### `dbt_get_blast_radius`

**Description:** Returns all downstream nodes that would be affected if the given node fails, changes schema, or is dropped. Syntactic sugar over `dbt_get_lineage(direction="downstream", depth=None)` with additional severity scoring. Use this before making a breaking change.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_id` | `str` | Yes | The dbt unique node ID. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_get_blast_radius",
  "params": {
    "node_id": "source.jaffle_shop.raw.orders"
  }
}
```

**Example response shape:**
```json
[
  {
    "node_id": "model.jaffle_shop.stg_orders",
    "name": "stg_orders",
    "resource_type": "model",
    "materialization": "view",
    "hops_from_source": 1,
    "has_downstream_dependents": true
  },
  {
    "node_id": "model.jaffle_shop.orders",
    "name": "orders",
    "resource_type": "model",
    "materialization": "table",
    "hops_from_source": 2,
    "has_downstream_dependents": true
  },
  {
    "node_id": "model.jaffle_shop.fct_orders",
    "name": "fct_orders",
    "resource_type": "model",
    "materialization": "table",
    "hops_from_source": 3,
    "has_downstream_dependents": false
  },
  {
    "node_id": "test.jaffle_shop.not_null_orders_order_id",
    "name": "not_null_orders_order_id",
    "resource_type": "test",
    "materialization": null,
    "hops_from_source": 2,
    "has_downstream_dependents": false
  }
]
```

**Notes:**
- Includes tests as well as models — a change that breaks a test counts as blast radius.
- Does not include seed nodes (seeds don't depend on other nodes).
- `hops_from_source` is the graph distance from the input node. Useful for prioritizing review order.

---

#### `dbt_get_model_tests`

**Description:** Returns all dbt tests defined for a model: schema tests (not_null, unique, accepted_values, relationships), singular tests, and custom generic tests. Reads `manifest.json`. Use this to understand the test coverage on a model before investigating a data quality issue.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `model_name` | `str` | Yes | The dbt model name (not full node ID). Example: `orders`. The server resolves to the correct project. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_get_model_tests",
  "params": {
    "model_name": "orders"
  }
}
```

**Example response shape:**
```json
[
  {
    "test_id": "test.jaffle_shop.not_null_orders_order_id",
    "test_type": "not_null",
    "column_name": "order_id",
    "model_name": "orders",
    "severity": "error",
    "config": {}
  },
  {
    "test_id": "test.jaffle_shop.unique_orders_order_id",
    "test_type": "unique",
    "column_name": "order_id",
    "model_name": "orders",
    "severity": "error",
    "config": {}
  },
  {
    "test_id": "test.jaffle_shop.accepted_values_orders_status",
    "test_type": "accepted_values",
    "column_name": "status",
    "model_name": "orders",
    "severity": "warn",
    "config": {
      "values": ["placed", "shipped", "completed", "return_pending", "returned"]
    }
  },
  {
    "test_id": "test.jaffle_shop.relationships_orders_customer_id",
    "test_type": "relationships",
    "column_name": "customer_id",
    "model_name": "orders",
    "severity": "error",
    "config": {
      "to": "ref('customers')",
      "field": "customer_id"
    }
  }
]
```

**Notes:**
- Returns an empty list (not an error) if the model has no tests defined. The agent should treat this as a signal, not just a null result.
- `severity` is `"error"` or `"warn"` — controls whether a test failure blocks a dbt run.

---

#### `dbt_get_failed_models`

**Description:** Parses `run_results.json` and returns all models (and tests) that failed in the most recent run. Also returns models that were skipped due to upstream failures. Use this immediately after a failed dbt run to understand scope of failure.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `run_results_path` | `str` | Yes | Absolute path to `run_results.json`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_get_failed_models",
  "params": {
    "run_results_path": "/home/de/jaffle_shop/target/run_results.json"
  }
}
```

**Example response shape:**
```json
{
  "run_id": "run_abc123",
  "run_started_at": "2026-02-19T03:14:00Z",
  "elapsed_seconds": 142.3,
  "failed": [
    {
      "node_id": "model.jaffle_shop.stg_orders",
      "name": "stg_orders",
      "resource_type": "model",
      "status": "error",
      "error_message": "Database Error in model stg_orders: column \"fulfillment_status\" does not exist",
      "execution_time_seconds": 1.2,
      "started_at": "2026-02-19T03:14:05Z"
    }
  ],
  "skipped": [
    {
      "node_id": "model.jaffle_shop.orders",
      "name": "orders",
      "resource_type": "model",
      "status": "skipped",
      "error_message": null,
      "upstream_failure": "model.jaffle_shop.stg_orders"
    }
  ],
  "warnings": [],
  "total_failed": 1,
  "total_skipped": 3,
  "total_passed": 24
}
```

**Notes:**
- `skipped` models are included because they represent additional blast radius from the original failure.
- `error_message` is the raw database or dbt error string — may need further parsing for structured diagnosis.
- If the run succeeded completely, `failed` and `skipped` will be empty lists and `total_failed` will be 0.

---

#### `dbt_detect_silent_skip`

**Description:** Detects models that were expected to run (based on naming patterns or explicit node IDs) but are absent from `run_results.json`. Silent skips occur when a `--select` flag is too narrow, when a model is excluded by a tag, or when a dbt selector silently drops nodes. This is a correctness check, not an error check.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `run_results_path` | `str` | Yes | Absolute path to `run_results.json`. |
| `expected_patterns` | `list[str]` | Yes | List of model name patterns or node IDs expected to be present. Supports glob-style wildcards. Example: `["stg_*", "fct_orders", "model.jaffle_shop.revenue_by_month"]` |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_detect_silent_skip",
  "params": {
    "run_results_path": "/home/de/jaffle_shop/target/run_results.json",
    "expected_patterns": ["stg_*", "fct_orders", "dim_customers"]
  }
}
```

**Example response shape:**
```json
[
  {
    "pattern": "stg_*",
    "expected_match_count": 8,
    "actual_match_count": 6,
    "missing_models": ["stg_payments", "stg_refunds"],
    "severity": "warning"
  },
  {
    "pattern": "fct_orders",
    "expected_match_count": 1,
    "actual_match_count": 1,
    "missing_models": [],
    "severity": "ok"
  },
  {
    "pattern": "dim_customers",
    "expected_match_count": 1,
    "actual_match_count": 0,
    "missing_models": ["dim_customers"],
    "severity": "warning"
  }
]
```

**Notes:**
- Returns an empty list when all expected patterns are satisfied.
- The manifest (at `project_path/target/manifest.json`) is used to resolve glob patterns against actual model names. Pattern matching is applied to the short model name, not the full node ID.
- This tool is specifically for catching the "run succeeded but didn't touch the models we expected" class of bugs.

---

#### `dbt_get_schema`

**Description:** Returns the column list for a model, sourced either from `manifest.json` (the schema as defined in YAML files) or from `catalog.json` (the schema as observed in the warehouse by the last `dbt docs generate` run). Use `manifest` to see what the project declares; use `catalog` to see what actually exists in the warehouse.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `model_name` | `str` | Yes | The dbt model name. |
| `source` | `"manifest" \| "catalog"` | Yes | Which artifact to read. `manifest` = declared schema from YAML. `catalog` = observed schema from last docs run. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_get_schema",
  "params": {
    "model_name": "orders",
    "source": "catalog"
  }
}
```

**Example response shape:**
```json
{
  "model_name": "orders",
  "source": "catalog",
  "schema": "dbt_prod",
  "database": "analytics",
  "catalog_generated_at": "2026-02-18T22:00:00Z",
  "columns": [
    {
      "column_name": "order_id",
      "data_type": "NUMBER",
      "comment": "Primary key",
      "index": 1
    },
    {
      "column_name": "customer_id",
      "data_type": "NUMBER",
      "comment": null,
      "index": 2
    },
    {
      "column_name": "order_date",
      "data_type": "DATE",
      "comment": null,
      "index": 3
    },
    {
      "column_name": "amount",
      "data_type": "FLOAT",
      "comment": null,
      "index": 4
    }
  ]
}
```

**Notes:**
- When `source="catalog"`, returns `{"error": "catalog_not_found"}` if `catalog.json` does not exist at `target_path`.
- Column data types are warehouse-native types when sourced from catalog (e.g., `NUMBER`, `VARCHAR`, `TIMESTAMP_NTZ`). They are dbt-declared types (e.g., `text`, `int`) when sourced from manifest — and may be null if not declared.
- To detect schema drift: call once with `source="manifest"` and once with `source="catalog"`, then diff. Or use `warehouse_detect_schema_drift` which does this automatically.

---

#### `dbt_scan_pii_risk`

**Description:** Scans `manifest.json` and `catalog.json` for columns whose names match known PII patterns (email, phone, SSN, name, address, date_of_birth, etc.) and cross-references with model metadata and descriptions. Returns a prioritized list of models and columns that likely contain PII and lack appropriate tagging or masking. Does not read actual data rows.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `manifest_path` | `str` | Yes | Absolute path to `manifest.json`. |
| `catalog_path` | `str` | Yes | Absolute path to `catalog.json`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_scan_pii_risk",
  "params": {
    "manifest_path": "/home/de/jaffle_shop/target/manifest.json",
    "catalog_path": "/home/de/jaffle_shop/target/catalog.json"
  }
}
```

**Example response shape:**
```json
[
  {
    "model_name": "stg_customers",
    "node_id": "model.jaffle_shop.stg_customers",
    "column_name": "email",
    "pii_pattern_matched": "email",
    "has_pii_tag": false,
    "has_masking_policy": false,
    "materialization": "view",
    "risk_level": "high"
  },
  {
    "model_name": "stg_customers",
    "node_id": "model.jaffle_shop.stg_customers",
    "column_name": "full_name",
    "pii_pattern_matched": "name",
    "has_pii_tag": false,
    "has_masking_policy": false,
    "materialization": "view",
    "risk_level": "medium"
  },
  {
    "model_name": "raw_payments",
    "node_id": "source.jaffle_shop.raw.payments",
    "column_name": "card_last_four",
    "pii_pattern_matched": "payment_card",
    "has_pii_tag": true,
    "has_masking_policy": false,
    "materialization": null,
    "risk_level": "medium"
  }
]
```

**Notes:**
- PII patterns matched against column names (case-insensitive substring and regex matching): `email`, `phone`, `ssn`, `social_security`, `dob`, `date_of_birth`, `first_name`, `last_name`, `full_name`, `address`, `zip`, `postal_code`, `ip_address`, `credit_card`, `card_number`, `card_last_four`, `passport`, `driver_license`.
- `has_pii_tag` checks for a `pii` or `sensitive` tag in the column-level manifest metadata.
- `has_masking_policy` checks for Snowflake-style masking policy references in meta fields (only relevant for Snowflake projects).
- `risk_level` is heuristic: `high` = direct identifier (email, SSN, phone), `medium` = quasi-identifier (name, address component), `low` = potential context (zip alone).

---

#### `dbt_get_source_freshness`

**Description:** Reads `sources.json` (the output of `dbt source freshness`) and returns per-source freshness status, last-loaded timestamps, and staleness relative to configured thresholds. Use this to detect stale data sources before investigating downstream model anomalies.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `sources_path` | `str` | Yes | Absolute path to `sources.json`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_get_source_freshness",
  "params": {
    "sources_path": "/home/de/jaffle_shop/target/sources.json"
  }
}
```

**Example response shape:**
```json
{
  "generated_at": "2026-02-19T06:00:00Z",
  "sources": [
    {
      "source_name": "raw",
      "table_name": "orders",
      "status": "pass",
      "max_loaded_at": "2026-02-19T05:45:00Z",
      "snapshotted_at": "2026-02-19T06:00:00Z",
      "age_seconds": 900,
      "warn_after_seconds": 3600,
      "error_after_seconds": 86400,
      "filter": null
    },
    {
      "source_name": "raw",
      "table_name": "customers",
      "status": "warn",
      "max_loaded_at": "2026-02-19T01:00:00Z",
      "snapshotted_at": "2026-02-19T06:00:00Z",
      "age_seconds": 18000,
      "warn_after_seconds": 7200,
      "error_after_seconds": 86400,
      "filter": null
    },
    {
      "source_name": "stripe",
      "table_name": "events",
      "status": "error",
      "max_loaded_at": "2026-02-17T12:00:00Z",
      "snapshotted_at": "2026-02-19T06:00:00Z",
      "age_seconds": 151200,
      "warn_after_seconds": 3600,
      "error_after_seconds": 86400,
      "filter": null
    }
  ]
}
```

**Notes:**
- `status` is `"pass"`, `"warn"`, `"error"`, or `"runtime error"` (dbt's native status values from sources.json).
- Returns `{"error": "sources_not_found"}` if `sources.json` does not exist — this usually means `dbt source freshness` has not been run.
- `age_seconds` is computed at parse time as `snapshotted_at - max_loaded_at`.

---

#### `dbt_find_select_star`

**Description:** Scans all models' compiled SQL in `manifest.json` for `SELECT *` usage. Returns the list of models that use wildcard column selection, which is a code quality issue (schema changes will silently propagate) and a common source of schema drift bugs.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `manifest_path` | `str` | Yes | Absolute path to `manifest.json`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "dbt_find_select_star",
  "params": {
    "manifest_path": "/home/de/jaffle_shop/target/manifest.json"
  }
}
```

**Example response shape:**
```json
[
  {
    "model_name": "stg_stripe_events",
    "node_id": "model.jaffle_shop.stg_stripe_events",
    "compiled_sql_snippet": "SELECT * FROM {{ source('stripe', 'events') }}",
    "occurrence_count": 1,
    "schema": "dbt_staging"
  },
  {
    "model_name": "raw_hubspot_contacts",
    "node_id": "model.jaffle_shop.raw_hubspot_contacts",
    "compiled_sql_snippet": "SELECT *, _fivetran_synced FROM hubspot.contacts",
    "occurrence_count": 1,
    "schema": "dbt_raw"
  }
]
```

**Notes:**
- Uses regex to detect `SELECT *` and `SELECT t.*` patterns in compiled SQL.
- `compiled_sql_snippet` is the first 200 characters of the matched line for context.
- CTE-internal `SELECT *` (used for expansion) is also flagged — the agent should distinguish expansion patterns from final SELECT patterns if needed.

---

### Category 2: Warehouse Tools

**MCP Server name:** `warehouse`

**What this server does:** Executes SQL and inspects schemas directly against the warehouse. Supports Snowflake, BigQuery, and DuckDB. All queries are run with the configured read-only role where possible.

**Server init parameters:**
- `warehouse: "snowflake" | "bigquery" | "duckdb"` — which warehouse to connect to
- `connection_config: dict` — warehouse-specific connection parameters (account, user, password, database, schema, project_id, credentials_path, db_path, etc.)
- `default_role: str` — Snowflake role or BigQuery IAM role to use (optional, defaults to connector default)
- `query_timeout_seconds: int` — per-query timeout (default: 120)

---

#### `warehouse_execute`

**Description:** Executes a SQL query against the configured warehouse and returns results as a list of row dicts. The primary tool for ad-hoc investigation: row counts, sample data, aggregations, anomaly checks. Automatically applies a `LIMIT` if not present in the query.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `sql` | `str` | Yes | The SQL query to execute. Multi-line strings supported. |
| `warehouse` | `"snowflake" \| "bigquery" \| "duckdb"` | No | Override the server-default warehouse. |
| `limit` | `int` | No | Maximum rows to return. Appended as `LIMIT` if not already present in `sql`. Default: `1000`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_execute",
  "params": {
    "sql": "SELECT status, COUNT(*) as order_count FROM dbt_prod.orders GROUP BY status ORDER BY order_count DESC",
    "limit": 100
  }
}
```

**Example response shape:**
```json
{
  "rows": [
    {"status": "completed", "order_count": 8241},
    {"status": "placed", "order_count": 1203},
    {"status": "shipped", "order_count": 892},
    {"status": "return_pending", "order_count": 144},
    {"status": "returned", "order_count": 98}
  ],
  "row_count": 5,
  "elapsed_ms": 340,
  "bytes_processed": null,
  "warehouse": "snowflake",
  "limit_applied": true
}
```

**Notes:**
- For DDL/DML queries (`INSERT`, `UPDATE`, `CREATE`, `DROP`, `TRUNCATE`), the server raises a structured error `{"error": "dml_not_permitted", "detail": "..."}` if the connection role is read-only.
- `bytes_processed` is populated for BigQuery (cost visibility); null for Snowflake and DuckDB.
- Results exceeding `limit` rows are truncated with `limit_applied: true`.

---

#### `warehouse_get_schema`

**Description:** Returns the full column list for a schema or table using `INFORMATION_SCHEMA.COLUMNS`. Use this to inspect what columns currently exist in the warehouse — independent of what dbt thinks should exist.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `schema_name` | `str` | Yes | The schema to inspect. Can optionally include database prefix: `database.schema`. |
| `table_name` | `str` | No | Filter to a specific table within the schema. If omitted, returns all tables in the schema. |
| `warehouse` | `str` | No | Override server default. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_get_schema",
  "params": {
    "schema_name": "dbt_prod",
    "table_name": "orders"
  }
}
```

**Example response shape:**
```json
{
  "database": "analytics",
  "schema": "dbt_prod",
  "table_name": "orders",
  "columns": [
    {
      "column_name": "order_id",
      "ordinal_position": 1,
      "data_type": "NUMBER",
      "is_nullable": "NO",
      "column_default": null,
      "character_maximum_length": null,
      "numeric_precision": 38,
      "numeric_scale": 0
    },
    {
      "column_name": "customer_id",
      "ordinal_position": 2,
      "data_type": "NUMBER",
      "is_nullable": "YES",
      "column_default": null,
      "character_maximum_length": null,
      "numeric_precision": 38,
      "numeric_scale": 0
    },
    {
      "column_name": "order_date",
      "ordinal_position": 3,
      "data_type": "DATE",
      "is_nullable": "YES",
      "column_default": null,
      "character_maximum_length": null,
      "numeric_precision": null,
      "numeric_scale": null
    }
  ],
  "column_count": 3
}
```

**Notes:**
- Uses `INFORMATION_SCHEMA.COLUMNS` which is ANSI standard and available in Snowflake, BigQuery, and DuckDB.
- BigQuery note: `INFORMATION_SCHEMA.COLUMNS` in BigQuery requires the table to be in the same project or cross-project access enabled.

---

#### `warehouse_detect_schema_drift`

**Description:** Compares the column schema declared in dbt's `manifest.json` against the actual schema in the warehouse. Returns a structured drift report: columns added in warehouse (not in manifest), columns removed from warehouse (in manifest but not in warehouse), and columns with changed data types.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `model_name` | `str` | Yes | The dbt model name. |
| `manifest_path` | `str` | Yes | Absolute path to `manifest.json`. |
| `warehouse` | `str` | No | Override server default. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_detect_schema_drift",
  "params": {
    "model_name": "stg_orders",
    "manifest_path": "/home/de/jaffle_shop/target/manifest.json"
  }
}
```

**Example response shape:**
```json
{
  "model_name": "stg_orders",
  "drift_detected": true,
  "added_in_warehouse": [
    {
      "column_name": "fulfillment_partner",
      "data_type": "VARCHAR",
      "note": "Column exists in warehouse but not declared in manifest"
    }
  ],
  "removed_from_warehouse": [
    {
      "column_name": "fulfillment_status",
      "declared_type": "VARCHAR",
      "note": "Column declared in manifest but absent from warehouse"
    }
  ],
  "type_changed": [
    {
      "column_name": "order_value",
      "manifest_type": "NUMBER",
      "warehouse_type": "FLOAT",
      "note": "Type mismatch between manifest declaration and warehouse column"
    }
  ],
  "unchanged_count": 12,
  "checked_at": "2026-02-19T06:14:22Z"
}
```

**Notes:**
- Type comparison is normalized (e.g., `TEXT` == `VARCHAR`, `INT` == `NUMBER(38,0)`) to avoid false positives from warehouse-specific type aliases. Normalization is warehouse-aware.
- Returns `drift_detected: false` with empty lists when schemas match exactly.
- This tool was directly motivated by LRN-036 (detection latency is the real incident cost — WT-04).

---

#### `warehouse_check_freshness`

**Description:** Queries a specific table to find the most recent timestamp in a given column and computes staleness. Complements `dbt_get_source_freshness` (which reads the artifact) by doing a live freshness check directly against the warehouse.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `table_name` | `str` | Yes | Fully qualified table name: `database.schema.table` or `schema.table`. |
| `timestamp_column` | `str` | Yes | The column to use as the freshness indicator. Must be a DATE, TIMESTAMP, or DATETIME type. |
| `freshness_threshold_hours` | `float` | No | Threshold in hours to determine `is_fresh`. Default: `24.0`. |
| `warehouse` | `str` | No | Override server default. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_check_freshness",
  "params": {
    "table_name": "analytics.dbt_prod.orders",
    "timestamp_column": "updated_at",
    "freshness_threshold_hours": 6
  }
}
```

**Example response shape:**
```json
{
  "table_name": "analytics.dbt_prod.orders",
  "timestamp_column": "updated_at",
  "max_timestamp": "2026-02-19T04:30:00Z",
  "checked_at": "2026-02-19T06:14:00Z",
  "staleness_hours": 1.73,
  "freshness_threshold_hours": 6.0,
  "is_fresh": true,
  "row_count_sampled": null
}
```

**Notes:**
- Executes `SELECT MAX({timestamp_column}) FROM {table_name}`.
- Returns `{"error": "column_not_found", ...}` if `timestamp_column` does not exist on the table.
- Returns `{"max_timestamp": null, "staleness_hours": null, "is_fresh": false}` if the table is empty.

---

#### `warehouse_get_query_history`

**Description:** Returns recent query history for a table or table pattern from the warehouse's query log. Snowflake: `QUERY_HISTORY` view. BigQuery: `INFORMATION_SCHEMA.JOBS`. DuckDB: not supported (returns structured error). Useful for understanding access patterns, identifying expensive queries, and auditing who queried sensitive tables.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `table_pattern` | `str` | Yes | Table name or SQL `LIKE` pattern to filter queries referencing that table. Example: `%orders%` |
| `lookback_days` | `int` | No | Number of days back to search. Default: `7`. Max: `30` (warehouse limitation). |
| `warehouse` | `str` | No | Override server default. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_get_query_history",
  "params": {
    "table_pattern": "%fct_orders%",
    "lookback_days": 3
  }
}
```

**Example response shape:**
```json
{
  "queries": [
    {
      "query_id": "01b3c4d5-6789-abcd-ef01-234567890abc",
      "query_text_truncated": "SELECT customer_id, SUM(amount) FROM dbt_prod.fct_orders WHERE order_date >= ...",
      "user_name": "BI_SERVICE_ACCOUNT",
      "start_time": "2026-02-19T05:55:02Z",
      "end_time": "2026-02-19T05:55:14Z",
      "duration_ms": 12200,
      "bytes_scanned": 1240000000,
      "rows_produced": 4821,
      "execution_status": "SUCCESS"
    },
    {
      "query_id": "02c4d5e6-789a-bcde-f012-34567890abcd",
      "query_text_truncated": "SELECT * FROM dbt_prod.fct_orders LIMIT 100",
      "user_name": "analytics_user_jsmith",
      "start_time": "2026-02-19T02:10:00Z",
      "end_time": "2026-02-19T02:10:03Z",
      "duration_ms": 3100,
      "bytes_scanned": 240000000,
      "rows_produced": 100,
      "execution_status": "SUCCESS"
    }
  ],
  "total_returned": 2,
  "lookback_days": 3,
  "warehouse": "snowflake"
}
```

**Notes:**
- `query_text_truncated` is capped at 500 characters for context window efficiency.
- `bytes_scanned` is null for Snowflake virtual warehouses that don't expose this metric at the query level (credits are the Snowflake cost unit, not bytes).
- BigQuery populates `bytes_scanned` accurately (maps to billable bytes).
- This tool requires elevated permissions on some warehouses (e.g., `ACCOUNTADMIN` or `SYSADMIN` for Snowflake's `QUERY_HISTORY` view).

---

#### `warehouse_explain_query`

**Description:** Returns the execution plan for a SQL query without running it. Useful for diagnosing slow queries before executing them, estimating cost, and understanding join order and scan patterns.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `sql` | `str` | Yes | The SQL query to explain. |
| `warehouse` | `str` | No | Override server default. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_explain_query",
  "params": {
    "sql": "SELECT a.order_id, b.customer_name FROM dbt_prod.orders a JOIN dbt_prod.customers b ON a.customer_id = b.customer_id WHERE a.order_date >= '2026-01-01'"
  }
}
```

**Example response shape:**
```json
{
  "plan_text": "GlobalStats:\n  partitionsTotal=1\n  partitionsAssigned=1\n  bytesAssigned=1240000000\nOperations:\n  1:TableScan dbt_prod.orders [order_id, customer_id, order_date] {partitionsTotal=1, bytesAssigned=820000000}\n  2:TableScan dbt_prod.customers [customer_id, customer_name] {partitionsTotal=1, bytesAssigned=420000000}\n  3:JoinFilter [customer_id] (Inner)\n  4:Project [order_id, customer_name]\n",
  "estimated_bytes_scanned": 1240000000,
  "estimated_cost_credits": null,
  "warehouse": "snowflake",
  "notes": "EXPLAIN output is warehouse-native text format. Structured parsing not available."
}
```

**Notes:**
- `plan_text` is the raw EXPLAIN output — format varies by warehouse (Snowflake: tabular text, BigQuery: JSON plan, DuckDB: tree text).
- `estimated_cost_credits` is null for all warehouses — Snowflake does not expose pre-query cost estimates.
- `estimated_bytes_scanned` is populated for BigQuery (from `EXPLAIN` response). For Snowflake it is sometimes derivable from the GlobalStats line.

---

#### `warehouse_detect_duplicates`

**Description:** Detects duplicate rows in a table based on a set of key columns. Returns the duplicate count, severity assessment, and sample duplicate rows. Use for data quality investigations (WT-08 pattern: duplicate detection).

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `table_name` | `str` | Yes | Fully qualified table name. |
| `key_columns` | `list[str]` | Yes | The columns that together should be unique. Example: `["order_id"]` or `["customer_id", "event_date"]`. |
| `warehouse` | `str` | No | Override server default. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "warehouse_detect_duplicates",
  "params": {
    "table_name": "analytics.dbt_prod.orders",
    "key_columns": ["order_id"]
  }
}
```

**Example response shape:**
```json
{
  "table_name": "analytics.dbt_prod.orders",
  "key_columns": ["order_id"],
  "total_rows": 10582,
  "distinct_key_count": 10478,
  "duplicate_key_count": 104,
  "duplicate_row_count": 208,
  "duplication_rate_pct": 0.98,
  "severity": "medium",
  "sample_duplicates": [
    {
      "order_id": 10021,
      "occurrence_count": 2,
      "sample_row": {"order_id": 10021, "customer_id": 441, "order_date": "2026-01-15", "amount": 149.99}
    },
    {
      "order_id": 10088,
      "occurrence_count": 2,
      "sample_row": {"order_id": 10088, "customer_id": 892, "order_date": "2026-01-22", "amount": 75.00}
    }
  ]
}
```

**Notes:**
- `severity` heuristic: `low` < 0.1% duplication rate, `medium` 0.1–1%, `high` > 1%.
- `sample_duplicates` returns up to 5 examples.
- Executes two queries: `SELECT COUNT(*)` and a `GROUP BY ... HAVING COUNT(*) > 1` query. On large tables this can be slow — the tool applies a `LIMIT` on the sample query but not on the dedup count.

---

### Category 3: dbt Cloud Tools

**MCP Server name:** `dbt-cloud`

**What this server does:** Wraps the dbt Cloud REST API v2. Triggers runs, polls run status, fetches artifacts from completed runs, and queries job configuration. Requires a dbt Cloud API token and account ID configured at server init.

**Server init parameters:**
- `api_token: str` — dbt Cloud service token (read + run scope required)
- `account_id: int` — dbt Cloud account ID
- `base_url: str` — dbt Cloud API base URL (default: `https://cloud.getdbt.com/api/v2`)

---

#### `dbtcloud_trigger_job`

**Description:** Triggers a dbt Cloud job run. Returns the run ID immediately (does not wait for completion — use `dbtcloud_poll_run` to wait). Optionally overrides the job's default steps.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `job_id` | `int` | Yes | The dbt Cloud job ID. |
| `cause` | `str` | Yes | Human-readable string describing why the run was triggered. Appears in dbt Cloud run history. Example: `"Agent-triggered: schema drift detected on stg_orders"`. |
| `steps_override` | `list[str] \| None` | No | If provided, overrides the job's configured steps. Example: `["dbt run --select stg_orders+", "dbt test --select stg_orders+"]`. Default: `null` (uses job's default steps). |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: false`
- `destructiveHint: false`
- `idempotentHint: false`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "dbtcloud_trigger_job",
  "params": {
    "job_id": 12345,
    "cause": "Agent-triggered: schema drift detected on stg_orders, re-running downstream models",
    "steps_override": ["dbt run --select stg_orders+", "dbt test --select stg_orders+"]
  }
}
```

**Example response shape:**
```json
{
  "run_id": 78901234,
  "job_id": 12345,
  "status": "queued",
  "created_at": "2026-02-19T06:20:00Z",
  "href": "https://cloud.getdbt.com/#/accounts/1234/projects/5678/runs/78901234/",
  "cause": "Agent-triggered: schema drift detected on stg_orders, re-running downstream models"
}
```

**Notes:**
- `readOnlyHint: false` because this triggers a job run — state-changing in dbt Cloud.
- `idempotentHint: false` because calling this twice creates two runs.
- The agent should log all `dbtcloud_trigger_job` calls to `DECISIONS.md` with the cause string as justification.

---

#### `dbtcloud_poll_run`

**Description:** Polls a dbt Cloud run until it reaches a terminal state (success, error, cancelled) or the timeout is exceeded. Blocks until the run completes or times out. Returns the final run state.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `run_id` | `int` | Yes | The dbt Cloud run ID (returned by `dbtcloud_trigger_job`). |
| `timeout_seconds` | `int` | No | Maximum time to wait in seconds. Default: `1800` (30 min). If exceeded, returns the current (non-terminal) state with `timed_out: true`. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "dbtcloud_poll_run",
  "params": {
    "run_id": 78901234,
    "timeout_seconds": 900
  }
}
```

**Example response shape:**
```json
{
  "run_id": 78901234,
  "job_id": 12345,
  "status": "success",
  "status_message": null,
  "started_at": "2026-02-19T06:20:15Z",
  "finished_at": "2026-02-19T06:24:30Z",
  "duration_seconds": 255,
  "steps": [
    {
      "name": "dbt run --select stg_orders+",
      "status": "success",
      "duration_seconds": 140
    },
    {
      "name": "dbt test --select stg_orders+",
      "status": "success",
      "duration_seconds": 115
    }
  ],
  "timed_out": false,
  "href": "https://cloud.getdbt.com/#/accounts/1234/projects/5678/runs/78901234/"
}
```

**Notes:**
- `status` values: `"queued"`, `"starting"`, `"running"`, `"success"`, `"error"`, `"cancelled"`.
- Polls every 10 seconds internally. Does not block the MCP server thread (async implementation).
- When `timed_out: true`, the agent should decide whether to continue polling or abandon.

---

#### `dbtcloud_get_last_run`

**Description:** Returns metadata about the most recent run of a dbt Cloud job matching the given status. Use this to check whether a job has succeeded recently without triggering a new run.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `job_id` | `int` | Yes | The dbt Cloud job ID. |
| `status` | `str` | No | Filter to runs with this status. Default: `"Success"`. Accepts dbt Cloud status strings: `"Success"`, `"Error"`, `"Cancelled"`, or `null` for any status. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "dbtcloud_get_last_run",
  "params": {
    "job_id": 12345,
    "status": "Success"
  }
}
```

**Example response shape:**
```json
{
  "run_id": 78891234,
  "job_id": 12345,
  "status": "Success",
  "started_at": "2026-02-19T04:00:10Z",
  "finished_at": "2026-02-19T04:14:22Z",
  "duration_seconds": 852,
  "triggered_by": "scheduler",
  "cause": "Scheduled run",
  "href": "https://cloud.getdbt.com/#/accounts/1234/projects/5678/runs/78891234/"
}
```

**Notes:**
- Returns `{"error": "no_matching_run", "job_id": 12345, "status_filter": "Success"}` if no matching run exists.

---

#### `dbtcloud_fetch_artifact`

**Description:** Downloads a dbt artifact JSON file from a completed dbt Cloud run and returns its parsed content. This is how the agent gets up-to-date lineage, schema, and run results without needing local file access.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `run_id` | `int` | Yes | The dbt Cloud run ID. |
| `artifact` | `"manifest.json" \| "catalog.json" \| "run_results.json" \| "sources.json"` | Yes | Which artifact to fetch. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "dbtcloud_fetch_artifact",
  "params": {
    "run_id": 78891234,
    "artifact": "run_results.json"
  }
}
```

**Example response shape:**
```json
{
  "artifact": "run_results.json",
  "run_id": 78891234,
  "fetched_at": "2026-02-19T06:25:00Z",
  "content": {
    "metadata": {
      "dbt_schema_version": "https://schemas.getdbt.com/dbt/run-results/v5/run-results.json",
      "dbt_version": "1.7.4",
      "generated_at": "2026-02-19T04:14:20Z"
    },
    "results": [
      {
        "unique_id": "model.jaffle_shop.stg_orders",
        "status": "success",
        "execution_time": 2.14
      }
    ],
    "elapsed_time": 852.3
  }
}
```

**Notes:**
- Returns `{"error": "artifact_not_found", ...}` if the run did not produce the requested artifact (e.g., requesting `catalog.json` from a run that didn't include `dbt docs generate`).
- `content` is the full parsed artifact JSON — can be large for `manifest.json` on complex projects. The agent should extract only the fields it needs.

---

#### `dbtcloud_list_jobs`

**Description:** Lists all configured dbt Cloud jobs for a project, optionally filtered by environment. Returns job configuration metadata.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `project_id` | `int` | Yes | The dbt Cloud project ID. |
| `environment_id` | `int \| None` | No | Filter to jobs in a specific environment (e.g., production only). Default: `null` (all environments). |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "dbtcloud_list_jobs",
  "params": {
    "project_id": 5678,
    "environment_id": 910
  }
}
```

**Example response shape:**
```json
[
  {
    "job_id": 12345,
    "name": "Daily Production Run",
    "environment_id": 910,
    "environment_name": "Production",
    "schedule_enabled": true,
    "cron": "0 4 * * *",
    "steps": ["dbt run", "dbt test"],
    "generate_docs": true,
    "run_source_freshness": true
  },
  {
    "job_id": 12346,
    "name": "Staging CI",
    "environment_id": 911,
    "environment_name": "Staging",
    "schedule_enabled": false,
    "cron": null,
    "steps": ["dbt run --select state:modified+", "dbt test --select state:modified+"],
    "generate_docs": false,
    "run_source_freshness": false
  }
]
```

---

#### `dbtcloud_get_source_freshness`

**Description:** Returns per-source freshness status from the most recent run of a dbt Cloud job that included source freshness. Reads the `sources.json` artifact from the last successful run.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `job_id` | `int` | Yes | The dbt Cloud job ID. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "dbtcloud_get_source_freshness",
  "params": {
    "job_id": 12345
  }
}
```

**Example response shape:**
```json
{
  "job_id": 12345,
  "run_id": 78891234,
  "run_finished_at": "2026-02-19T04:14:22Z",
  "sources": [
    {
      "source_name": "raw",
      "table_name": "orders",
      "status": "pass",
      "max_loaded_at": "2026-02-19T04:00:00Z",
      "age_seconds": 840
    },
    {
      "source_name": "stripe",
      "table_name": "events",
      "status": "error",
      "max_loaded_at": "2026-02-17T12:00:00Z",
      "age_seconds": 151200
    }
  ]
}
```

**Notes:**
- Returns `{"error": "no_freshness_run", ...}` if the job is not configured with `run_source_freshness: true`.

---

### Category 4: Orchestrator Tools

**MCP Server name:** `orchestrator`

**What this server does:** Interfaces with Airflow (REST API v2) or Prefect (Python client) to inspect DAG/flow run history, trigger runs, fetch task statuses, and retrieve logs. Backend is selected per call via the `backend` parameter.

**Server init parameters:**
- `airflow_base_url: str` — Airflow webserver URL (e.g., `http://airflow.internal:8080`)
- `airflow_username: str` / `airflow_password: str` — Airflow basic auth credentials
- `prefect_api_url: str` — Prefect Cloud or self-hosted API URL
- `prefect_api_key: str` — Prefect API key

---

#### `orchestrator_get_last_run`

**Description:** Returns metadata about the most recent run of a DAG (Airflow) or flow (Prefect), optionally filtered by status. Use this to check when a pipeline last succeeded and whether it is current.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dag_id` | `str` | Yes | The Airflow DAG ID or Prefect flow name. |
| `status` | `str` | No | Filter by run state. Airflow: `"success"`, `"failed"`, `"running"`. Prefect: `"COMPLETED"`, `"FAILED"`, `"RUNNING"`. Default: `"success"`. |
| `backend` | `"airflow" \| "prefect"` | Yes | Which orchestrator to query. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "orchestrator_get_last_run",
  "params": {
    "dag_id": "dbt_daily_production",
    "status": "failed",
    "backend": "airflow"
  }
}
```

**Example response shape:**
```json
{
  "dag_id": "dbt_daily_production",
  "run_id": "scheduled__2026-02-19T04:00:00+00:00",
  "state": "failed",
  "execution_date": "2026-02-19T04:00:00Z",
  "start_date": "2026-02-19T04:00:12Z",
  "end_date": "2026-02-19T04:08:44Z",
  "duration_seconds": 512,
  "run_type": "scheduled",
  "external_trigger": false,
  "backend": "airflow"
}
```

---

#### `orchestrator_trigger_dag`

**Description:** Triggers an Airflow DAG run or Prefect flow run. Returns immediately with a run ID. Use `orchestrator_get_last_run` or `orchestrator_get_task_status` to monitor progress.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dag_id` | `str` | Yes | The Airflow DAG ID or Prefect flow name. |
| `conf` | `dict \| None` | No | Run configuration passed as DAG conf (Airflow) or flow parameters (Prefect). Default: `null`. |
| `backend` | `"airflow" \| "prefect"` | Yes | Which orchestrator to target. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: false`
- `destructiveHint: false`
- `idempotentHint: false`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "orchestrator_trigger_dag",
  "params": {
    "dag_id": "dbt_daily_production",
    "conf": {"reason": "agent-triggered: source freshness error on stripe.events"},
    "backend": "airflow"
  }
}
```

**Example response shape:**
```json
{
  "dag_id": "dbt_daily_production",
  "run_id": "manual__2026-02-19T06:30:00+00:00",
  "state": "queued",
  "execution_date": "2026-02-19T06:30:00Z",
  "conf": {"reason": "agent-triggered: source freshness error on stripe.events"},
  "backend": "airflow"
}
```

**Notes:**
- `idempotentHint: false` — calling this twice creates two runs.
- The agent should log all triggered runs with the `conf.reason` field as audit trail.

---

#### `orchestrator_get_task_status`

**Description:** Returns the status and timing for a specific task within a DAG run. Use this to identify which task in a run failed and how long it ran.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dag_id` | `str` | Yes | The DAG or flow ID. |
| `run_id` | `str` | Yes | The run ID (from `orchestrator_get_last_run` or `orchestrator_trigger_dag`). |
| `task_id` | `str` | Yes | The specific task ID within the DAG. |
| `backend` | `"airflow" \| "prefect"` | Yes | Which orchestrator to query. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "orchestrator_get_task_status",
  "params": {
    "dag_id": "dbt_daily_production",
    "run_id": "scheduled__2026-02-19T04:00:00+00:00",
    "task_id": "dbt_run_stg_models",
    "backend": "airflow"
  }
}
```

**Example response shape:**
```json
{
  "dag_id": "dbt_daily_production",
  "run_id": "scheduled__2026-02-19T04:00:00+00:00",
  "task_id": "dbt_run_stg_models",
  "state": "failed",
  "start_date": "2026-02-19T04:02:10Z",
  "end_date": "2026-02-19T04:03:22Z",
  "duration_seconds": 72,
  "try_number": 1,
  "max_tries": 3,
  "pool": "default_pool",
  "backend": "airflow"
}
```

---

#### `orchestrator_fetch_logs`

**Description:** Fetches the raw log output for a specific task instance. Returns log text as a string. Use in conjunction with `orchestrator_detect_patterns` to extract structured information from logs.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dag_id` | `str` | Yes | The DAG or flow ID. |
| `run_id` | `str` | Yes | The run ID. |
| `task_id` | `str` | Yes | The task ID. |
| `backend` | `"airflow" \| "prefect"` | Yes | Which orchestrator to query. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "orchestrator_fetch_logs",
  "params": {
    "dag_id": "dbt_daily_production",
    "run_id": "scheduled__2026-02-19T04:00:00+00:00",
    "task_id": "dbt_run_stg_models",
    "backend": "airflow"
  }
}
```

**Example response shape:**
```json
{
  "dag_id": "dbt_daily_production",
  "run_id": "scheduled__2026-02-19T04:00:00+00:00",
  "task_id": "dbt_run_stg_models",
  "log_text": "[2026-02-19 04:02:10,221] {taskinstance.py:1088} INFO - Dependencies all met for...\n[2026-02-19 04:02:10,880] {subprocess.py:74} INFO - Running command: dbt run --select staging.*\n[2026-02-19 04:03:21,442] {subprocess.py:85} ERROR - 22 of 24 OK created sql table model dbt_staging.stg_orders ........... ERROR\n[2026-02-19 04:03:21,443] {subprocess.py:85} INFO - Database Error in model stg_orders (models/staging/stg_orders.sql)\ncolumn \"fulfillment_status\" does not exist\n",
  "log_length_chars": 1842,
  "truncated": false
}
```

**Notes:**
- Logs can be very long (tens of thousands of lines). The server caps returned log length at 50,000 characters and sets `truncated: true` if exceeded.
- For structured analysis of log content, pass `log_text` to `orchestrator_detect_patterns`.

---

#### `orchestrator_detect_patterns`

**Description:** Scans a log text string for a list of patterns (regex or literal strings) and returns all matches with line numbers and surrounding context. This is the structured extraction layer on top of raw log text returned by `orchestrator_fetch_logs`.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `log_text` | `str` | Yes | The raw log text to scan. Typically from `orchestrator_fetch_logs`. |
| `patterns` | `list[str]` | Yes | List of patterns to search for. Each pattern can be a literal string or a Python regex. Example: `["ERROR", "column .* does not exist", "Database Error"]` |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "orchestrator_detect_patterns",
  "params": {
    "log_text": "[2026-02-19 04:03:21] ERROR - Database Error in model stg_orders\ncolumn \"fulfillment_status\" does not exist\n[2026-02-19 04:03:21] INFO - Run complete",
    "patterns": ["ERROR", "column .* does not exist", "Database Error in model (\\w+)"]
  }
}
```

**Example response shape:**
```json
[
  {
    "pattern": "ERROR",
    "match_count": 1,
    "matches": [
      {
        "line_number": 1,
        "matched_text": "ERROR",
        "line_snippet": "[2026-02-19 04:03:21] ERROR - Database Error in model stg_orders"
      }
    ]
  },
  {
    "pattern": "column .* does not exist",
    "match_count": 1,
    "matches": [
      {
        "line_number": 2,
        "matched_text": "column \"fulfillment_status\" does not exist",
        "line_snippet": "column \"fulfillment_status\" does not exist"
      }
    ]
  },
  {
    "pattern": "Database Error in model (\\w+)",
    "match_count": 1,
    "matches": [
      {
        "line_number": 1,
        "matched_text": "Database Error in model stg_orders",
        "line_snippet": "[2026-02-19 04:03:21] ERROR - Database Error in model stg_orders",
        "capture_groups": ["stg_orders"]
      }
    ]
  }
]
```

**Notes:**
- `openWorldHint: false` — this operates on text passed to it, not on external systems.
- Patterns that match 0 times are not returned (filtered from output). Only non-empty matches are included.
- Invalid regex patterns return `{"error": "invalid_regex", "pattern": "..."}` in the result list.

---

#### `orchestrator_get_run_history`

**Description:** Returns the timeline of DAG/flow runs over a lookback period, including success/failure/running states and run durations. Use for reliability analysis: identifying flapping pipelines, detecting degrading run times, and understanding failure frequency.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dag_id` | `str` | Yes | The DAG or flow ID. |
| `lookback_days` | `int` | No | How many days of history to retrieve. Default: `7`. |
| `backend` | `"airflow" \| "prefect"` | Yes | Which orchestrator to query. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "orchestrator_get_run_history",
  "params": {
    "dag_id": "dbt_daily_production",
    "lookback_days": 7,
    "backend": "airflow"
  }
}
```

**Example response shape:**
```json
{
  "dag_id": "dbt_daily_production",
  "lookback_days": 7,
  "runs": [
    {
      "run_id": "scheduled__2026-02-19T04:00:00+00:00",
      "state": "failed",
      "execution_date": "2026-02-19T04:00:00Z",
      "duration_seconds": 512,
      "run_type": "scheduled"
    },
    {
      "run_id": "scheduled__2026-02-18T04:00:00+00:00",
      "state": "success",
      "execution_date": "2026-02-18T04:00:00Z",
      "duration_seconds": 841,
      "run_type": "scheduled"
    },
    {
      "run_id": "scheduled__2026-02-17T04:00:00+00:00",
      "state": "success",
      "execution_date": "2026-02-17T04:00:00Z",
      "duration_seconds": 822,
      "run_type": "scheduled"
    }
  ],
  "total_runs": 7,
  "success_count": 6,
  "failure_count": 1,
  "avg_duration_seconds": 798.4
}
```

---

### Category 5: BI API Tools

**MCP Server name:** `bi-api`

**What this server does:** Interfaces with Looker (API 4.0) and Metabase (REST API) to check dashboard health, run queries, and verify data is flowing through to the BI layer. Read-only by default.

**Server init parameters:**
- `looker_base_url: str` — Looker instance URL
- `looker_client_id: str` / `looker_client_secret: str` — Looker API credentials
- `metabase_base_url: str` — Metabase instance URL
- `metabase_username: str` / `metabase_password: str` — Metabase credentials

---

#### `bi_check_dashboard_health`

**Description:** Checks whether a dashboard is rendering without errors. Attempts to load the dashboard and reports element count, error state, and last modification time. Use this as the first step in a BI investigation to determine scope of breakage.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dashboard_id` | `str` | Yes | Dashboard ID. Looker: numeric string (e.g., `"42"`). Metabase: numeric string (e.g., `"7"`). |
| `tool` | `"looker" \| "metabase"` | Yes | Which BI tool. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "bi_check_dashboard_health",
  "params": {
    "dashboard_id": "42",
    "tool": "looker"
  }
}
```

**Example response shape:**
```json
{
  "dashboard_id": "42",
  "tool": "looker",
  "title": "Revenue Overview",
  "status": "error",
  "error_detail": "LookML error: dimension 'orders.fulfillment_status' does not exist in view 'orders'",
  "element_count": 8,
  "elements_with_errors": 3,
  "last_updated_at": "2026-02-17T14:22:00Z",
  "url": "https://company.looker.com/dashboards/42"
}
```

**Notes:**
- `status` values: `"ok"` (all elements rendered), `"error"` (at least one element failed), `"unknown"` (could not load dashboard metadata).
- For Metabase, `error_detail` may be null even when `status="error"` — Metabase's API does not always surface individual card errors at the dashboard level.

---

#### `bi_run_look`

**Description:** Executes a Looker Look (a saved query) and returns the results. Looker-only. Use this to verify that a Look is returning data and to sample the results for data quality investigation.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `look_id` | `int` | Yes | The Looker Look ID. |
| `limit` | `int` | No | Maximum rows to return. Default: `1000`. Max: `5000`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "bi_run_look",
  "params": {
    "look_id": 88,
    "limit": 100
  }
}
```

**Example response shape:**
```json
{
  "look_id": 88,
  "title": "Orders by Status - Last 30 Days",
  "row_count": 5,
  "rows": [
    {"orders.status": "completed", "orders.count": "8241"},
    {"orders.status": "placed", "orders.count": "1203"},
    {"orders.status": "shipped", "orders.count": "892"},
    {"orders.status": "return_pending", "orders.count": "144"},
    {"orders.status": "returned", "orders.count": "98"}
  ],
  "elapsed_ms": 1840
}
```

**Notes:**
- Looker API returns all values as strings by default. The agent should cast numeric fields as needed.
- Returns `{"error": "look_error", "detail": "..."}` if the Look's LookML is broken or the underlying model has errors.

---

#### `bi_list_dashboards`

**Description:** Returns a list of all accessible dashboards with metadata. Use this to get dashboard IDs for subsequent tool calls or to audit the dashboard landscape.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `tool` | `"looker" \| "metabase"` | Yes | Which BI tool to query. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "bi_list_dashboards",
  "params": {
    "tool": "looker"
  }
}
```

**Example response shape:**
```json
[
  {
    "dashboard_id": "42",
    "title": "Revenue Overview",
    "folder": "Finance",
    "created_at": "2025-06-01T10:00:00Z",
    "last_updated_at": "2026-02-17T14:22:00Z",
    "view_count": 1240,
    "url": "https://company.looker.com/dashboards/42"
  },
  {
    "dashboard_id": "43",
    "title": "Customer Acquisition",
    "folder": "Marketing",
    "created_at": "2025-08-15T09:00:00Z",
    "last_updated_at": "2026-02-10T11:00:00Z",
    "view_count": 320,
    "url": "https://company.looker.com/dashboards/43"
  }
]
```

---

#### `bi_get_dashboard_elements`

**Description:** Returns all tiles/elements within a dashboard, including the query or LookML model each tile references. Use this to identify which models underlie a broken dashboard tile.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dashboard_id` | `str` | Yes | Dashboard ID. |
| `tool` | `"looker" \| "metabase"` | Yes | Which BI tool. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "bi_get_dashboard_elements",
  "params": {
    "dashboard_id": "42",
    "tool": "looker"
  }
}
```

**Example response shape:**
```json
[
  {
    "element_id": "101",
    "title": "Revenue This Month",
    "element_type": "vis",
    "model_name": "revenue",
    "explore_name": "orders",
    "dimensions": ["orders.order_date"],
    "measures": ["orders.total_revenue"],
    "has_error": false,
    "error_detail": null
  },
  {
    "element_id": "102",
    "title": "Orders by Status",
    "element_type": "vis",
    "model_name": "revenue",
    "explore_name": "orders",
    "dimensions": ["orders.status"],
    "measures": ["orders.count"],
    "has_error": true,
    "error_detail": "dimension 'orders.fulfillment_status' referenced in filter does not exist"
  },
  {
    "element_id": "103",
    "title": "Active Customer Count",
    "element_type": "vis",
    "model_name": "customers",
    "explore_name": "customers",
    "dimensions": [],
    "measures": ["customers.active_count"],
    "has_error": false,
    "error_detail": null
  }
]
```

**Notes:**
- For Metabase, `model_name` and `explore_name` are replaced with `question_id` and `database_id` since Metabase uses questions (saved queries) rather than LookML models.

---

#### `bi_verify_row_counts`

**Description:** Runs each element/tile in a dashboard and checks whether it returns at least `min_rows` rows. Returns a per-element report. Use this to detect dashboards that are technically rendering but returning empty results (a common silent failure mode).

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `dashboard_id` | `str` | Yes | Dashboard ID. |
| `tool` | `"looker" \| "metabase"` | Yes | Which BI tool. |
| `min_rows` | `int` | No | Minimum row count threshold for a tile to be considered healthy. Default: `1`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: true`

**Example call:**
```json
{
  "tool": "bi_verify_row_counts",
  "params": {
    "dashboard_id": "42",
    "tool": "looker",
    "min_rows": 1
  }
}
```

**Example response shape:**
```json
{
  "dashboard_id": "42",
  "tool": "looker",
  "checked_at": "2026-02-19T06:30:00Z",
  "elements": [
    {
      "element_id": "101",
      "title": "Revenue This Month",
      "row_count": 28,
      "meets_threshold": true,
      "error": null
    },
    {
      "element_id": "102",
      "title": "Orders by Status",
      "row_count": null,
      "meets_threshold": false,
      "error": "LookML error: dimension does not exist"
    },
    {
      "element_id": "103",
      "title": "Active Customer Count",
      "row_count": 1,
      "meets_threshold": true,
      "error": null
    }
  ],
  "total_elements": 3,
  "healthy_count": 2,
  "failing_count": 1
}
```

**Notes:**
- This tool executes each tile's query — can be slow on dashboards with many tiles or complex queries. Consider rate limiting.
- `row_count: null` when the element errors — the query could not run.

---

### Category 6: File System Tools

**MCP Server name:** `dbt-project`

**What this server does:** Reads raw files from the local dbt project directory — SQL models, schema YAML, `dbt_project.yml`, and LookML files. All operations are local filesystem reads. No compilation or execution.

**Server init parameters:**
- `project_path: str` — absolute path to the dbt project root

---

#### `fs_read_model_sql`

**Description:** Returns the SQL source for a dbt model — either the raw (authored) SQL or the compiled SQL (with `ref()` and `source()` resolved to actual table names). Compiled SQL requires that `dbt compile` has been run and artifacts are current.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `model_name` | `str` | Yes | The dbt model name (without `.sql` extension). |
| `compiled` | `bool` | No | If `true`, returns compiled SQL from `target/compiled/`. If `false`, returns the raw model SQL from `models/`. Default: `false`. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "fs_read_model_sql",
  "params": {
    "model_name": "stg_orders",
    "compiled": false
  }
}
```

**Example response shape:**
```json
{
  "model_name": "stg_orders",
  "compiled": false,
  "file_path": "/home/de/jaffle_shop/models/staging/stg_orders.sql",
  "sql": "WITH source AS (\n    SELECT * FROM {{ source('raw', 'orders') }}\n),\n\nrenamed AS (\n    SELECT\n        id AS order_id,\n        customer_id,\n        ordered_at AS order_date,\n        status,\n        amount\n    FROM source\n)\n\nSELECT * FROM renamed\n",
  "line_count": 17,
  "last_modified": "2026-02-15T11:30:00Z"
}
```

**Notes:**
- Returns `{"error": "model_not_found", "model_name": "..."}` if the model file does not exist.
- Returns `{"error": "compiled_not_found", ...}` if `compiled=true` but no compiled artifact exists (likely `dbt compile` not yet run).

---

#### `fs_read_schema_yaml`

**Description:** Reads and parses a schema YAML file (typically `schema.yml` or `_sources.yml`) from the dbt project. Returns the parsed content as a dict. Use this to inspect model documentation, column descriptions, test definitions, and source configurations as they appear in source files.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `schema_path` | `str` | Yes | Path to the YAML file. Relative paths are resolved from `project_path`. Example: `models/staging/schema.yml`. |

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "fs_read_schema_yaml",
  "params": {
    "schema_path": "models/staging/schema.yml"
  }
}
```

**Example response shape:**
```json
{
  "file_path": "/home/de/jaffle_shop/models/staging/schema.yml",
  "content": {
    "version": 2,
    "models": [
      {
        "name": "stg_orders",
        "description": "Staged orders from raw source",
        "columns": [
          {
            "name": "order_id",
            "description": "Primary key for orders",
            "tests": ["not_null", "unique"]
          },
          {
            "name": "status",
            "description": "Current order status",
            "tests": [
              {
                "accepted_values": {
                  "values": ["placed", "shipped", "completed", "return_pending", "returned"]
                }
              }
            ]
          }
        ]
      }
    ]
  },
  "last_modified": "2026-02-15T11:30:00Z"
}
```

---

#### `fs_list_models`

**Description:** Lists all models in the dbt project, with optional filtering by tag, schema, or materialization type. Use this to understand the project structure, find all models of a certain type, or scope an investigation.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `tag` | `str \| None` | No | Filter by dbt tag. Example: `"finance"`. Reads tag metadata from `manifest.json`. Default: `null`. |
| `schema` | `str \| None` | No | Filter by target schema name. Example: `"dbt_staging"`. Default: `null`. |
| `materialization` | `str \| None` | No | Filter by materialization type: `"table"`, `"view"`, `"incremental"`, `"ephemeral"`. Default: `null`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "fs_list_models",
  "params": {
    "materialization": "incremental",
    "schema": "dbt_prod"
  }
}
```

**Example response shape:**
```json
[
  {
    "model_name": "fct_orders",
    "node_id": "model.jaffle_shop.fct_orders",
    "file_path": "models/marts/fct_orders.sql",
    "schema": "dbt_prod",
    "materialization": "incremental",
    "tags": ["finance", "daily"],
    "description": "Order-grain fact table"
  },
  {
    "model_name": "fct_sessions",
    "node_id": "model.jaffle_shop.fct_sessions",
    "file_path": "models/marts/fct_sessions.sql",
    "schema": "dbt_prod",
    "materialization": "incremental",
    "tags": ["product", "daily"],
    "description": "User session-grain fact table"
  }
]
```

---

#### `fs_read_project_config`

**Description:** Reads and parses `dbt_project.yml` — the project-level configuration file. Returns it as a dict. Use this to understand global model path configurations, variable definitions, hooks, and default materializations.

**Parameters:** None.

**Return type:** `dict`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "fs_read_project_config",
  "params": {}
}
```

**Example response shape:**
```json
{
  "file_path": "/home/de/jaffle_shop/dbt_project.yml",
  "content": {
    "name": "jaffle_shop",
    "version": "1.0.0",
    "profile": "jaffle_shop",
    "model-paths": ["models"],
    "analysis-paths": ["analyses"],
    "test-paths": ["tests"],
    "seed-paths": ["seeds"],
    "macro-paths": ["macros"],
    "snapshot-paths": ["snapshots"],
    "target-path": "target",
    "clean-targets": ["target", "dbt_packages"],
    "vars": {
      "payment_methods": ["credit_card", "coupon", "bank_transfer", "gift_card"],
      "start_date": "2025-01-01"
    },
    "models": {
      "jaffle_shop": {
        "staging": {
          "+materialized": "view",
          "+schema": "staging"
        },
        "marts": {
          "+materialized": "table",
          "+schema": "prod"
        }
      }
    }
  }
}
```

---

#### `fs_find_models_referencing`

**Description:** Finds all models that reference a given source or model using `{{ ref('...') }}` or `{{ source('...', '...') }}` in their SQL. Use this to trace forward lineage at the file level — useful when `manifest.json` is stale or when you want to understand raw file dependencies.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `source_or_model` | `str` | Yes | The name to search for. For `ref()` targets, use the model name. For `source()` targets, use `source_name.table_name` format. Example: `"raw_orders"` or `"raw.orders"`. |

**Return type:** `list[dict]`

**MCP annotations:**
- `readOnlyHint: true`
- `destructiveHint: false`
- `idempotentHint: true`
- `openWorldHint: false`

**Example call:**
```json
{
  "tool": "fs_find_models_referencing",
  "params": {
    "source_or_model": "stg_orders"
  }
}
```

**Example response shape:**
```json
[
  {
    "model_name": "orders",
    "file_path": "models/marts/orders.sql",
    "reference_type": "ref",
    "reference_expression": "ref('stg_orders')",
    "line_number": 4
  },
  {
    "model_name": "order_items",
    "file_path": "models/marts/order_items.sql",
    "reference_type": "ref",
    "reference_expression": "ref('stg_orders')",
    "line_number": 7
  }
]
```

**Notes:**
- Scans all `.sql` files under `project_path/models/` using regex: `ref\(['"]target_name['"]\)` or `source\(['"]source_name['"],\s*['"]table_name['"]\)`.
- Operates on raw SQL files, not compiled SQL — faster than parsing manifest but may miss macro-generated references.

---

### Category 7: Computer Use (Fallback — Not an MCP Tool)

Computer use is not a tool in this toolset. It is a fallback capability of the underlying agent — the ability to control a browser or desktop UI when no structured API is available.

**When to invoke computer use:**

The agent should only fall back to computer use when:
1. The required information is not available through any tool in this spec.
2. The target system has no accessible API (e.g., legacy Tableau Server on an air-gapped network, a BI tool with no REST API, an on-premise system with only a web UI).
3. The MCP tool call has failed with a `connection_failed` or `auth_error` and the agent cannot self-remediate.

**Concrete examples where computer use may be justified:**
- Tableau Server (the REST API is complex and often locked down; computer use can screenshot a dashboard as a last resort).
- Legacy on-premise BI tools with no REST API.
- A BI tool configuration page that cannot be reached via API but must be verified.

**Computer use is NOT justified for:**
- Any operation in this spec. All seven tool categories have programmatic API backing.
- Looker, Metabase, dbt Cloud, Airflow, Prefect, Snowflake, BigQuery — all have real APIs. There is no reason to browser-drive these.

**What the agent must document when it uses computer use:**

When the agent falls back to computer use, it must log an entry in `LEARNINGS.md` with:
1. Which tool was accessed via computer use.
2. What information was retrieved.
3. Why the structured API path was not available.
4. Whether a new MCP tool should be built to cover this gap (and if so, file a `BACKLOG.md` item).

The goal is to make computer use self-eliminating: every time it's used, it generates a signal to build the structured tool that replaces it. Computer use is the gap detector, not the permanent solution.

---

## Tool Coverage Matrix

The following table maps common Agent DE investigation scenarios to the tool categories they require. A filled cell indicates the category is used in that scenario. A "primary" marking indicates the category is the main workhorse for that scenario.

| Scenario | Artifact | Warehouse | dbt Cloud | Orchestrator | BI API | File System | Computer Use |
|---|---|---|---|---|---|---|---|
| **WT-02: Revenue Investigation** (dashboard wrong, tracing to source) | primary | primary | supporting | supporting | primary | supporting | fallback only |
| **WT-04: Schema Drift Detection** (column renamed in source) | primary | primary | supporting | supporting | primary | supporting | fallback only |
| **WT-05: Slow Query** (identifying and diagnosing expensive queries) | supporting | primary | supporting | supporting | supporting | supporting | fallback only |
| **WT-06: Data Staleness** (stale source, stale pipeline) | primary | primary | primary | primary | supporting | — | fallback only |
| **WT-07: PII Detection** (finding unmasked PII columns) | primary | supporting | supporting | — | — | supporting | fallback only |
| **WT-08: Duplicate Detection** (finding duplicate keys) | supporting | primary | supporting | supporting | supporting | — | fallback only |

**Notes on the matrix:**

- **WT-02 (Revenue Investigation):** Starts in BI API (dashboard health check, element errors), works backward through Artifact (lineage, blast radius from failing model), runs diagnostic queries via Warehouse, checks Orchestrator for recent run failures, and uses dbt Cloud to confirm last successful run and fetch recent run_results.

- **WT-04 (Schema Drift Detection):** Artifact tools provide the declared schema. Warehouse tools provide the actual schema. `warehouse_detect_schema_drift` is the core tool. BI API confirms whether the drift has propagated to broken dashboards. dbt Cloud confirms whether the drift caused a run failure.

- **WT-05 (Slow Query):** Predominantly Warehouse: `warehouse_get_query_history` identifies slow queries against the table, `warehouse_explain_query` diagnoses them. Artifact tools provide model context (what model generates this table, what tests it has). Orchestrator confirms whether slow queries are causing DAG timeouts.

- **WT-06 (Data Staleness):** All four operational tool categories are needed. Artifact (`dbt_get_source_freshness` from local file). Warehouse (`warehouse_check_freshness` live check). dbt Cloud (`dbtcloud_get_source_freshness` from last run). Orchestrator (last run timing, task failure detection). BI API (whether staleness is visible in dashboards).

- **WT-07 (PII Detection):** Almost entirely Artifact (`dbt_scan_pii_risk` is the primary tool). Warehouse is used to sample actual column values and confirm presence of PII data. File System is used to read schema YAML and confirm tagging gaps.

- **WT-08 (Duplicate Detection):** Warehouse is the primary tool (`warehouse_detect_duplicates`). Artifact provides context on which models lack uniqueness tests. Orchestrator confirms whether duplicates appeared after a specific run.

---

## Gap Analysis

The following gaps exist in this toolset. These are not things to build immediately — they are known limitations to track.

**Gap 1: Cross-stack lineage (no single tool connects dbt → Airflow → BI)**

The toolset has excellent within-stack lineage (dbt's `manifest.json` gives full dbt node lineage) but no cross-stack lineage. There is no single tool that says: "this Looker dashboard tile depends on this dbt model, which is populated by this Airflow DAG, which loads from this source." The agent must assemble this picture by making three separate tool calls and reasoning about the connections. This is sufficient for the current walkthrough scenarios but becomes a usability issue at scale. A cross-stack lineage index (even a simple config file mapping DAG → dbt job → BI dashboard) would significantly reduce agent reasoning load.

**Gap 2: Real-time schema events (all schema inspection is poll-based)**

Every schema check in this toolset is poll-based: the agent asks "what is the schema now?" rather than receiving an event when the schema changes. For WT-04 (schema drift detection), the agent catches drift by periodically running `warehouse_detect_schema_drift`. A push-based schema change notification (Snowflake dynamic data masking events, BigQuery schema change notifications via Pub/Sub) would allow the agent to react immediately rather than discovering drift on the next poll cycle. This is an infrastructure gap, not a tooling gap — requires warehouse event infrastructure that most orgs don't have yet.

**Gap 3: Credential management (each server needs secrets — no unified agent secrets layer)**

Each MCP server requires its own credentials at init time. There is no unified secrets layer. In a production deployment with multiple MCP servers (`dbt-artifacts`, `warehouse`, `dbt-cloud`, `orchestrator`, `bi-api`, `dbt-project`), the agent needs to be initialized with 15–20 individual secrets. This is a deployment complexity problem, not a functional problem. A unified agent secrets manager (injected at runtime, not hardcoded in server init) would simplify deployment significantly. Candidates: HashiCorp Vault, AWS Secrets Manager, or a simple environment variable convention.

**Gap 4: Semantic lineage (SQL-level lineage within models — needs sqlglot integration)**

`dbt_get_lineage` gives model-level lineage (which models depend on which models). It does not give column-level lineage (which column in model B is derived from which column in model A). Column-level lineage requires SQL parsing — specifically, integrating `sqlglot` to parse the compiled SQL of each model and trace column transformations. Without this, the agent cannot answer "the `amount` column in `fct_orders` — is it sourced from `stg_orders.amount` or from `stg_payments.amount`?" This is a P2 enhancement: useful but not required for the core walkthrough scenarios.

**Gap 5: Data catalog integration (DataHub, Atlan, Collibra — not yet in spec)**

Many production data orgs have a data catalog layer (DataHub, Atlan, Collibra, Alation) that stores business metadata, data steward assignments, sensitivity classifications, and cross-system lineage. None of these are in this toolset. The agent currently reconstructs catalog-like information from dbt artifacts and warehouse INFORMATION_SCHEMA. For orgs with active data catalogs, an MCP server wrapping the catalog API would give the agent access to business context (owner, sensitivity, SLA) that is not present in technical metadata. This is a P2 consideration — most early adopters will not have a mature data catalog.

---

## Implementation Priority

Tools are ranked by which walkthrough scenarios they unblock and by implementation complexity.

### P0 — Required for any Agent DE scenario

These three server/tool sets are the minimum viable toolset. Without them, the agent cannot perform any of the walkthrough scenarios.

| Server | Tools | Why P0 |
|---|---|---|
| `dbt-artifacts` | All 9 tools | Ground truth for all dbt project structure, lineage, schema, tests, run results. No network calls — fastest category to implement. |
| `warehouse` | `warehouse_execute`, `warehouse_get_schema`, `warehouse_detect_schema_drift`, `warehouse_check_freshness`, `warehouse_detect_duplicates` | Direct warehouse access is required for every WT scenario. |
| `dbt-project` | All 5 tools | Local file reads — trivial to implement. Required for reading raw SQL and YAML when manifest is stale. |

**Estimated implementation effort (P0):** 3–5 days for a developer familiar with Python and the dbt artifact schema. The `dbt-artifacts` and `dbt-project` servers require no external dependencies beyond JSON/YAML parsing. The `warehouse` server requires the Snowflake Python connector (`snowflake-connector-python`) and/or the BigQuery client library (`google-cloud-bigquery`).

### P1 — Required for monitoring and operational scenarios

These tools unlock the staleness, orchestration, and cloud-triggered investigation scenarios (WT-06, WT-02 fully).

| Server | Tools | Why P1 |
|---|---|---|
| `dbt-cloud` | All 6 tools | Required to trigger re-runs after drift detection, fetch remote artifacts, check source freshness from cloud. |
| `orchestrator` | All 6 tools | Required to diagnose pipeline failures, fetch task logs, identify DAG-level failures that caused data issues. |

**Estimated implementation effort (P1):** 2–3 days each. The dbt Cloud server is a thin wrapper over the dbt Cloud REST API v2 — well-documented and stable. The Orchestrator server requires two clients (Airflow REST API and Prefect Python client) but the tool interface is unified, so backend-specific logic is contained.

### P2 — Required for full BI-layer coverage

| Server | Tools | Why P2 |
|---|---|---|
| `bi-api` | All 5 tools | Required for full WT-02 investigation (dashboard health), WT-04 confirmation (drift visible in BI). Less critical if BI tool is directly accessible via warehouse queries. |

**Estimated implementation effort (P2):** 3–4 days. Looker API 4.0 is well-documented. Metabase API is less formally documented but functional. The main complexity is handling the different data models (Looker's LookML explore model vs. Metabase's question/collection model) behind a unified interface.

### Fallback — Computer Use

Available from day one. No implementation required. The agent's underlying capability handles it. Every use of computer use should generate a backlog item to build the structured tool that replaces it.

---

## Versioning and Stability Notes

The following versions are pinned for stability. These are the versions the tool implementations should target.

| System | Version | Notes |
|---|---|---|
| **dbt artifacts** | dbt 1.7+ | `manifest.json`, `catalog.json`, `run_results.json`, and `sources.json` schema stabilized in 1.7. The `metadata.dbt_schema_version` field in each artifact encodes the schema version. The tool implementations should validate this field and return an error if the artifact version is incompatible. |
| **Warehouse SQL (INFORMATION_SCHEMA)** | ANSI SQL:2011 | `INFORMATION_SCHEMA.COLUMNS`, `INFORMATION_SCHEMA.TABLES` are ANSI standard and stable across Snowflake, BigQuery, and DuckDB. Warehouse-specific extensions (Snowflake's `QUERY_HISTORY`, BigQuery's `JOBS`) are accessed only in the tools that explicitly require them. |
| **dbt Cloud API** | v2 | Stable since 2024. v3 is in beta as of early 2026. Pin to v2 until v3 is generally available and the migration path is clear. Base URL: `https://cloud.getdbt.com/api/v2`. |
| **Airflow REST API** | v2 | Stable since Airflow 2.0. All endpoints used in this spec are under `/api/v1/` (confusingly named — the REST API version is v1 within Airflow 2.x). |
| **Prefect Python client** | `prefect>=2.0` | Prefect 3 (2024) introduced breaking changes from Prefect 1. Pin to Prefect 2.x or 3.x explicitly — do not support both without explicit version detection. |
| **Looker API** | 4.0 | Stable, preferred over the deprecated 3.1 API. Accessed via the `looker-sdk` Python package (`pip install looker-sdk`). |
| **Metabase API** | No versioning | Metabase does not formally version its API. Test against the target deployment version. Major endpoint changes are announced in Metabase release notes. |
| **MCP annotation format** | agentskills.io Dec 2025 | `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint` per the Agent Skills Open Standard. This spec uses the Dec 2025 version. Update annotations if the standard evolves. |

---

*Document generated 2026-02-19. Author: CTO-Agent. Feeds: implementation sprint for Agent DE MCP server build.*
