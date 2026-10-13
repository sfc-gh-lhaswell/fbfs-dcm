#!/usr/bin/env python3
"""
check_breaking.py — Detect breaking changes against published column contracts.

Reads:
  - out/plan/plan_result.json  (DCM plan output)
  - contracts/*.yml            (published column contracts)

A change is BREAKING if it:
  1. DROPs a consumer view listed in a contract
  2. DROPs or renames a column on a contracted SERVE view
  3. Changes the data type of a contracted column

Exit code:
  0  — No breaking changes (or ALLOW_BREAKING=true)
  1  — Breaking changes detected and ALLOW_BREAKING is not set

Usage:
  python scripts/check_breaking.py
  ALLOW_BREAKING=true python scripts/check_breaking.py
"""

import json
import os
import sys
import glob
import yaml


def load_contracts(contracts_dir="contracts"):
    """Load all YAML column contracts from the contracts directory."""
    contracts = {}
    for path in glob.glob(os.path.join(contracts_dir, "*.yml")):
        with open(path) as f:
            doc = yaml.safe_load(f)
        if doc and "contract" in doc:
            c = doc["contract"]
            key = f"{c.get('schema', 'SERVE')}.{c['view']}"
            contracts[key] = {
                "file": os.path.basename(path),
                "columns": {col["name"]: col["type"] for col in c.get("columns", [])},
            }
    return contracts


def load_plan(plan_path="out/plan/plan_result.json"):
    """Load the DCM plan result JSON."""
    if not os.path.exists(plan_path):
        print(f"⚠️  Plan file not found: {plan_path}")
        print("   Run `snow dcm plan --save-output` first.")
        sys.exit(1)
    with open(plan_path) as f:
        return json.load(f)


def check_breaking(plan, contracts):
    """Analyze plan operations for breaking changes against contracts."""
    breaking = []
    summary_lines = []

    operations = plan if isinstance(plan, list) else plan.get("operations", [])

    for op in operations:
        op_type = op.get("operation", op.get("type", "UNKNOWN")).upper()
        obj_name = op.get("name", op.get("object_name", ""))
        obj_type = op.get("object_type", "").upper()

        # Normalize the object name to just SCHEMA.OBJECT
        parts = obj_name.rsplit(".", 2)
        if len(parts) >= 2:
            short_name = f"{parts[-2]}.{parts[-1]}"
        else:
            short_name = obj_name

        summary_lines.append(f"- **{op_type}** {obj_type} `{obj_name}`")

        # Check 1: DROP of a contracted view
        if op_type == "DROP" and short_name in contracts:
            breaking.append(
                f"🚨 DROP of contracted view `{obj_name}` "
                f"(contract: {contracts[short_name]['file']})"
            )

        # Check 2: ALTER on a contracted view — look for column changes
        if op_type == "ALTER" and short_name in contracts:
            contract_cols = contracts[short_name]["columns"]
            changes = op.get("changes", op.get("details", []))
            if isinstance(changes, list):
                for change in changes:
                    change_type = change.get("type", "").upper()
                    col_name = change.get("column", change.get("name", ""))
                    if change_type in ("DROP_COLUMN", "REMOVE") and col_name in contract_cols:
                        breaking.append(
                            f"🚨 Column DROP `{col_name}` on contracted view `{obj_name}`"
                        )
                    if change_type in ("RENAME_COLUMN", "RENAME") and col_name in contract_cols:
                        breaking.append(
                            f"🚨 Column RENAME `{col_name}` on contracted view `{obj_name}`"
                        )
                    if change_type in ("ALTER_COLUMN", "MODIFY") and col_name in contract_cols:
                        new_type = change.get("new_type", change.get("to_type", ""))
                        if new_type and new_type.upper() != contract_cols[col_name].upper():
                            breaking.append(
                                f"🚨 Type change `{col_name}`: "
                                f"{contract_cols[col_name]} → {new_type} "
                                f"on contracted view `{obj_name}`"
                            )

    return breaking, summary_lines


def main():
    contracts = load_contracts()
    plan = load_plan()
    breaking, summary = check_breaking(plan, contracts)

    allow_breaking = os.environ.get("ALLOW_BREAKING", "").lower() == "true"

    # Print markdown summary
    print("## DCM Plan Summary\n")
    if summary:
        print("### Operations")
        for line in summary:
            print(line)
    else:
        print("_No operations in plan — infrastructure is up to date._")

    print()

    if breaking:
        print("### ⚠️ Breaking Changes Detected\n")
        for b in breaking:
            print(b)
        print()
        if allow_breaking:
            print(
                "✅ `ALLOW_BREAKING=true` is set — proceeding despite breaking changes."
            )
        else:
            print(
                "❌ Set `ALLOW_BREAKING=true` or add the `breaking-change` label "
                "to the PR to proceed."
            )
            sys.exit(1)
    else:
        print("✅ No breaking changes detected against published contracts.")


if __name__ == "__main__":
    main()
