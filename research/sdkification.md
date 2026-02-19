# SDKification: Data Stack APIs for Agent Data Engineers

**Research Date:** 2026-02-19
**Purpose:** Map every API/SDK surface an agent DE needs for direct programmatic data stack access. Compiled post-WT-04 per DEC-014.

---

## Executive Summary

The Agent Data Engineer operates across a modern data stack — dbt, a cloud warehouse, an orchestrator, and one or more BI tools. The question of *how* the agent interacts with these systems is not cosmetic; it determines what the agent can actually do, how reliably it can do it, and whether the architecture is maintainable at production scale. This document answers that question concretely.

The core principle is **SDK-first, computer use as fallback**. Every tool in the modern data stack — dbt Cloud, Snowflake, BigQuery, Airflow, Prefect, Looker, Metabase — exposes a real API or Python SDK. These APIs return structured data, are deterministic, are fast, and do not break when a UI changes. An agent that reads `manifest.json` directly, queries `INFORMATION_SCHEMA.COLUMNS`, and calls the dbt Cloud REST API is operating at the right layer. An agent that takes screenshots of the dbt Cloud UI and parses HTML is not — it is solving a solved problem the wrong way.

The key finding from this survey: **the data stack is more API-rich than it appears from the outside**. The raw dbt artifacts (`manifest.json`, `catalog.json`, `run_results.json`) answer the majority of questions about lineage, schema, test status, and run history — locally, with no network call. The warehouse's `INFORMATION_SCHEMA` views answer schema drift and query performance questions directly via SQL. dbt Cloud, Airflow, Prefect, and Looker all have complete REST APIs. The one genuine weak point is Tableau, which has a REST API that is complex enough that computer use may sometimes be the pragmatic choice. That is the exception, not the rule.

The recommendation: build the agent DE toolset as an SDK orchestrator, not a browser automation system. The seven tool categories identified in Section 8 (artifact reader, warehouse connector, dbt Cloud client, orchestrator client, BI API client, file system reader, and computer use fallback) cover the full surface of what an agent DE needs to operate autonomously. This document provides the technical foundation for that toolset (BL-026).

---

## The Principle: SDK-First, Computer Use as Fallback

### The Claude Code Analogy

Claude Code operates by reading files directly (`cat main.py`), running bash commands (`pytest tests/`), and calling APIs (`git log --oneline`). It does not take screenshots of VS Code and parse the editor pane. That would be absurd — the file system is directly accessible, structured, and deterministic.

The Agent Data Engineer faces the same choice. When asked "which models failed in the last dbt run?", the agent can:

- **Option A (SDK):** Load `target/run_results.json`, filter `results` where `status != "success"` → returns structured data in milliseconds, zero dependencies on UI state.
- **Option B (Computer Use):** Open dbt Cloud in a browser, navigate to the run history page, parse the HTML or take a screenshot → brittle, slow, breaks on UI changes.

Option A is not just faster. It is categorically more reliable, more composable (the output is structured data, not text), and easier to test.

### The Equivalence Table

| Claude Code does this... | Agent DE equivalent |
|---|---|
| `cat target/manifest.json` | Load dbt manifest artifact directly |
| `psql -c "SELECT ..."` | Execute SQL via warehouse Python connector |
| `curl api.github.com/repos/...` | Call dbt Cloud REST API |
| Read `pyproject.toml` | Read `dbt_project.yml`, schema YAML files |
| Run `pytest` and parse output | Poll `run_results.json` or dbt Cloud API |

### When Computer Use IS the Right Answer

Computer use is appropriate when:

1. **No API exists.** Legacy BI tools (Periscope pre-2022, some custom dashboards, older Sisense versions) have no REST API. Computer use is not a workaround — it is the only path.
2. **The API doesn't cover the needed operation.** Tableau's REST API exists but is complex and incomplete. Certain Looker admin workflows are UI-only. Some Airflow deployments have the UI but not the REST API enabled.
3. **The operation is genuinely UI-bound.** Approving a Snowflake governance workflow in the UI, configuring a Looker connection — one-time admin tasks that aren't worth building SDK wrappers for.
4. **Speed of implementation outweighs reliability.** For prototyping or one-off investigations, computer use is sometimes faster to reach for. The agent should note this and flag it for replacement.

**Rule:** If there is an API, use it. Computer use is a fallback, not a default.

---

## Section 1: dbt Artifacts (Local, No API Call Needed)

dbt's most underutilized feature from an agent perspective is its artifact system. After any `dbt run`, `dbt compile`, or `dbt docs generate`, dbt writes structured JSON files to `target/`. These files are the compiled, resolved output of the entire dbt project — lineage, schema, test definitions, run results, freshness. An agent with access to these files can answer the majority of data stack questions without any network call.

In dbt Cloud, these artifacts are also available via the REST API after each run (see Section 3), so the agent can operate on them even without local file system access.

---

### manifest.json

**Location:** `target/manifest.json` (generated by `dbt compile`, `dbt run`, `dbt test`, `dbt docs generate`)

**Size:** Typically 1–50 MB for real projects. Load once per session.

**Python loading:**
```python
import json

with open("target/manifest.json") as f:
    manifest = json.load(f)

# Top-level keys
# manifest["nodes"]        — models, tests, snapshots, seeds, analyses
# manifest["sources"]      — source definitions
# manifest["exposures"]    — downstream exposures (dashboards, etc.)
# manifest["metrics"]      — dbt metrics (if used)
# manifest["parent_map"]   — node -> list of its parents (what it depends on)
# manifest["child_map"]    — node -> list of its children (what depends on it)
# manifest["metadata"]     — dbt version, generated_at, env
```

**Key fields per node:**

```python
node = manifest["nodes"]["model.jaffle_shop.fct_orders"]

node["name"]              # "fct_orders"
node["resource_type"]     # "model"
node["schema"]            # "prod"
node["database"]          # "analytics"
node["relation_name"]     # "`analytics`.`prod`.`fct_orders`"
node["original_file_path"]  # "models/marts/fct_orders.sql"
node["compiled_code"]     # the fully compiled SQL (after ref/source resolution)
node["raw_code"]          # the original SQL with ref() and source() calls
node["config"]["materialized"]  # "table", "view", "incremental", "ephemeral"
node["config"]["tags"]    # ["finance", "daily"]
node["refs"]              # [["stg_orders"], ["stg_payments"]]  — what this model refs
node["sources"]           # [["jaffle_shop", "orders"]]  — what sources it uses
node["depends_on"]["nodes"]  # full node IDs of parents
node["description"]       # model description from YAML
node["columns"]           # column-level metadata from YAML (not catalog — YAML declared)
node["patch_path"]        # path to the YAML file that declares this model
```

**Test nodes:**
```python
test_node = manifest["nodes"]["test.jaffle_shop.not_null_fct_orders_order_id.ef48b4"]

test_node["name"]         # "not_null_fct_orders_order_id"
test_node["test_metadata"]["name"]  # "not_null"
test_node["test_metadata"]["kwargs"]["column_name"]  # "order_id"
test_node["attached_node"]  # "model.jaffle_shop.fct_orders"
```

**Agent use cases and code:**

*Use case 1: Find all upstream models for a given model (blast radius in reverse)*
```python
def get_upstream_lineage(manifest, node_id, depth=0, max_depth=5):
    """Recursively trace parents of a node."""
    if depth > max_depth:
        return []
    
    parents = manifest["parent_map"].get(node_id, [])
    result = []
    for parent in parents:
        result.append({"node": parent, "depth": depth + 1})
        result.extend(get_upstream_lineage(manifest, parent, depth + 1, max_depth))
    return result

# Who does fct_orders depend on, transitively?
upstream = get_upstream_lineage(manifest, "model.jaffle_shop.fct_orders")
# Returns: [{"node": "model.jaffle_shop.stg_orders", "depth": 1}, 
#           {"node": "source.jaffle_shop.jaffle_shop.orders", "depth": 2}, ...]
```

*Use case 2: Blast radius — what breaks if stg_orders changes?*
```python
def get_downstream_blast_radius(manifest, node_id, depth=0, max_depth=10):
    """Recursively trace children of a node."""
    children = manifest["child_map"].get(node_id, [])
    result = []
    for child in children:
        result.append({"node": child, "depth": depth + 1})
        result.extend(get_downstream_blast_radius(manifest, child, depth + 1, max_depth))
    return result

blast = get_downstream_blast_radius(manifest, "model.jaffle_shop.stg_orders")
# Returns all models + tests + exposures that transitively depend on stg_orders
```

*Use case 3: Find all tests on a model*
```python
def get_tests_for_model(manifest, model_name):
    tests = []
    for node_id, node in manifest["nodes"].items():
        if node["resource_type"] == "test":
            if node.get("attached_node") == f"model.{manifest['metadata']['project_id']}.{model_name}":
                tests.append({
                    "test_name": node["name"],
                    "test_type": node["test_metadata"]["name"],
                    "column": node["test_metadata"]["kwargs"].get("column_name"),
                })
    return tests

# Example output:
# [{"test_name": "not_null_fct_orders_order_id", "test_type": "not_null", "column": "order_id"},
#  {"test_name": "unique_fct_orders_order_id", "test_type": "unique", "column": "order_id"}]
```

*Use case 4: Find all models by tag*
```python
def get_models_by_tag(manifest, tag):
    return [
        node["name"]
        for node_id, node in manifest["nodes"].items()
        if node["resource_type"] == "model"
        and tag in node["config"].get("tags", [])
    ]

pii_models = get_models_by_tag(manifest, "pii")
```

*Use case 5: Find all SELECT * patterns (for PII propagation detection)*
```python
import re

def find_select_star_models(manifest):
    matches = []
    for node_id, node in manifest["nodes"].items():
        if node["resource_type"] == "model":
            raw = node.get("raw_code", "")
            if re.search(r"SELECT\s+\*", raw, re.IGNORECASE):
                matches.append({
                    "model": node["name"],
                    "file": node["original_file_path"],
                })
    return matches
```

---

### catalog.json

**Location:** `target/catalog.json` (generated by `dbt docs generate`)

**What it contains:** The actual schema of every model and source *as it exists in the warehouse*, captured at generate time. This is ground truth for column types, unlike `manifest.json` which only has YAML-declared column metadata.

**Python loading:**
```python
with open("target/catalog.json") as f:
    catalog = json.load(f)

# catalog["nodes"]    — models and snapshots
# catalog["sources"]  — sources
```

**Key fields per node:**
```python
node = catalog["nodes"]["model.jaffle_shop.fct_orders"]

node["metadata"]["type"]        # "BASE TABLE"
node["metadata"]["schema"]      # "prod"
node["metadata"]["database"]    # "analytics"
node["metadata"]["comment"]     # table-level comment if set

# Column definitions (ground truth from warehouse):
node["columns"]["order_id"] = {
    "type": "NUMBER",           # warehouse-native type
    "index": 1,
    "name": "order_id",
    "comment": "Primary key of the orders table"
}
node["columns"]["amount"] = {
    "type": "FLOAT",
    "index": 2,
    "name": "amount",
    "comment": None
}

node["stats"]["row_count"]["value"]  # row count at catalog generate time (if available)
node["stats"]["bytes"]["value"]      # table size in bytes (Snowflake)
```

**Agent use cases:**

*Use case 1: Column existence check — does `customer_lifetime_value` exist in `dim_customers`?*
```python
def column_exists(catalog, model_name, column_name):
    # Try nodes first, then sources
    for node_id, node in catalog["nodes"].items():
        if node_id.endswith(f".{model_name}"):
            return column_name.lower() in {c.lower() for c in node["columns"]}
    return False
```

*Use case 2: Type validation — is `order_id` a NUMBER or TEXT?*
```python
def get_column_type(catalog, model_name, column_name):
    for node_id, node in catalog["nodes"].items():
        if node_id.endswith(f".{model_name}"):
            col = node["columns"].get(column_name.upper()) or node["columns"].get(column_name.lower())
            return col["type"] if col else None
    return None
```

*Use case 3: PII scan — find all column names matching PII patterns across all models*
```python
import re

PII_PATTERNS = [
    r"email", r"phone", r"ssn", r"social.?security", r"credit.?card",
    r"passport", r"driver.?licen", r"date.?of.?birth", r"dob",
    r"ip.?address", r"first.?name", r"last.?name", r"full.?name",
    r"address", r"zip.?code", r"postal",
]

def find_pii_columns(catalog):
    findings = []
    for node_id, node in catalog["nodes"].items():
        for col_name, col_info in node["columns"].items():
            for pattern in PII_PATTERNS:
                if re.search(pattern, col_name, re.IGNORECASE):
                    findings.append({
                        "model": node_id,
                        "column": col_name,
                        "type": col_info["type"],
                        "pattern_matched": pattern,
                    })
                    break
    return findings
```

---

### run_results.json

**Location:** `target/run_results.json` (generated after `dbt run`, `dbt test`, `dbt build`)

**What it contains:** The outcome of every node executed in the last dbt invocation — status, timing, failure messages, adapter response.

**Python loading:**
```python
with open("target/run_results.json") as f:
    run_results = json.load(f)

run_results["metadata"]["generated_at"]  # ISO timestamp of run
run_results["elapsed_time"]              # total run time in seconds
run_results["args"]                      # dict of CLI args used

# Each result in the results array:
result = run_results["results"][0]
result["unique_id"]       # "model.jaffle_shop.fct_orders"
result["status"]          # "success", "error", "warn", "skip", "pass", "fail"
result["execution_time"]  # seconds this node took
result["failures"]        # count of test failures (for test nodes)
result["message"]         # e.g. "OK created table (5283 rows)" or error text

result["timing"]  # list of timing phases
# [{"name": "compile", "started_at": "...", "completed_at": "..."},
#  {"name": "execute", "started_at": "...", "completed_at": "..."}]

result["adapter_response"]  # warehouse-specific metadata
# Snowflake: {"_message": "SUCCESS 5283", "rows_affected": 5283}
# BigQuery: {"bytes_processed": 12345678, "slot_ms": 450}
```

**Agent use cases:**

*Use case 1: Which models failed in the last run?*
```python
def get_failed_models(run_results):
    failed = []
    for result in run_results["results"]:
        if result["status"] in ("error", "fail"):
            failed.append({
                "node": result["unique_id"],
                "status": result["status"],
                "message": result["message"],
                "execution_time": result["execution_time"],
            })
    return failed
```

*Use case 2: Execution timing analysis — find slowest models*
```python
def get_slowest_models(run_results, top_n=10):
    models = [
        {"node": r["unique_id"], "execution_time": r["execution_time"]}
        for r in run_results["results"]
        if r["unique_id"].startswith("model.")
    ]
    return sorted(models, key=lambda x: x["execution_time"], reverse=True)[:top_n]
```

*Use case 3: Silent skip detection (the WT-06 scenario)*
```python
def detect_silent_skips(run_results, expected_model_patterns):
    """
    Detect when critical models were skipped but run still exited 0.
    expected_model_patterns: list of substrings that should appear in executed nodes
    """
    executed = {r["unique_id"] for r in run_results["results"] if r["status"] != "skip"}
    skipped = {r["unique_id"] for r in run_results["results"] if r["status"] == "skip"}
    
    missing_critical = []
    for pattern in expected_model_patterns:
        if not any(pattern in node for node in executed):
            # Was it skipped, or never in the selector?
            skipped_match = [n for n in skipped if pattern in n]
            missing_critical.append({
                "pattern": pattern,
                "skipped_nodes": skipped_match,
                "in_selector": len(skipped_match) > 0,
            })
    
    return missing_critical
```

---

### sources.json

**Location:** `target/sources.json` (generated by `dbt source freshness`)

**What it contains:** The freshness check results for every source defined with a `freshness:` block in `schema.yml`.

**Key fields:**
```python
with open("target/sources.json") as f:
    sources_data = json.load(f)

result = sources_data["results"][0]
result["unique_id"]         # "source.jaffle_shop.jaffle_shop.orders"
result["status"]            # "pass", "warn", "error"
result["max_loaded_at"]     # ISO timestamp of most recent record in source
result["snapshotted_at"]    # when the freshness check ran
result["max_loaded_at_time_ago_in_s"]  # seconds since last record
result["criteria"]["warn_after"]       # {"count": 12, "period": "hour"}
result["criteria"]["error_after"]      # {"count": 24, "period": "hour"}
```

**Agent use case: source freshness without any API call**
```python
def get_stale_sources(sources_data, status_filter=("warn", "error")):
    stale = []
    for result in sources_data["results"]:
        if result["status"] in status_filter:
            hours_ago = result["max_loaded_at_time_ago_in_s"] / 3600
            stale.append({
                "source": result["unique_id"],
                "status": result["status"],
                "hours_since_last_record": round(hours_ago, 1),
                "last_record_at": result["max_loaded_at"],
            })
    return stale
```

---

## Section 2: Warehouse SQL Layer (Direct Query Access)

The warehouse is the most powerful tool in the agent's kit. Every modern cloud warehouse exposes `INFORMATION_SCHEMA` views, query history tables, and explain plan interfaces — all accessible via SQL and Python connectors.

### Python SDK Access

**Snowflake Python Connector:**
```python
import snowflake.connector
import pandas as pd

conn = snowflake.connector.connect(
    user="agent_svc",
    password="...",          # or private_key_file for key-pair auth
    account="xy12345.us-east-1",
    warehouse="AGENT_WH",
    database="ANALYTICS",
    schema="PROD",
    role="TRANSFORMER",
)

cur = conn.cursor()
cur.execute("SELECT CURRENT_VERSION()")
print(cur.fetchone())  # ('8.10.0',)

# To DataFrame:
cur.execute("SELECT * FROM information_schema.columns WHERE table_schema = 'PROD' LIMIT 100")
df = cur.fetch_pandas_all()

# Using the DictCursor for dict results:
from snowflake.connector import DictCursor
cur = conn.cursor(DictCursor)
cur.execute("SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema = 'PROD'")
rows = cur.fetchall()  # list of dicts

conn.close()
```

**Snowflake with SQLAlchemy (recommended for dbt-adjacent work):**
```python
from sqlalchemy import create_engine, text

engine = create_engine(
    "snowflake://agent_svc:password@xy12345.us-east-1/ANALYTICS/PROD?warehouse=AGENT_WH&role=TRANSFORMER"
)

with engine.connect() as conn:
    result = conn.execute(text("SELECT table_name, row_count FROM information_schema.tables WHERE table_schema = 'PROD'"))
    rows = result.fetchall()
```

**BigQuery Python Client:**
```python
from google.cloud import bigquery
import pandas as pd

# Authentication via ADC (Application Default Credentials) or service account:
client = bigquery.Client(project="my-project")
# Or with service account:
# from google.oauth2 import service_account
# creds = service_account.Credentials.from_service_account_file("sa.json")
# client = bigquery.Client(project="my-project", credentials=creds)

# Simple query:
query = """
    SELECT table_name, column_name, data_type
    FROM `my-project.my_dataset.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_schema = 'my_dataset'
    ORDER BY table_name, ordinal_position
"""
df = client.query(query).to_dataframe()

# With job config (for dry runs, timeouts):
job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
dry_run_job = client.query(query, job_config=job_config)
print(f"This query will process {dry_run_job.total_bytes_processed / 1e9:.2f} GB")
```

**DuckDB (local dev / file-based):**
```python
import duckdb
import pandas as pd

# In-memory:
conn = duckdb.connect()

# File-based:
conn = duckdb.connect("/path/to/warehouse.duckdb")

# DuckDB can also query Parquet, CSV, JSON directly:
conn.execute("CREATE VIEW orders AS SELECT * FROM read_parquet('/data/orders/*.parquet')")

# Query result as DataFrame:
df = conn.execute("SELECT * FROM information_schema.columns").df()

# DuckDB supports EXPLAIN ANALYZE:
plan = conn.execute("EXPLAIN ANALYZE SELECT customer_id, SUM(amount) FROM orders GROUP BY 1").fetchall()
for row in plan:
    print(row[1])  # the plan text
```

---

### Schema Inspection

**The core tool: `INFORMATION_SCHEMA.COLUMNS`**

This view exists in both Snowflake and BigQuery and is the ground truth for what columns actually exist in the warehouse right now.

*Snowflake:*
```sql
-- All columns in schema PROD
SELECT 
    table_name,
    column_name,
    ordinal_position,
    data_type,
    character_maximum_length,
    numeric_precision,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'PROD'
ORDER BY table_name, ordinal_position;
```

*BigQuery:*
```sql
-- All columns in dataset my_dataset
SELECT 
    table_name,
    column_name,
    ordinal_position,
    data_type,
    is_nullable
FROM `my-project.my_dataset.INFORMATION_SCHEMA.COLUMNS`
ORDER BY table_name, ordinal_position;
```

**Schema drift detection — find columns added or removed:**

The agent's approach to schema drift is to compare the *current* state (warehouse INFORMATION_SCHEMA) against the *registered* state (dbt manifest or catalog.json). No scheduled polling needed — the agent can compute this on demand.

```python
def detect_schema_drift(manifest, warehouse_columns: dict) -> dict:
    """
    manifest: loaded manifest.json
    warehouse_columns: dict of {model_name: set of column names} from warehouse INFORMATION_SCHEMA
    Returns: additions, removals, type_changes per model
    """
    drift = {}
    
    for node_id, node in manifest["nodes"].items():
        if node["resource_type"] != "model":
            continue
        
        model_name = node["name"]
        
        # Columns declared in dbt YAML (from manifest — not catalog)
        declared = {col.lower() for col in node["columns"].keys()}
        
        # Columns actually in warehouse
        actual = {col.lower() for col in warehouse_columns.get(model_name, set())}
        
        if not actual:
            continue  # model not in warehouse yet
        
        added = actual - declared      # in warehouse but not in dbt YAML
        removed = declared - actual    # in dbt YAML but not in warehouse
        
        if added or removed:
            drift[model_name] = {
                "added_columns": list(added),
                "removed_columns": list(removed),
            }
    
    return drift

# Fetch current warehouse columns:
cur.execute("""
    SELECT LOWER(table_name), LOWER(column_name)
    FROM information_schema.columns
    WHERE table_schema = 'PROD'
""")
warehouse_columns = {}
for table, col in cur.fetchall():
    warehouse_columns.setdefault(table, set()).add(col)

drift = detect_schema_drift(manifest, warehouse_columns)
```

**Find newly appeared columns (the WT-04 scenario — unexpected column from upstream):**
```sql
-- Snowflake: columns in PROD that weren't there 24 hours ago
-- (Snowflake doesn't have a column creation timestamp, but you can track via QUERY_HISTORY 
--  for the CREATE/ALTER TABLE statement)
SELECT
    q.query_text,
    q.start_time,
    q.end_time,
    q.user_name
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    END_TIME_RANGE_START => DATEADD(hours, -24, CURRENT_TIMESTAMP()),
    RESULT_LIMIT => 1000
)) q
WHERE 
    (LOWER(query_text) LIKE '%alter table%add column%'
     OR LOWER(query_text) LIKE '%create or replace table%')
    AND execution_status = 'SUCCESS'
ORDER BY start_time DESC;
```

**INFORMATION_SCHEMA.TABLES — existence and row counts:**
```sql
-- Snowflake
SELECT 
    table_name,
    table_type,     -- 'BASE TABLE', 'VIEW'
    row_count,      -- approximate, updated after DML
    bytes,          -- table size
    created,        -- creation timestamp
    last_altered    -- last DDL change
FROM information_schema.tables
WHERE table_schema = 'PROD'
ORDER BY table_name;

-- BigQuery (note: row_count not directly available, use __TABLES__ instead)
SELECT 
    table_id,
    creation_time,
    last_modified_time,
    row_count,
    size_bytes,
    type            -- 1=TABLE, 2=VIEW, 3=EXTERNAL
FROM `my-project.my_dataset.__TABLES__`
ORDER BY table_id;
```

---

### Query Performance

**Snowflake QUERY_HISTORY:**

Snowflake maintains a complete queryable history of all SQL executed in the account. This is the primary tool for performance investigations.

```sql
-- Slowest queries in last 7 days against fct_revenue
SELECT
    query_id,
    query_text,
    user_name,
    role_name,
    warehouse_name,
    start_time,
    end_time,
    ROUND(total_elapsed_time / 1000, 2)         AS elapsed_seconds,
    ROUND(execution_time / 1000, 2)             AS execution_seconds,
    ROUND(compilation_time / 1000, 2)           AS compilation_seconds,
    bytes_scanned,
    ROUND(bytes_scanned / 1e9, 2)               AS gb_scanned,
    rows_produced,
    partitions_total,
    partitions_scanned,
    ROUND(partitions_scanned / NULLIF(partitions_total, 0) * 100, 1) AS pct_partitions_scanned,
    query_type,   -- 'SELECT', 'INSERT', 'MERGE', etc.
    execution_status  -- 'SUCCESS', 'FAIL'
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    END_TIME_RANGE_START   => DATEADD(days, -7, CURRENT_TIMESTAMP()),
    END_TIME_RANGE_END     => CURRENT_TIMESTAMP(),
    RESULT_LIMIT           => 10000
))
WHERE 
    LOWER(query_text) LIKE '%fct_revenue%'
    AND execution_status = 'SUCCESS'
ORDER BY total_elapsed_time DESC
LIMIT 20;
```

Snowflake also exposes `QUERY_HISTORY` as a view in `SNOWFLAKE.ACCOUNT_USAGE` (90-day retention, slight delay):
```sql
-- From ACCOUNT_USAGE (requires ACCOUNTADMIN or SNOWFLAKE database access)
SELECT
    query_id,
    query_text,
    total_elapsed_time / 1000 AS elapsed_seconds,
    bytes_scanned,
    rows_produced,
    credits_used_cloud_services
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    start_time >= DATEADD(days, -7, CURRENT_TIMESTAMP())
    AND LOWER(query_text) LIKE '%fct_revenue%'
ORDER BY total_elapsed_time DESC
LIMIT 20;
```

**Key Snowflake QUERY_HISTORY fields:**

| Field | Description | Agent Use |
|---|---|---|
| `QUERY_ID` | Unique identifier | Link to explain plan |
| `QUERY_TEXT` | Full SQL text | Find queries touching a model |
| `TOTAL_ELAPSED_TIME` | Wall clock ms | Slowest queries |
| `EXECUTION_TIME` | Execution-only ms (excl. compile) | True execution cost |
| `COMPILATION_TIME` | Compile/parse ms | High = complex query or cold cache |
| `BYTES_SCANNED` | Data scanned (pre-pruning) | Storage efficiency |
| `PARTITIONS_SCANNED` | Micro-partitions accessed | Pruning effectiveness |
| `PARTITIONS_TOTAL` | Total micro-partitions | Pruning ratio = scanned/total |
| `ROWS_PRODUCED` | Rows returned | Output size |
| `CREDITS_USED_CLOUD_SERVICES` | Cost of query | Cost analysis |

**BigQuery INFORMATION_SCHEMA.JOBS_BY_PROJECT:**
```sql
-- Most expensive queries in last 7 days against a specific table
SELECT
    job_id,
    user_email,
    query,
    creation_time,
    total_slot_ms,
    ROUND(total_bytes_processed / 1e9, 2)       AS gb_processed,
    ROUND(total_bytes_billed / 1e9, 2)           AS gb_billed,
    ROUND(total_slot_ms / 1000 / 3600, 4)        AS slot_hours,
    statement_type,   -- 'SELECT', 'INSERT', 'MERGE', etc.
    state             -- 'DONE', 'RUNNING', 'PENDING'
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE
    creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY) AND CURRENT_TIMESTAMP()
    AND LOWER(query) LIKE '%fct_revenue%'
    AND state = 'DONE'
ORDER BY total_bytes_processed DESC
LIMIT 20;
```

Note: `region-us` must match your BQ region. Use `region-eu` for EU datasets.

**EXPLAIN / Query Plans:**

*Snowflake EXPLAIN:*
```sql
-- Returns structured JSON with full physical plan
EXPLAIN USING JSON
SELECT customer_id, SUM(amount)
FROM prod.fct_orders
WHERE order_date >= '2024-01-01'
GROUP BY customer_id;
```

```python
cur.execute("""
    EXPLAIN USING JSON
    SELECT customer_id, SUM(amount) FROM prod.fct_orders GROUP BY 1
""")
plan_json = cur.fetchone()[0]  # JSON string
import json
plan = json.loads(plan_json)
# plan["GlobalStats"]["partitionsTotal"]   — total partitions
# plan["GlobalStats"]["partitionsAssigned"] — partitions after pruning
# Look for "TableScan" nodes to find what tables are being scanned
```

*BigQuery Dry Run (bytes estimate, no execution):*
```python
job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
dry_run = client.query(
    "SELECT customer_id, SUM(amount) FROM `project.dataset.fct_orders` GROUP BY 1",
    job_config=job_config
)
print(f"Query will process: {dry_run.total_bytes_processed / 1e9:.2f} GB")
# No results — this is just a cost estimate / validation
```

*DuckDB EXPLAIN ANALYZE (local dev):*
```python
result = conn.execute("""
    EXPLAIN ANALYZE
    SELECT customer_id, SUM(amount) FROM orders GROUP BY 1
""").fetchall()
# Returns a text representation of the execution plan with actual timings
for row in result:
    print(row[1])
```

---

### Freshness / Data Recency

**Max timestamp queries — detecting staleness:**
```sql
-- When was the most recent record loaded into fct_revenue_monthly?
SELECT 
    MAX(updated_at)             AS last_record_at,
    DATEDIFF(hour, MAX(updated_at), CURRENT_TIMESTAMP()) AS hours_since_last_record,
    COUNT(*)                    AS total_rows,
    COUNT(CASE WHEN updated_at >= DATEADD(day, -1, CURRENT_TIMESTAMP()) THEN 1 END) AS rows_last_24h
FROM prod.fct_revenue_monthly;
```

**Row count trend — did the table stop growing?**
```python
def detect_growth_stoppage(conn, table_name, lookback_hours=48):
    """
    Compare recent row additions to historical average.
    Requires an updated_at or inserted_at column.
    """
    query = f"""
        SELECT
            DATE_TRUNC('hour', updated_at) AS hour_bucket,
            COUNT(*) AS rows_added
        FROM {table_name}
        WHERE updated_at >= DATEADD(hour, -{lookback_hours}, CURRENT_TIMESTAMP())
        GROUP BY 1
        ORDER BY 1
    """
    cur.execute(query)
    rows = cur.fetchall()
    
    if len(rows) < 2:
        return {"status": "insufficient_data"}
    
    # Check if last 3 hours have 0 new rows
    recent = [r[1] for r in rows[-3:]]
    historical_avg = sum(r[1] for r in rows[:-3]) / max(len(rows) - 3, 1)
    
    if sum(recent) == 0 and historical_avg > 0:
        return {
            "status": "growth_stopped",
            "last_active_hour": rows[-4][0] if len(rows) > 3 else None,
            "historical_hourly_avg": round(historical_avg, 0),
        }
    
    return {"status": "normal", "recent_hourly_avg": round(sum(recent) / 3, 0)}
```

**BigQuery partition freshness:**
```sql
-- Check freshness of a date-partitioned table
SELECT
    partition_id,
    last_modified_time,
    row_count,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_modified_time, HOUR) AS hours_since_modified
FROM `my-project.my_dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'fct_revenue_monthly'
ORDER BY partition_id DESC
LIMIT 7;
```

---

### Lineage via SQL Parsing

**Important distinction:** `INFORMATION_SCHEMA` does not give you lineage. It tells you what columns exist, what tables exist, how big they are — but not what SQL created them or what they depend on. For lineage, the dbt manifest is the right source.

The manifest's `parent_map` and `child_map` are pre-computed from `ref()` and `source()` calls. This is authoritative for any model that goes through dbt.

**When you do need SQL parsing (outside dbt):**

Some data stacks have models or transformations that exist outside dbt — Fivetran transformations, legacy stored procedures, ad hoc queries that hit production tables directly. To detect these undocumented dependencies:

```python
import sqlglot
import sqlglot.expressions as exp

def extract_tables_from_sql(sql: str, dialect: str = "snowflake") -> list[str]:
    """
    Extract all table/view references from a SQL string.
    Uses sqlglot for dialect-aware parsing.
    """
    try:
        tree = sqlglot.parse_one(sql, dialect=dialect)
        tables = []
        for node in tree.walk():
            if isinstance(node, exp.Table):
                parts = [node.catalog, node.db, node.name]
                ref = ".".join(p for p in parts if p)
                if ref:
                    tables.append(ref)
        return list(set(tables))
    except Exception:
        return []

# Usage: scan QUERY_HISTORY for queries touching prod tables, 
# extract dependencies, compare to dbt manifest
# Queries in QUERY_HISTORY that reference PROD tables but aren't in manifest = undocumented access
```

---

## Section 3: dbt Cloud REST API

**Base URL:** `https://cloud.getdbt.com/api/v2/accounts/{account_id}/`

**Authentication:** Token in header — `Authorization: Token {your_service_token}`

Service tokens are created in dbt Cloud under Account Settings > Service Tokens. Use a token with "Job Admin" permissions for read + trigger access.

**Python setup:**
```python
import requests
from typing import Optional

class DbtCloudClient:
    def __init__(self, account_id: int, token: str):
        self.account_id = account_id
        self.base_url = f"https://cloud.getdbt.com/api/v2/accounts/{account_id}"
        self.headers = {
            "Authorization": f"Token {token}",
            "Content-Type": "application/json",
        }
    
    def get(self, path: str, params: dict = None):
        r = requests.get(f"{self.base_url}{path}", headers=self.headers, params=params)
        r.raise_for_status()
        return r.json()
    
    def post(self, path: str, payload: dict = None):
        r = requests.post(f"{self.base_url}{path}", headers=self.headers, json=payload)
        r.raise_for_status()
        return r.json()

client = DbtCloudClient(account_id=12345, token="dbt_abc123...")
```

---

### Key Endpoints

**GET /runs/ — list runs with filtering:**
```python
# List recent runs for a specific job
resp = client.get("/runs/", params={
    "job_definition_id": 456,
    "order_by": "-id",      # newest first
    "limit": 10,
    "offset": 0,
})

run = resp["data"][0]
run["id"]                   # run ID
run["status"]               # 1=Queued, 2=Starting, 3=Running, 10=Success, 20=Error, 30=Cancelled
run["status_humanized"]     # "Success", "Error", "Running", etc.
run["started_at"]           # ISO datetime
run["finished_at"]          # ISO datetime (null if still running)
run["duration_humanized"]   # "3 minutes, 42 seconds"
run["created_at"]           # when the run was triggered
run["trigger"]["cause"]     # "scheduled", "api", "manual"
run["environment_id"]       # which environment this ran in
run["job_id"]               # parent job ID
run["href"]                 # URL to view in dbt Cloud UI
```

Response shape for `/runs/`:
```json
{
  "status": {"code": 200, "is_success": true},
  "data": [
    {
      "id": 789,
      "status": 10,
      "status_humanized": "Success",
      "started_at": "2026-02-19T04:00:02.341Z",
      "finished_at": "2026-02-19T04:07:15.892Z",
      "duration": "433",
      "duration_humanized": "7 minutes, 13 seconds",
      "job_id": 456,
      "environment_id": 101,
      "trigger": {"cause": "scheduled"},
      "href": "https://cloud.getdbt.com/deploy/12345/runs/789"
    }
  ],
  "extra": {"filters": {}, "order_by": "-id", "pagination": {"count": 1, "total_count": 247}}
}
```

**GET /runs/{run_id}/ — single run details:**
```python
run = client.get(f"/runs/789/")["data"]
run["status_humanized"]      # "Success"
run["duration_humanized"]    # "7 minutes, 13 seconds"
run["run_steps"]             # list of step details (if run is complete)
```

**GET /jobs/ — list jobs:**
```python
jobs = client.get("/jobs/", params={"project_id": 111, "environment_id": 101})
job = jobs["data"][0]
job["id"]                    # job ID
job["name"]                  # "Production - Daily"
job["state"]                 # 1=active, 2=deleted
job["triggers"]["schedule"]  # True/False
job["schedule"]["cron"]      # "0 4 * * *"
job["settings"]["threads"]   # 8
job["execute_steps"]         # ["dbt build --select state:modified+"]
job["environment_id"]        # which environment it runs in
```

**POST /jobs/{job_id}/run/ — trigger a run:**
```python
result = client.post(f"/jobs/456/run/", payload={
    "cause": "Triggered by agent DE investigation",
    "steps_override": ["dbt run --select fct_orders+"],  # optional override
    "schema_override": "dev_agent",  # optional schema override
})
new_run_id = result["data"]["id"]
print(f"Triggered run {new_run_id}: {result['data']['href']}")
```

**GET /runs/{run_id}/artifacts/ — list available artifacts:**
```python
artifacts = client.get(f"/runs/789/artifacts/")
# Returns: {"data": ["manifest.json", "run_results.json", "catalog.json", "sources.json"]}
```

**GET /runs/{run_id}/artifacts/{path} — fetch artifact content:**
```python
import json

# Fetch run_results.json from a dbt Cloud run
resp = requests.get(
    f"https://cloud.getdbt.com/api/v2/accounts/12345/runs/789/artifacts/run_results.json",
    headers={"Authorization": "Token dbt_abc123..."}
)
run_results = resp.json()

# Fetch manifest.json
manifest_resp = requests.get(
    f"https://cloud.getdbt.com/api/v2/accounts/12345/runs/789/artifacts/manifest.json",
    headers={"Authorization": "Token dbt_abc123..."}
)
manifest = manifest_resp.json()
```

This is the key pattern for agents that don't have local file system access to dbt target/ — they can pull the latest artifacts from the most recent successful run.

**GET /projects/ — list projects:**
```python
projects = client.get("/projects/")
project = projects["data"][0]
project["id"]
project["name"]              # "Production Analytics"
project["repository"]["remote_url"]  # GitHub repo URL
project["dbt_project_subdirectory"]  # if monorepo
```

**GET /environments/ — list environments:**
```python
environments = client.get("/environments/")
env = environments["data"][0]
env["id"]
env["name"]                  # "Production"
env["type"]                  # "deployment" or "development"
env["credentials_id"]        # which warehouse credentials
env["dbt_version"]           # "1.7.0"
env["custom_branch"]         # override from main
```

---

### Polling Pattern for Monitoring

```python
import time
from dataclasses import dataclass
from typing import Optional

TERMINAL_STATUSES = {"Success", "Error", "Cancelled"}

def poll_run(client: DbtCloudClient, run_id: int, interval_seconds: int = 30, timeout_seconds: int = 3600):
    """
    Poll a dbt Cloud run until it reaches a terminal state.
    Returns the final run data dict.
    Raises TimeoutError if run doesn't complete within timeout.
    """
    elapsed = 0
    while elapsed < timeout_seconds:
        run_data = client.get(f"/runs/{run_id}/")["data"]
        status = run_data["status_humanized"]
        
        print(f"[{elapsed}s] Run {run_id}: {status}")
        
        if status in TERMINAL_STATUSES:
            return run_data
        
        time.sleep(interval_seconds)
        elapsed += interval_seconds
    
    raise TimeoutError(f"Run {run_id} did not complete within {timeout_seconds}s")


def trigger_and_wait(client: DbtCloudClient, job_id: int, cause: str = "Agent trigger") -> dict:
    """Trigger a job and wait for completion. Returns run data with artifacts."""
    trigger_resp = client.post(f"/jobs/{job_id}/run/", payload={"cause": cause})
    run_id = trigger_resp["data"]["id"]
    
    run_data = poll_run(client, run_id)
    
    if run_data["status_humanized"] == "Success":
        # Fetch run_results.json artifact
        artifacts_resp = requests.get(
            f"https://cloud.getdbt.com/api/v2/accounts/{client.account_id}/runs/{run_id}/artifacts/run_results.json",
            headers=client.headers
        )
        run_data["_run_results"] = artifacts_resp.json()
    
    return run_data
```

---

### Source Freshness via API

```python
def get_latest_source_freshness(client: DbtCloudClient, job_id: int) -> dict:
    """Get the most recent source freshness data from dbt Cloud."""
    # Find the most recent successful run for this job
    runs = client.get("/runs/", params={
        "job_definition_id": job_id,
        "order_by": "-id",
        "limit": 5,
        "status": 10,  # Success only
    })["data"]
    
    if not runs:
        return {"error": "No successful runs found"}
    
    latest_run_id = runs[0]["id"]
    
    # Check if sources.json is available (requires dbt source freshness step in job)
    artifacts = client.get(f"/runs/{latest_run_id}/artifacts/")["data"]
    if "sources.json" not in artifacts:
        return {"error": "sources.json not in artifacts — job may not run source freshness"}
    
    sources_resp = requests.get(
        f"https://cloud.getdbt.com/api/v2/accounts/{client.account_id}/runs/{latest_run_id}/artifacts/sources.json",
        headers=client.headers
    )
    return sources_resp.json()
```

---

### What dbt Cloud API Doesn't Give You

- **Real-time streaming:** The API is request/response, not push. For event-driven triggers, use webhooks (see Section 4 — dbt Cloud Webhooks).
- **Model-level performance within a run:** The API gives run-level timing. For per-model timing, fetch and parse `run_results.json` artifact.
- **Direct SQL execution:** The API has no `/query` endpoint. All SQL must go through the warehouse connector.
- **Development environment run history:** dbt Cloud API covers deployment environments. Development IDE runs are not exposed.
- **Cross-account views:** Each account_id is a separate API namespace. No cross-account aggregation.

---

## Section 4: Orchestrator APIs

### Apache Airflow REST API (v2)

**Base URL:** `http://your-airflow-host/api/v1/`

**Authentication:** Basic auth or JWT. Airflow 2.x ships with a built-in REST API (enabled by default in 2.x with the `[api]` config section).

```python
import requests
from requests.auth import HTTPBasicAuth

airflow_auth = HTTPBasicAuth("airflow_user", "airflow_password")
AIRFLOW_BASE = "http://airflow.internal:8080/api/v1"

def airflow_get(path, params=None):
    r = requests.get(f"{AIRFLOW_BASE}{path}", auth=airflow_auth, params=params)
    r.raise_for_status()
    return r.json()

def airflow_post(path, payload=None):
    r = requests.post(f"{AIRFLOW_BASE}{path}", auth=airflow_auth, json=payload)
    r.raise_for_status()
    return r.json()
```

**GET /dags — list DAGs:**
```python
dags = airflow_get("/dags", params={"limit": 100, "only_active": True})
dag = dags["dags"][0]
dag["dag_id"]             # "dbt_production_daily"
dag["is_active"]          # True
dag["is_paused"]          # False
dag["schedule_interval"]  # "0 4 * * *"
dag["next_dagrun"]        # ISO datetime of next scheduled run
dag["owners"]             # ["data-team"]
dag["tags"]               # [{"name": "dbt"}, {"name": "production"}]
```

**GET /dags/{dag_id}/dagRuns — list DAG runs:**
```python
dag_runs = airflow_get(
    "/dags/dbt_production_daily/dagRuns",
    params={"limit": 10, "order_by": "-start_date"}
)

run = dag_runs["dag_runs"][0]
run["dag_run_id"]         # "scheduled__2026-02-19T04:00:00+00:00"
run["state"]              # "success", "failed", "running", "queued"
run["start_date"]         # ISO datetime
run["end_date"]           # ISO datetime (null if running)
run["logical_date"]       # the logical execution date
run["run_type"]           # "scheduled", "manual", "backfill"
run["conf"]               # dict of run-level config overrides
```

**POST /dags/{dag_id}/dagRuns — trigger a DAG:**
```python
result = airflow_post("/dags/dbt_production_daily/dagRuns", payload={
    "dag_run_id": f"agent_triggered_{int(time.time())}",
    "conf": {"triggered_by": "agent_de", "reason": "Manual recovery after schema fix"},
    "logical_date": "2026-02-19T04:00:00+00:00",  # optional, defaults to now
})
print(f"Triggered: {result['dag_run_id']} — state: {result['state']}")
```

**GET /dags/{dag_id}/tasks/{task_id}/instances — task-level status:**
```python
# Get status of a specific task within a DAG run
task_instance = airflow_get(
    "/dags/dbt_production_daily/dagRuns/scheduled__2026-02-19T04:00:00+00:00/taskInstances/dbt_run_marts"
)
task_instance["state"]           # "success", "failed", "skipped", "up_for_retry"
task_instance["start_date"]      # task start time
task_instance["end_date"]        # task end time
task_instance["duration"]        # seconds
task_instance["try_number"]      # which attempt (1 = first, 2 = first retry, etc.)
task_instance["max_tries"]       # max retries configured

# List all task instances in a run:
all_tasks = airflow_get(
    "/dags/dbt_production_daily/dagRuns/scheduled__2026-02-19T04:00:00+00:00/taskInstances"
)
```

**Get task logs:**
```python
# Fetch logs for a specific task instance
logs_resp = requests.get(
    f"{AIRFLOW_BASE}/dags/dbt_production_daily/dagRuns/scheduled__2026-02-19T04:00:00+00:00/taskInstances/dbt_run_marts/logs/1",
    auth=airflow_auth
)
log_text = logs_resp.text  # raw log output — parse for "0 rows" or error patterns
```

**Agent use case: did the dbt job actually run, and when did it last succeed?**
```python
def get_last_successful_dag_run(dag_id: str) -> Optional[dict]:
    runs = airflow_get(f"/dags/{dag_id}/dagRuns", params={
        "state": "success",
        "order_by": "-start_date",
        "limit": 1,
    })
    return runs["dag_runs"][0] if runs["dag_runs"] else None

last_success = get_last_successful_dag_run("dbt_production_daily")
if last_success:
    hours_ago = (datetime.utcnow() - datetime.fromisoformat(last_success["end_date"].replace("Z", ""))).seconds / 3600
    print(f"Last successful run: {hours_ago:.1f} hours ago")
```

---

### Prefect API (v2 / Prefect Cloud)

**Two access modes:**

1. **Prefect Cloud:** `https://api.prefect.cloud/api/accounts/{account_id}/workspaces/{workspace_id}/`
2. **Self-hosted Prefect server:** `http://prefect-server:4200/api/`

**Python client (recommended over raw REST):**
```python
import asyncio
from prefect.client.orchestration import get_client
from prefect.client.schemas.filters import FlowRunFilter, FlowFilter
from prefect.client.schemas.sorting import FlowRunSort

async def get_recent_flow_runs(flow_name: str, limit: int = 10):
    async with get_client() as client:
        flow_runs = await client.read_flow_runs(
            flow_filter=FlowFilter(name={"any_": [flow_name]}),
            sort=FlowRunSort.EXPECTED_START_TIME_DESC,
            limit=limit,
        )
        return flow_runs

runs = asyncio.run(get_recent_flow_runs("dbt-production-daily"))
```

**Flow run fields:**
```python
run = runs[0]
run.id                          # UUID
run.name                        # "dbt-production-daily-xyz"
run.state.name                  # "Completed", "Failed", "Running", "Crashed"
run.state.type                  # StateType.COMPLETED, StateType.FAILED
run.start_time                  # datetime
run.end_time                    # datetime
run.total_run_time              # timedelta
run.flow_id                     # UUID of parent flow
run.deployment_id               # UUID of deployment that triggered this
run.parameters                  # dict of run parameters
run.tags                        # ["production", "dbt"]
```

**Fetch logs for a flow run:**
```python
async def get_flow_run_logs(flow_run_id: str):
    async with get_client() as client:
        logs = await client.read_logs(
            log_filter=LogFilter(flow_run_id={"any_": [flow_run_id]})
        )
        return [(log.level, log.message) for log in logs]

logs = asyncio.run(get_flow_run_logs(str(runs[0].id)))
# Parse logs for: "0 rows affected", "Skipping", error messages
```

**Detect silent skip (the WT-06 pattern) in Prefect:**
```python
async def detect_silent_skip(flow_run_id: str, required_task_names: list[str]):
    """
    Check if required tasks were skipped in an otherwise-successful flow run.
    """
    async with get_client() as client:
        task_runs = await client.read_task_runs(
            task_run_filter=TaskRunFilter(
                flow_run_id={"any_": [flow_run_id]}
            )
        )
    
    task_states = {tr.name: tr.state.name for tr in task_runs}
    
    skipped_required = []
    for task_name in required_task_names:
        state = task_states.get(task_name, "NOT_IN_RUN")
        if state in ("Skipped", "NOT_IN_RUN"):
            skipped_required.append({"task": task_name, "state": state})
    
    return skipped_required
```

**Trigger a deployment via Prefect API:**
```python
async def trigger_deployment(deployment_name: str, parameters: dict = None):
    async with get_client() as client:
        deployment = await client.read_deployment_by_name(deployment_name)
        flow_run = await client.create_flow_run_from_deployment(
            deployment.id,
            parameters=parameters or {},
            tags=["agent-triggered"],
        )
        return flow_run.id
```

---

### dbt Cloud Webhooks

dbt Cloud supports outbound webhooks for event-driven monitoring. This is the alternative to polling `/runs/` in a loop.

**Event types:**
- `job.run.started` — run has begun
- `job.run.completed` — run finished (success or error — check status field)
- `job.run.errored` — run specifically errored

**Webhook payload (on delivery to your endpoint):**
```json
{
  "eventId": "evt_abc123",
  "timestamp": "2026-02-19T04:07:15Z",
  "eventType": "job.run.completed",
  "webhookName": "Production Monitoring",
  "data": {
    "accountId": "12345",
    "jobId": "456",
    "runId": "789",
    "environmentId": "101",
    "runStatus": "Success",
    "runStatusCode": 10,
    "runStatusHumanized": "Success",
    "runReason": "scheduled",
    "runStartedAt": "2026-02-19T04:00:02Z",
    "runFinishedAt": "2026-02-19T04:07:15Z",
    "runDurationHumanized": "7 minutes, 13 seconds"
  }
}
```

**Verify webhook signatures** (dbt Cloud signs payloads with HMAC-SHA256):
```python
import hmac
import hashlib
from fastapi import FastAPI, Request, HTTPException

app = FastAPI()
WEBHOOK_SECRET = "your_webhook_secret"

@app.post("/dbt-webhook")
async def handle_dbt_webhook(request: Request):
    body = await request.body()
    signature = request.headers.get("x-dbt-signature-256")
    
    expected = hmac.new(
        WEBHOOK_SECRET.encode(),
        msg=body,
        digestmod=hashlib.sha256,
    ).hexdigest()
    
    if not hmac.compare_digest(f"sha256={expected}", signature or ""):
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    payload = await request.json()
    event_type = payload["eventType"]
    run_id = payload["data"]["runId"]
    
    if event_type == "job.run.errored":
        # Trigger agent investigation
        await handle_run_failure(run_id)
    
    return {"status": "received"}
```

---

### GitHub Actions API

**Base URL:** `https://api.github.com/repos/{owner}/{repo}/`

**Authentication:** Personal Access Token or GitHub App token.

```python
GH_TOKEN = "ghp_..."
GH_HEADERS = {
    "Authorization": f"Bearer {GH_TOKEN}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}

# List recent workflow runs
resp = requests.get(
    "https://api.github.com/repos/acme/analytics/actions/runs",
    headers=GH_HEADERS,
    params={"per_page": 20, "branch": "main", "status": "completed"}
)
runs = resp.json()["workflow_runs"]

run = runs[0]
run["id"]               # run ID
run["name"]             # workflow name
run["status"]           # "completed"
run["conclusion"]       # "success", "failure", "cancelled", "skipped"
run["created_at"]       # ISO datetime
run["updated_at"]       # ISO datetime
run["head_sha"]         # commit SHA that triggered this
run["head_commit"]["message"]  # commit message
run["html_url"]         # link to the run in GitHub UI
```

**Agent use case: was there a deploy that could have caused this regression?**
```python
def find_deploys_before_incident(repo: str, incident_time: str, lookback_hours: int = 24) -> list:
    """
    Find workflow runs (likely deploys) that completed in the window before an incident.
    """
    cutoff = datetime.fromisoformat(incident_time) - timedelta(hours=lookback_hours)
    
    resp = requests.get(
        f"https://api.github.com/repos/{repo}/actions/runs",
        headers=GH_HEADERS,
        params={"per_page": 50, "status": "completed"},
    )
    
    return [
        {
            "run_id": r["id"],
            "workflow": r["name"],
            "conclusion": r["conclusion"],
            "finished_at": r["updated_at"],
            "commit": r["head_commit"]["message"],
            "sha": r["head_sha"][:8],
        }
        for r in resp.json()["workflow_runs"]
        if datetime.fromisoformat(r["updated_at"].replace("Z", "")) > cutoff
    ]
```

---

## Section 5: BI Tool APIs

### Looker API (3.1 / 4.0)

Looker has the most complete BI API in the modern data stack. Nearly everything you can do in the UI is available via REST.

**Base URL:** `https://your-company.looker.com/api/4.0/`

**Authentication:** OAuth2 client credentials flow.

```python
import requests

LOOKER_BASE = "https://acme.looker.com/api/4.0"
CLIENT_ID = "abc123"
CLIENT_SECRET = "xyz789"

def get_looker_token():
    r = requests.post(
        f"{LOOKER_BASE}/login",
        data={"client_id": CLIENT_ID, "client_secret": CLIENT_SECRET},
    )
    r.raise_for_status()
    return r.json()["access_token"]

token = get_looker_token()
looker_headers = {"Authorization": f"Bearer {token}"}
```

**GET /looks — list all Looks:**
```python
resp = requests.get(f"{LOOKER_BASE}/looks", headers=looker_headers)
looks = resp.json()

look = looks[0]
look["id"]              # 42
look["title"]           # "Daily Revenue by Region"
look["space"]["name"]   # folder/space it lives in
look["model"]["id"]     # LookML model name
look["query"]["view"]   # explore name
look["last_viewed_at"]  # when a user last viewed it
look["last_run_at"]     # when it last returned data
look["public"]          # True/False
```

**POST /looks/{look_id}/run/{result_format} — run a Look and get results:**
```python
# Run a Look and get results as JSON
resp = requests.post(
    f"{LOOKER_BASE}/looks/42/run/json",
    headers=looker_headers,
    params={
        "limit": 1000,
        "apply_formatting": False,
        "apply_vis": False,
    }
)

results = resp.json()
# results is a list of dicts, one per row:
# [{"orders.order_date": "2026-02-19", "orders.total_revenue": 125432.50}, ...]

# Also available: /run/csv, /run/xlsx, /run/png (for visualizations)
```

**Agent use case: is dashboard X still returning data?**
```python
def check_look_health(look_id: int) -> dict:
    """Programmatically verify a Look is returning data — no screenshot needed."""
    resp = requests.post(
        f"{LOOKER_BASE}/looks/{look_id}/run/json",
        headers=looker_headers,
        params={"limit": 1, "apply_formatting": False},
    )
    
    if resp.status_code != 200:
        return {"healthy": False, "error": resp.text}
    
    data = resp.json()
    
    if isinstance(data, dict) and "errors" in data:
        return {"healthy": False, "error": data["errors"]}
    
    return {
        "healthy": len(data) > 0,
        "row_count_sample": len(data),
        "columns": list(data[0].keys()) if data else [],
    }
```

**GET /dashboards/{dashboard_id} — dashboard metadata:**
```python
resp = requests.get(f"{LOOKER_BASE}/dashboards/15", headers=looker_headers)
dashboard = resp.json()

dashboard["id"]             # 15
dashboard["title"]          # "Executive Revenue Dashboard"
dashboard["dashboard_elements"]  # list of tiles/charts on the dashboard
for element in dashboard["dashboard_elements"]:
    element["id"]           # tile ID
    element["title"]        # tile title
    element["look_id"]      # if it's a saved Look
    element["query"]        # inline query definition
```

**GET /lookml_models/{model}/explores/{explore_name} — field catalog:**
```python
resp = requests.get(
    f"{LOOKER_BASE}/lookml_models/revenue_model/explores/orders",
    headers=looker_headers,
    params={"fields": "id,name,fields"},
)
explore = resp.json()

# All dimensions and measures available in this explore:
for field in explore["fields"]["dimensions"]:
    field["name"]           # "orders.order_date"
    field["type"]           # "date_date"
    field["sql"]            # underlying SQL expression
    field["label"]          # "Order Date"

for field in explore["fields"]["measures"]:
    field["name"]           # "orders.total_revenue"
    field["type"]           # "sum"
    field["sql"]            # "${TABLE}.amount"
```

**LookML via Git (recommended for lineage):**

LookML is stored as plain files in a Git repository. The agent can read `.lkml` files directly to understand Looker's view of the data, independent of the Looker API. This is often faster and more complete than querying the API for field metadata.

```python
import lkml  # pip install lkml

with open("views/orders.view.lkml") as f:
    view = lkml.load(f)

view["views"][0]["name"]              # "orders"
view["views"][0]["sql_table_name"]    # "prod.fct_orders"
for dim in view["views"][0]["dimensions"]:
    dim["name"]   # "order_date"
    dim["sql"]    # "${TABLE}.order_date"
    dim["type"]   # "date"
```

---

### Metabase API

**Base URL:** `http://your-metabase.internal/api/`

**Authentication:** Session token via POST /session.

```python
METABASE_BASE = "http://metabase.internal/api"

# Authenticate
auth_resp = requests.post(f"{METABASE_BASE}/session", json={
    "username": "agent@company.com",
    "password": "password123",
})
session_token = auth_resp.json()["id"]
mb_headers = {"X-Metabase-Session": session_token}
```

**GET /api/dashboard/:id — dashboard metadata:**
```python
resp = requests.get(f"{METABASE_BASE}/dashboard/5", headers=mb_headers)
dashboard = resp.json()

dashboard["name"]              # "Revenue Overview"
dashboard["ordered_cards"]     # list of cards (questions) on the dashboard
for card in dashboard["ordered_cards"]:
    card["card"]["id"]         # question/card ID
    card["card"]["name"]       # "Total Revenue MTD"
    card["card"]["query_type"] # "query" or "native" (SQL)
    card["card"]["dataset_query"]  # the query definition
```

**POST /api/card/:id/query — run a question and get results:**
```python
resp = requests.post(
    f"{METABASE_BASE}/card/42/query",
    headers=mb_headers,
    json={}
)
result = resp.json()

result["data"]["rows"]        # list of rows (each is a list of values)
result["data"]["cols"]        # column metadata
# [{"name": "order_date", "display_name": "Order Date", "base_type": "type/Date"}, ...]
result["row_count"]           # total rows
result["status"]              # "completed"

# Simple row count check:
row_count = result["row_count"]
print(f"Question 42 returned {row_count} rows")
```

**Agent use case: verify dashboard row counts match expectations:**
```python
def verify_dashboard_health(dashboard_id: int, expected_min_rows: int = 1) -> list[dict]:
    dashboard = requests.get(f"{METABASE_BASE}/dashboard/{dashboard_id}", headers=mb_headers).json()
    
    results = []
    for card in dashboard["ordered_cards"]:
        card_id = card["card"]["id"]
        card_name = card["card"]["name"]
        
        query_result = requests.post(
            f"{METABASE_BASE}/card/{card_id}/query", headers=mb_headers, json={}
        ).json()
        
        row_count = query_result.get("row_count", 0)
        results.append({
            "card_id": card_id,
            "card_name": card_name,
            "row_count": row_count,
            "healthy": row_count >= expected_min_rows,
        })
    
    return results
```

---

### Tableau REST API

Tableau has a complete REST API but it is substantially more complex than Looker or Metabase. Authentication alone requires multiple steps.

**Authentication (Personal Access Token):**
```python
TABLEAU_SERVER = "https://tableau.company.com"
TABLEAU_SITE = "CompanySite"
TABLEAU_TOKEN_NAME = "agent-token"
TABLEAU_TOKEN_VALUE = "xxx"

auth_resp = requests.post(
    f"{TABLEAU_SERVER}/api/3.17/auth/signin",
    json={
        "credentials": {
            "personalAccessTokenName": TABLEAU_TOKEN_NAME,
            "personalAccessTokenSecret": TABLEAU_TOKEN_VALUE,
            "site": {"contentUrl": TABLEAU_SITE},
        }
    }
)
auth_data = auth_resp.json()["credentials"]
tableau_token = auth_data["token"]
site_id = auth_data["site"]["id"]
tableau_headers = {"x-tableau-auth": tableau_token}
```

**GET /workbooks — list workbooks:**
```python
resp = requests.get(
    f"{TABLEAU_SERVER}/api/3.17/sites/{site_id}/workbooks",
    headers=tableau_headers,
)
workbooks = resp.json()["workbooks"]["workbook"]
```

**POST /views/{viewId}/data — extract view data:**
```python
# Get data from a specific view as CSV
resp = requests.get(
    f"{TABLEAU_SERVER}/api/3.17/sites/{site_id}/views/{view_id}/data",
    headers=tableau_headers,
    params={"maxAge": 5},  # max 5 minutes cache
)
# Returns CSV data
import csv, io
reader = csv.DictReader(io.StringIO(resp.text))
rows = list(reader)
```

---

### Where Computer Use IS the Right Answer

The rule is API-first. Here is where that rule has genuine exceptions:

| Tool | Situation | Why Computer Use | API Alternative |
|---|---|---|---|
| **Tableau** | Complex admin config, content permissions | REST API exists but incomplete for admin tasks | For data extraction, prefer REST API |
| **Looker** | PDT (persistent derived table) admin | Some admin settings in UI only | Most data access has API |
| **Airflow** | Old deployments (v1.x) without REST API | REST API only in v2+ | Upgrade path or parse web scrape |
| **Legacy BI** | Periscope, older Sisense, Domo | No/poor public API | No alternative — computer use is right |
| **Source SaaS** | CRM/ERP with no export API | No programmatic access | Computer use or vendor escalation |
| **One-time setup** | Connecting dbt Cloud to warehouse | UI wizard, no API equivalent | Skip — agent shouldn't do infra setup |

**Decision heuristic:**
1. Does a REST/SDK API exist? → Use it.
2. Is the API complete enough for this task? → If yes, use it. If partial, use it for what it covers.
3. Is the API complexity > 2x the computer use implementation for this specific task? → Consider computer use with a logged decision.
4. Is this a one-time or rare task? → Computer use acceptable; flag for future SDK investment.

---

## Section 6: API Surface by DE Scenario

This section maps each walkthrough scenario to the concrete APIs the agent would call, in order.

---

### WT-02: The Dashboard Is Wrong (Revenue Investigation)

**Situation:** A BI dashboard showing revenue is returning wrong numbers. Agent must trace from dashboard back to source data to find where the error is introduced.

**Step 1 — Understand the DAG:**
```python
# Load manifest, find fct_revenue and all its upstream models
manifest = json.load(open("target/manifest.json"))
upstream = get_upstream_lineage(manifest, "model.analytics.fct_revenue")
# Result: [{node: "model.analytics.stg_orders", depth: 1}, 
#          {node: "model.analytics.stg_payments", depth: 1},
#          {node: "source.analytics.acme.orders", depth: 2}]
```

**Step 2 — Row count audit at each DAG layer:**
```python
# Execute SQL against warehouse to find where rows drop
audit_queries = {
    "source_orders": "SELECT COUNT(*) FROM raw.acme.orders",
    "stg_orders": "SELECT COUNT(*) FROM prod.stg_orders",
    "fct_revenue": "SELECT COUNT(*) FROM prod.fct_revenue",
}

counts = {}
for name, query in audit_queries.items():
    cur.execute(query)
    counts[name] = cur.fetchone()[0]

# If source_orders=50000, stg_orders=49800, fct_revenue=12000 — 
# the big drop is in fct_revenue, not staging
```

**Step 3 — Read the staging SQL directly:**
```python
# Find the model file path from manifest
node = manifest["nodes"]["model.analytics.fct_revenue"]
sql_path = node["original_file_path"]  # "models/marts/fct_revenue.sql"

# Read the raw SQL to understand the join logic
with open(f"/path/to/dbt/project/{sql_path}") as f:
    raw_sql = f.read()

# Also available: node["compiled_code"] — the fully resolved SQL
```

**Step 4 — Blast radius for the fix:**
```python
# What else depends on stg_orders? (don't want to break other marts)
blast = get_downstream_blast_radius(manifest, "model.analytics.stg_orders")
print(f"Changing stg_orders will affect {len(blast)} downstream nodes")
```

---

### WT-04: The Schema Migration (Schema Drift Detection)

**Situation:** An upstream source added a new column. Agent must detect this drift and assess impact.

**Step 1 — Get registered schema from manifest:**
```python
manifest = json.load(open("target/manifest.json"))
source_node = manifest["sources"]["source.analytics.acme.orders"]
registered_columns = set(source_node["columns"].keys())
```

**Step 2 — Get actual warehouse schema:**
```sql
-- Run against warehouse
SELECT LOWER(column_name)
FROM information_schema.columns
WHERE table_schema = 'RAW_ACME' AND table_name = 'ORDERS'
```

```python
cur.execute("SELECT LOWER(column_name) FROM information_schema.columns WHERE table_schema = 'RAW_ACME' AND table_name = 'ORDERS'")
actual_columns = {row[0] for row in cur.fetchall()}
```

**Step 3 — Compute diff and assess impact:**
```python
added = actual_columns - {c.lower() for c in registered_columns}
removed = {c.lower() for c in registered_columns} - actual_columns

if added:
    print(f"New columns in source: {added}")
    # Find all dbt models that SELECT * from this source (will now silently include new column)
    select_star_models = find_select_star_models(manifest)
    # Cross-reference with models that use this source
    source_users = [
        node_id for node_id, node in manifest["nodes"].items()
        if any(s == ["acme", "orders"] for s in node.get("sources", []))
    ]
```

---

### WT-05: Why Is This Query So Slow?

**Situation:** A model or dashboard is slow. Agent must identify the cause without access to a DBA.

**Step 1 — Find slow queries from QUERY_HISTORY:**
```sql
-- Snowflake: find all queries touching fct_revenue_monthly in last 7 days
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    total_elapsed_time / 1000 AS elapsed_sec,
    bytes_scanned / 1e9 AS gb_scanned,
    partitions_scanned,
    partitions_total,
    ROUND(partitions_scanned / NULLIF(partitions_total, 0) * 100, 1) AS pct_partitions_scanned
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    END_TIME_RANGE_START => DATEADD(days, -7, CURRENT_TIMESTAMP()),
    RESULT_LIMIT => 5000
))
WHERE LOWER(query_text) LIKE '%fct_revenue_monthly%'
ORDER BY total_elapsed_time DESC
LIMIT 10;
```

**Step 2 — EXPLAIN the worst query:**
```python
slow_query_id = "abc123def456"
# Fetch the full query text from QUERY_HISTORY
cur.execute(f"SELECT query_text FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY()) WHERE query_id = '{slow_query_id}'")
query_text = cur.fetchone()[0]

# EXPLAIN it
cur.execute(f"EXPLAIN USING JSON {query_text}")
plan = json.loads(cur.fetchone()[0])
```

**Step 3 — Check materialization config in manifest:**
```python
node = manifest["nodes"]["model.analytics.fct_revenue_monthly"]
materialization = node["config"]["materialized"]  # "view" might be the problem
cluster_by = node["config"].get("cluster_by", [])
```

**Step 4 — Check catalog for column types:**
```python
# Is the join column the right type? (type mismatch = full scan)
catalog = json.load(open("target/catalog.json"))
fct_node = catalog["nodes"]["model.analytics.fct_revenue_monthly"]
order_date_col = fct_node["columns"].get("ORDER_DATE", {})
print(f"order_date type: {order_date_col.get('type')}")  # "TEXT" would explain slow date filters
```

---

### WT-06: The Data Is Stale

**Situation:** A dashboard hasn't updated. Agent must determine whether the pipeline ran, whether dbt ran, and why data is stale.

**Step 1 — Direct freshness check:**
```python
cur.execute("SELECT MAX(updated_at), DATEDIFF(hour, MAX(updated_at), CURRENT_TIMESTAMP()) FROM prod.fct_revenue_monthly")
last_updated, hours_stale = cur.fetchone()
print(f"Table last updated: {last_updated} ({hours_stale} hours ago)")
```

**Step 2 — Check if orchestrator ran the job:**
```python
# Via Airflow:
last_success = get_last_successful_dag_run("dbt_production_daily")
# Via dbt Cloud API:
runs = client.get("/runs/", params={"job_definition_id": 456, "order_by": "-id", "limit": 3})
```

**Step 3 — Parse run logs for silent skip:**
```python
# Fetch run_results.json from last dbt Cloud run
run_results_resp = requests.get(
    f"https://cloud.getdbt.com/api/v2/accounts/{account_id}/runs/{run_id}/artifacts/run_results.json",
    headers=client.headers
)
run_results = run_results_resp.json()

# Detect silently skipped mart models
skipped = detect_silent_skips(run_results, expected_model_patterns=["fct_revenue", "mart_"])
# If skipped is non-empty: the run exited 0 but didn't execute critical models
```

**Step 4 — Determine root cause:**
```python
if hours_stale > 4:
    if not last_success:
        print("CAUSE: Orchestrator job never ran successfully")
    elif skipped:
        print(f"CAUSE: Silent skip — these models were not in selector: {skipped}")
    else:
        print("CAUSE: Pipeline ran but source data is stale — check upstream ETL")
```

---

### WT-07: PII Everywhere

**Situation:** A new compliance audit finds PII columns propagating through the data stack.

**Step 1 — Scan catalog.json for PII column names:**
```python
catalog = json.load(open("target/catalog.json"))
pii_findings = find_pii_columns(catalog)
print(f"Found {len(pii_findings)} potential PII columns across {len(set(f['model'] for f in pii_findings))} models")
```

**Step 2 — Trace which models use the PII source:**
```python
manifest = json.load(open("target/manifest.json"))

# Find all models using source('acme', 'customers')
pii_source_users = [
    node_id for node_id, node in manifest["nodes"].items()
    if node["resource_type"] == "model"
    and any(s == ["acme", "customers"] for s in node.get("sources", []))
]
```

**Step 3 — Find SELECT * propagation:**
```python
# Models that SELECT * from PII sources will propagate all columns
select_star_pii = [
    m for m in find_select_star_models(manifest)
    if m["model"] in [n.split(".")[-1] for n in pii_source_users]
]
```

**Step 4 — Full downstream blast radius:**
```python
# Every model that could have PII from this source
all_pii_downstream = set()
for source_user in pii_source_users:
    downstream = get_downstream_blast_radius(manifest, source_user)
    all_pii_downstream.update(d["node"] for d in downstream)

print(f"PII may have propagated to {len(all_pii_downstream)} downstream models")
```

---

### WT-08: The Duplicate Problem

**Situation:** A dashboard metric shows inflated numbers. Agent suspects duplicates in a staging model.

**Step 1 — Identify duplicates and their signature:**
```sql
-- Find duplicate payment records and their characteristics
SELECT
    order_id,
    amount,
    COUNT(*) AS duplicate_count,
    MIN(created_at) AS first_seen,
    MAX(created_at) AS last_seen,
    DATEDIFF(second, MIN(created_at), MAX(created_at)) AS seconds_between_duplicates
FROM prod.stg_payments
GROUP BY order_id, amount
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;
```

**Step 2 — Confirm ETL retry signature:**
```sql
-- Are duplicates consistently within the same time window? (ETL retry pattern)
SELECT
    payment_id,
    order_id,
    amount,
    created_at,
    LAG(created_at) OVER (PARTITION BY order_id, amount ORDER BY created_at) AS prev_created_at,
    DATEDIFF(
        second,
        LAG(created_at) OVER (PARTITION BY order_id, amount ORDER BY created_at),
        created_at
    ) AS seconds_since_prev
FROM prod.stg_payments
WHERE order_id IN (SELECT order_id FROM (
    SELECT order_id FROM prod.stg_payments GROUP BY order_id HAVING COUNT(*) > 1 LIMIT 20
))
ORDER BY order_id, created_at;
```

If `seconds_since_prev` is consistently ~300 seconds (5 minutes) across all duplicates, this is an ETL retry window pattern.

**Step 3 — Find all marts affected:**
```python
blast = get_downstream_blast_radius(manifest, "model.analytics.stg_payments")
affected_marts = [n["node"] for n in blast if "mart" in n["node"] or "fct" in n["node"]]
```

**Step 4 — Warehouse-side dedup validation:**
```sql
-- Snowflake: confirm dedup fix would work
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '|', amount, '|', DATE_TRUNC('hour', created_at))) AS deduped_rows,
    COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '|', amount, '|', DATE_TRUNC('hour', created_at))) AS duplicates_to_remove
FROM prod.stg_payments;
```

---

## Section 7: Gaps and What Doesn't Exist Yet

### No Unified Cross-Stack Lineage API

Each tool in the data stack maintains its own lineage graph in isolation. dbt's manifest tracks dbt model lineage. Looker knows what LookML explores and views exist. Airflow knows DAG dependencies. None of them talk to each other natively.

Connecting them requires a manual integration layer:
- dbt manifest → maps `stg_orders` to `prod.stg_orders` (the SQL table)
- Looker API → maps explore `orders` to view `orders`, which has `sql_table_name: prod.fct_orders`
- The agent must join these by SQL table name to trace: "which Looker dashboards depend on this dbt model?"

This is solvable but requires the agent to maintain a cross-stack catalog. Tools like Atlan, DataHub, and Metaphor are commercial solutions to this problem. The agent DE either builds this mapping or integrates with one of those platforms (each has its own API).

### No Real-Time Push from Warehouses

All warehouse schema inspection is pull-based. There is no event system that says "a column was just added to table X." The practical options are:

1. **Scheduled polling:** Run schema drift detection on a cron schedule (e.g., every 15 minutes). Adds latency.
2. **CDC (Change Data Capture):** Snowflake Streams, BigQuery Change History — these track data changes, not schema changes.
3. **DDL event hooks:** Snowflake has task and stream capabilities but no native DDL webhook. Requires a polling approach or Snowflake Event Notifications (available in newer Enterprise tiers).

### Orchestrator Log Parsing

Airflow and Prefect return run status (success/failed/running) but not semantic understanding of what happened inside a run. An agent investigating a silent skip must:

1. Fetch the raw log text from the Airflow API or Prefect client.
2. Parse that text for patterns: "0 rows processed," "model not in selector," "DbtRuntimeError," "Skipping because of selector."

This is text parsing against unstructured logs, not a structured API. The log format is not guaranteed to be stable. This is a genuine gap — the agent's log analysis is brittle.

### Cross-Cloud Warehouse

If an organization uses Snowflake for production and BigQuery for a data science sandbox (common), the agent needs both connectors. There is no unified query layer. The agent must:
- Know which database each model lives in
- Route queries to the correct connector
- Handle different SQL dialects (Snowflake's `DATEADD` vs BigQuery's `DATE_ADD`)

dbt handles this via its adapter system. The agent DE should either use dbt's compiled SQL (which is dialect-specific) or use sqlglot for cross-dialect transpilation.

### Agent Authentication Management

Each API in this document requires credentials: warehouse username/password or key pair, dbt Cloud service token, Airflow basic auth, Looker client_id/secret, GitHub PAT. An agent running in production needs a secure way to store and rotate these credentials.

This is not a data stack gap — it is an agent deployment gap. The right solutions are:
- **AWS Secrets Manager / GCP Secret Manager / HashiCorp Vault** for credential storage
- **Service accounts with scoped permissions** (not human user credentials)
- **Credential rotation** — agent tokens should have TTLs
- **Audit logging** — every API call the agent makes should be logged

This is unsolved at the platform level. Each deployment must configure it.

### dbt Core vs dbt Cloud API Gap

dbt Core (open source, CLI) has no REST API. All automation must go through local file system and CLI invocation. dbt Cloud adds the REST API but costs money and requires managed hosting. Organizations running dbt Core in self-hosted Airflow have no `/api/v2/runs` endpoint — they must parse Airflow task logs or run_results.json from the file system directly.

---

## Section 8: Recommended Agent Tool Architecture

Based on the API surface mapped in this document, the Agent Data Engineer requires seven distinct tool categories. Each maps to a discrete integration with a specific interface type.

### Tool 1: dbt Artifact Reader

**Purpose:** Load and query `manifest.json`, `catalog.json`, `run_results.json`, `sources.json` from local file system or dbt Cloud API.

**Interface:** Local file I/O + dbt Cloud REST (for remote artifact fetch).

**Key operations:**
- `load_manifest(path_or_run_id)` — load from disk or fetch from dbt Cloud run
- `get_lineage(node_id, direction)` — upstream or downstream traversal
- `get_blast_radius(node_id)` — full downstream impact
- `get_tests_for_model(model_name)` — test coverage
- `detect_select_star(manifest)` — PII propagation risk
- `get_failed_models(run_results)` — post-run failure summary
- `detect_silent_skips(run_results, expected_patterns)` — the WT-06 pattern

**Why separate from warehouse connector:** Artifact queries are in-memory operations on JSON. No SQL needed. Fast. No warehouse credentials required.

---

### Tool 2: Warehouse Connector

**Purpose:** Execute arbitrary SQL against Snowflake, BigQuery, or DuckDB.

**Interface:** Python database connectors (snowflake-connector-python, google-cloud-bigquery, duckdb).

**Key operations:**
- `execute_query(sql, warehouse="snowflake")` → DataFrame or list of dicts
- `get_schema(schema_name)` → column catalog from INFORMATION_SCHEMA
- `detect_schema_drift(model_name, expected_columns)` → diff
- `get_query_history(table_name, lookback_days)` → performance data
- `check_freshness(table_name, timestamp_column)` → staleness check
- `explain_query(sql)` → execution plan
- `dry_run(sql)` → bytes/cost estimate (BQ) or compile check (Snowflake)

**Dialect handling:** Use dbt's compiled SQL where possible (already dialect-correct). For generated SQL, use sqlglot for transpilation.

---

### Tool 3: dbt Cloud Client

**Purpose:** Interact with dbt Cloud REST API — trigger jobs, poll runs, fetch artifacts, monitor environments.

**Interface:** dbt Cloud REST API v2.

**Key operations:**
- `trigger_job(job_id, cause, steps_override)` → run_id
- `poll_run(run_id, until_terminal=True)` → final run state
- `fetch_artifact(run_id, artifact_name)` → JSON content
- `get_last_run(job_id, status="Success")` → most recent run matching criteria
- `list_jobs(project_id, environment_id)` → job catalog
- `get_source_freshness(job_id)` → freshness data from last run

**Fallback:** If dbt Cloud API is unavailable (self-hosted dbt Core), fall back to local artifact reader + Airflow task log parsing.

---

### Tool 4: Orchestrator Client

**Purpose:** Check run status, trigger runs, and parse logs from Airflow or Prefect.

**Interface:** Airflow REST API v2 or Prefect Python client.

**Key operations:**
- `get_last_dag_run(dag_id, status="success")` → run metadata
- `trigger_dag(dag_id, conf)` → dag_run_id
- `get_task_status(dag_id, dag_run_id, task_id)` → state
- `fetch_task_logs(dag_id, dag_run_id, task_id)` → raw log text
- `detect_silent_skip_in_logs(log_text, patterns)` → pattern match
- `get_run_history(dag_id, lookback_days)` → success/fail timeline

**Log parsing is a first-class concern:** Logs are unstructured text. The agent needs a set of patterns to match: dbt error signatures, skip messages, "0 rows" warnings.

---

### Tool 5: BI API Client

**Purpose:** Verify dashboard health, fetch query results, catalog available reports.

**Interface:** Looker API 4.0 (primary), Metabase API (secondary), Tableau REST API (tertiary).

**Key operations:**
- `check_look_health(look_id)` → row count, error status
- `run_look(look_id, limit)` → actual data rows
- `list_dashboards()` → catalog of available dashboards
- `get_dashboard_elements(dashboard_id)` → tiles and their queries
- `verify_dashboard_row_counts(dashboard_id, expected_min)` → health check
- `get_explore_fields(model, explore)` → field catalog (for lineage bridging)

**Priority order:** Looker API is most complete. Metabase API is simple and reliable. Tableau REST API is last resort — if complexity is too high, flag for computer use.

---

### Tool 6: File System Reader

**Purpose:** Read dbt project source files — SQL models, YAML schema files, `dbt_project.yml`, `profiles.yml`, LookML files.

**Interface:** Direct file I/O (no abstraction needed — this is local or cloned repo access).

**Key operations:**
- Read SQL model files to understand transformation logic
- Read `schema.yml` to understand declared tests, column descriptions, freshness config
- Read `dbt_project.yml` for project-level config (model paths, materializations, vars)
- Read LookML files to understand BI-layer definitions
- Read `.gitignore`, `packages.yml` for project structure

This is the "read the source code" tool. The agent needs to see the actual SQL, not just the compiled output, to understand developer intent.

---

### Tool 7: Computer Use (Fallback Only)

**Purpose:** Access BI tools or administrative interfaces that have no sufficient API.

**Trigger condition:** Explicit check — "does an API exist for this operation?" If no, fall back to computer use. Log the use and the reason.

**Appropriate for:**
- Tableau workbook navigation and data extraction when REST API is insufficient
- Legacy BI tools (Periscope, older Sisense)
- One-time administrative UI flows (connecting a new data source, configuring SSO)
- Debugging a UI issue that is itself the problem (e.g., "the dashboard renders wrong")

**Not appropriate for:** Any operation covered by Tools 1–6.

---

### Tool Summary Table

| Tool | Primary Interface | Fallback | Covers |
|---|---|---|---|
| dbt Artifact Reader | Local JSON files | dbt Cloud API artifacts | Lineage, schema, test coverage, run results |
| Warehouse Connector | Python DB connectors | SQL via dbt Cloud adapter | Schema drift, query perf, freshness, explain |
| dbt Cloud Client | REST API v2 | Local CLI + file system | Run trigger, monitor, artifact fetch |
| Orchestrator Client | Airflow/Prefect API | Log file parsing | Pipeline status, trigger, log analysis |
| BI API Client | Looker API 4.0 | Metabase → Tableau → skip | Dashboard health, data validation |
| File System Reader | Local file I/O | Git clone + read | Source SQL, YAML, LookML |
| Computer Use | Browser automation | — | Legacy tools, UI-only admin |

---

## Conclusion

The modern data stack is substantially more API-rich than it appears. Every production tool — dbt Cloud, Snowflake, BigQuery, Airflow, Prefect, Looker, Metabase — exposes structured, well-documented APIs that an agent can call directly. The agent DE that operates through these APIs is working at the right layer: it gets structured data back, operates deterministically, and does not break when a UI redesign ships. The combined surface of dbt artifacts (local JSON), warehouse INFORMATION_SCHEMA (SQL), and tool REST APIs covers over 90% of what a working data engineer does in a day.

The architectural implication of this survey is significant. The agent DE is not a browser automation system with a data stack plugin — it is an SDK orchestrator. Its seven core tools (artifact reader, warehouse connector, dbt Cloud client, orchestrator client, BI API client, file system reader, computer use fallback) map directly to the seven integration surfaces of the modern data stack. Building these tools well — with proper error handling, credential management, and structured return types — is the engineering foundation for the entire agent capability. Computer use is a genuine and sometimes necessary fallback, but it is the exception. It should be reached for only when the structured API surface is genuinely absent or insufficient.

Three gaps warrant continued attention: cross-stack lineage (no single API connects dbt → Airflow → BI lineage), real-time schema change events (all warehouse schema inspection is poll-based), and agent credential management (each API needs secrets, and no unified agent secrets layer exists in open-source tooling). These are active areas of development in the data ecosystem. The agent DE architecture should be designed to accommodate unified lineage tools (DataHub, Atlan) when they are adopted, event-driven schema monitoring when warehouse platforms expose it, and organization-standard secrets management from day one. These are not blockers — they are known constraints that the toolset is designed to work around.

---

*Document references: LRN-038 (WT-04 SDK insight), DEC-014 (SDK-first directive), BL-026 (agent toolset spec). Next action: translate Section 8 tool architecture into BL-026 implementation spec.*
