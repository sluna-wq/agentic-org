"""
pii_scanner.py — Automated PII exposure scanner for dbt warehouses.

Runs three layers of detection:
  1. Schema-level: column names match known PII identifiers
  2. Data-level: non-null row counts in prohibited zones
  3. Pattern-level: regex over VARCHAR columns to catch unlabeled PII

Usage (against local DuckDB from CSVs):
  python3 pii_scanner.py

Usage (against a real DuckDB file):
  python3 pii_scanner.py --db path/to/warehouse.duckdb

In CI: exit code 1 if any CRITICAL violation found.
"""

import duckdb
import re
import sys
import argparse
import json
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration — edit to match your warehouse
# ---------------------------------------------------------------------------

# Column names that are always PII regardless of table
FORBIDDEN_PII_COLUMNS = [
    "email",
    "phone",
    "ssn_last4",
    "ssn",
    "dob",
    "date_of_birth",
    "credit_card",
    "card_number",
    "passport_number",
    "national_id",
    "ip_address",
    "full_name",
    "first_name_last_name",  # concatenated
]

# Tables (or schema prefixes) that are ALLOWED to hold raw PII.
# Everything else is a prohibited zone.
ALLOWLISTED_TABLES = [
    "raw_customers",
    "raw_pii",
    "raw_users",
]

# Mart and staging tables to scan explicitly.
# In a real warehouse: query information_schema to get all non-raw tables.
PROHIBITED_TABLES = [
    "stg_customers",
    "stg_orders",
    "stg_marketing_exports",
    "fct_customer_orders",
    "fct_marketing_reach",
]

# Regex patterns to detect PII-like values in unlabeled columns
PII_PATTERNS = [
    ("email_pattern",  r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"),
    ("phone_pattern",  r"\b\d{3}[-.\s]?\d{3,4}[-.\s]?\d{4}\b"),
    ("ssn_full",       r"\b\d{3}-\d{2}-\d{4}\b"),
]

# EU countries for GDPR Art. 33 check
EU_COUNTRIES = {
    "DE", "FR", "IT", "ES", "NL", "SE", "DK", "PL", "BE", "AT",
    "IE", "FI", "PT", "GR", "CZ", "HU", "RO", "SK", "BG", "HR",
    "SI", "EE", "LV", "LT", "LU", "MT", "CY",
}


# ---------------------------------------------------------------------------
# Scanner
# ---------------------------------------------------------------------------

def get_connection(db_path=None, seeds_path=None):
    """Return a DuckDB connection, loading CSVs if no .duckdb file provided."""
    con = duckdb.connect(db_path or ":memory:")

    if seeds_path:
        import pathlib
        for csv_file in pathlib.Path(seeds_path).glob("*.csv"):
            table_name = csv_file.stem
            try:
                con.execute(
                    f"CREATE TABLE IF NOT EXISTS {table_name} "
                    f"AS SELECT * FROM read_csv_auto('{csv_file}')"
                )
            except Exception as e:
                print(f"  [warn] Could not load {csv_file.name}: {e}")

        # Materialize staging/mart layers (mirrors the buggy dbt project)
        _materialize_buggy_dbt_project(con)

    return con


def _materialize_buggy_dbt_project(con):
    """Replicate the dbt model graph for local investigation."""
    stmts = [
        # staging — stg_customers has the bug
        "CREATE TABLE IF NOT EXISTS stg_customers AS SELECT * FROM raw_customers",
        ("CREATE TABLE IF NOT EXISTS stg_orders AS "
         "SELECT order_id,customer_id,product_id,order_date::DATE AS order_date,"
         "status,amount,region FROM raw_orders"),
        ("CREATE TABLE IF NOT EXISTS stg_marketing_exports AS "
         "SELECT export_id,export_date::DATE AS export_date,customer_id,"
         "export_type,destination,row_count,status FROM raw_marketing_exports"),
        # marts
        ("CREATE TABLE IF NOT EXISTS fct_customer_orders AS "
         "SELECT o.order_id,o.customer_id,o.order_date,o.status,o.amount,o.region,"
         "c.first_name,c.last_name,c.plan,c.country,c.email,c.phone,c.ssn_last4 "
         "FROM stg_orders o LEFT JOIN stg_customers c ON o.customer_id=c.customer_id"),
        ("CREATE TABLE IF NOT EXISTS fct_marketing_reach AS "
         "SELECT e.export_id,e.export_date,e.customer_id,e.export_type,e.destination,"
         "e.status,c.first_name,c.last_name,c.plan,c.country,c.email,c.phone,c.ssn_last4 "
         "FROM stg_marketing_exports e LEFT JOIN stg_customers c ON e.customer_id=c.customer_id"),
    ]
    for stmt in stmts:
        try:
            con.execute(stmt)
        except Exception:
            pass  # table may already exist


def list_all_non_raw_tables(con):
    """
    In a real warehouse: query information_schema.tables filtered to
    non-raw schemas. Here we return the hardcoded prohibited list.
    """
    return PROHIBITED_TABLES


def schema_scan(con, tables):
    """Check column names in each table against the forbidden PII list."""
    violations = []
    for table in tables:
        try:
            cols = [row[0] for row in con.execute(f"DESCRIBE {table}").fetchall()]
            pii_cols = [c for c in cols if c in FORBIDDEN_PII_COLUMNS]
            if pii_cols:
                violations.append({
                    "check": "schema_presence",
                    "severity": "CRITICAL",
                    "table": table,
                    "columns": pii_cols,
                    "detail": f"PII column name(s) present in non-raw table",
                })
        except Exception as e:
            violations.append({
                "check": "schema_presence",
                "severity": "WARNING",
                "table": table,
                "columns": [],
                "detail": f"Could not inspect table: {e}",
            })
    return violations


def data_scan(con, tables):
    """Check for non-null PII values in each table's PII columns."""
    violations = []
    for table in tables:
        try:
            cols = [row[0] for row in con.execute(f"DESCRIBE {table}").fetchall()]
            pii_cols = [c for c in cols if c in FORBIDDEN_PII_COLUMNS]
            for col in pii_cols:
                n = con.execute(
                    f"SELECT COUNT(*) FROM {table} WHERE {col} IS NOT NULL"
                ).fetchone()[0]
                if n > 0:
                    sample = con.execute(
                        f"SELECT {col} FROM {table} WHERE {col} IS NOT NULL LIMIT 1"
                    ).fetchone()[0]
                    violations.append({
                        "check": "data_presence",
                        "severity": "CRITICAL",
                        "table": table,
                        "column": col,
                        "rows_affected": n,
                        "sample": str(sample)[:30],
                        "detail": f"{n} rows with non-null {col}",
                    })
        except Exception as e:
            pass
    return violations


def pattern_scan(con, tables):
    """Regex scan over VARCHAR columns to catch PII not caught by name matching."""
    violations = []
    for table in tables:
        try:
            cols = con.execute(f"DESCRIBE {table}").fetchall()
            varchar_cols = [
                c[0] for c in cols
                if "VARCHAR" in c[1] and c[0] not in FORBIDDEN_PII_COLUMNS
            ]
            for col in varchar_cols:
                for pattern_name, pattern in PII_PATTERNS:
                    try:
                        n = con.execute(
                            f"SELECT COUNT(*) FROM {table} "
                            f"WHERE regexp_matches(CAST({col} AS VARCHAR), '{pattern}')"
                        ).fetchone()[0]
                        if n > 0:
                            violations.append({
                                "check": pattern_name,
                                "severity": "HIGH",
                                "table": table,
                                "column": col,
                                "rows_affected": n,
                                "pattern": pattern,
                                "detail": f"{n} values match {pattern_name} in unlabeled column",
                            })
                    except Exception:
                        pass
        except Exception:
            pass
    return violations


def gdpr_check(con):
    """Check if EU-resident PII reached vendor exports. Returns GDPR findings."""
    findings = []
    try:
        eu_tuple = "('" + "','".join(EU_COUNTRIES) + "')"
        rows = con.execute(f"""
            SELECT
                mr.customer_id,
                mr.first_name,
                mr.last_name,
                mr.country,
                mr.email,
                mr.destination,
                mr.export_date
            FROM fct_marketing_reach mr
            WHERE mr.country IN {eu_tuple}
              AND mr.status = 'sent'
              AND mr.email IS NOT NULL
            ORDER BY mr.country, mr.customer_id
        """).fetchall()
        if rows:
            findings.append({
                "check": "gdpr_art33",
                "severity": "CRITICAL",
                "detail": (
                    f"GDPR Article 33 triggered: {len(rows)} EU-resident record(s) "
                    f"with PII transmitted to vendors. 72-hour notification clock running."
                ),
                "affected": [
                    {
                        "customer_id": r[0],
                        "name": f"{r[1]} {r[2]}",
                        "country": r[3],
                        "destination": r[5],
                        "export_date": str(r[6]),
                    }
                    for r in rows
                ],
            })
    except Exception as e:
        pass  # fct_marketing_reach may not exist or may be clean
    return findings


def run_scanner(con, verbose=True):
    tables = list_all_non_raw_tables(con)

    if verbose:
        print(f"\n[{datetime.utcnow().isoformat()}Z] PII Scanner starting")
        print(f"  Tables to scan: {tables}")

    schema_violations  = schema_scan(con, tables)
    data_violations    = data_scan(con, tables)
    pattern_violations = pattern_scan(con, tables)
    gdpr_findings      = gdpr_check(con)

    all_findings = schema_violations + data_violations + pattern_violations + gdpr_findings
    critical_count = sum(1 for f in all_findings if f.get("severity") == "CRITICAL")

    if verbose:
        print(f"\n{'='*60}")
        print("SCANNER RESULTS")
        print(f"{'='*60}")
        print(f"  Total findings : {len(all_findings)}")
        print(f"  CRITICAL       : {critical_count}")
        print(f"  HIGH           : {sum(1 for f in all_findings if f.get('severity') == 'HIGH')}")

        if schema_violations:
            print("\n[SCHEMA VIOLATIONS]")
            for v in schema_violations:
                print(f"  CRITICAL  {v['table']}: columns {v['columns']} are PII identifiers")

        if data_violations:
            print("\n[DATA VIOLATIONS]")
            for v in data_violations:
                print(f"  CRITICAL  {v['table']}.{v['column']}: {v['rows_affected']} rows exposed  (sample: {v['sample']})")

        if pattern_violations:
            print("\n[PATTERN VIOLATIONS]")
            for v in pattern_violations:
                print(f"  HIGH      {v['table']}.{v['column']}: {v['rows_affected']} values match {v['check']}")

        if gdpr_findings:
            print("\n[GDPR Art. 33]")
            for f in gdpr_findings:
                print(f"  CRITICAL  {f['detail']}")
                for rec in f.get("affected", []):
                    print(f"            {rec['name']} ({rec['country']}) -> {rec['destination']} on {rec['export_date']}")

        if not all_findings:
            print("\n  CLEAN: No PII found outside allowlisted tables.")
        else:
            print(f"\n  ACTION REQUIRED: {critical_count} critical violation(s) detected.")

    return all_findings, critical_count


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PII scanner for dbt warehouse")
    parser.add_argument("--db",    help="Path to DuckDB file (optional)")
    parser.add_argument("--seeds", help="Path to seed CSV directory (for local dev)",
                        default="/Users/santiagoluna/Desktop/claude/agentic-org/walkthroughs/wt07_pii_everywhere/seeds")
    parser.add_argument("--json",  action="store_true", help="Output results as JSON")
    args = parser.parse_args()

    con = get_connection(db_path=args.db, seeds_path=args.seeds)
    findings, critical_count = run_scanner(con, verbose=not args.json)

    if args.json:
        print(json.dumps(findings, indent=2, default=str))

    # CI gate: exit 1 if any critical violations
    sys.exit(1 if critical_count > 0 else 0)
