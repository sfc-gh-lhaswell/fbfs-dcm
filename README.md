# FBL Financial — DCM Demo

Snowflake Database Change Management (DCM) demo for FBL Financial (life insurance).
Demonstrates versioned infrastructure-as-code deployed through DEV → TEST with
GitHub Actions, breaking-change detection, data contracts, and approval gates.

## Architecture

```
GitHub repo (this)
  ├── manifest.yml          → targets DEV and TEST
  ├── sources/definitions/  → DEFINE statements (tables, views, grants, DMFs)
  ├── contracts/            → published column contracts (YAML)
  ├── scripts/              → breaking-change checker
  └── .github/workflows/    → CI/CD automation

Snowflake
  ├── FBL_DEMO.DCM
  │   ├── POLICY_PROJECT_DEV   (owned by DCM_DEV_DEPLOYER)
  │   └── POLICY_PROJECT_TEST  (owned by DCM_TEST_DEPLOYER)
  ├── FBL_POLICY_DEV
  │   ├── RAW.POLICY           (source table)
  │   ├── RAW.RELEASE_LOG      (deployment history)
  │   └── SERVE.POLICY_V1      (consumer view)
  └── FBL_POLICY_TEST
      └── (same structure)
```

## Quick Start (local)

```bash
# Plan against DEV
snow dcm plan FBL_DEMO.DCM.POLICY_PROJECT_DEV --target DEV --save-output

# Deploy to DEV
snow dcm deploy FBL_DEMO.DCM.POLICY_PROJECT_DEV --target DEV --alias v1.0.0

# Seed data + log release
snow sql -f post_deploy.sql \
  -D VERSION=v1.0.0 -D ENV=DEV -D GIT_SHA=abc1234 -D DEPLOYED_BY=$USER

# Run data quality tests
snow dcm test FBL_DEMO.DCM.POLICY_PROJECT_DEV --target DEV
```

## Demo Script (Talk Track)

### Scenario 1 — Initial Deployment (nonbreaking)

**Story**: FBL Financial is launching a new policy data platform. We version
everything in Git and deploy the same release tag through DEV, then TEST.

1. Show `manifest.yml` — two targets, one codebase, Jinja `{{env}}` templating
2. Show `sources/definitions/raw.sql` — DEFINE TABLE, CHANGE_TRACKING
3. Show `sources/definitions/serve.sql` — versioned consumer view POLICY_V1
4. Show `contracts/policy_v1.yml` — the published column contract
5. Show `sources/definitions/expectations.sql` — data quality as code
6. Tag `v1.0.0`, push → GitHub Actions deploys to DEV automatically
7. In GitHub: show the release workflow, the plan summary in the logs
8. In Snowflake: query `FBL_POLICY_DEV.SERVE.POLICY_V1` as POLICY_ANALYST
9. Approve the TEST environment → same tag deploys to TEST
10. Query `FBL_POLICY_TEST.RAW.RELEASE_LOG` — traceability

### Scenario 2 — Nonbreaking Change (add a column)

**Story**: Business wants to track beneficiary count. This is additive — no
contract violation.

1. Branch: `feature/add-beneficiary-count`
2. Add `BENEFICIARY_COUNT NUMBER DEFAULT 1` to POLICY table in `raw.sql`
3. Add the column to the view in `serve.sql`
4. Update `contracts/policy_v1.yml` with the new column
5. Open PR → `pr.yml` runs plan + `check_breaking.py`
6. Show the PR comment: "✅ No breaking changes"
7. Merge → tag `v1.1.0` → auto-deploy to DEV, approve for TEST

### Scenario 3 — Breaking Change (drop a column)

**Story**: Legal says we must remove POLICYHOLDER_NAME from the SERVE view
for GDPR compliance. This breaks the contract.

1. Branch: `feature/remove-pii`
2. Remove POLICYHOLDER_NAME from `serve.sql` and `contracts/policy_v1.yml`
3. Open PR (without the `breaking-change` label)
4. `pr.yml` runs → `check_breaking.py` exits 1 → PR check FAILS
5. Show the PR comment: "🚨 Column DROP POLICYHOLDER_NAME on POLICY_V1"
6. Add label `breaking-change` → re-run → check passes with warning
7. Discuss: notification to POLICY_ANALYST / CLAIMS_APP before merge
8. Merge → tag `v2.0.0` (major version bump signals breaking change)

### Scenario 4 — Deprecation & Backward Compatibility

**Story**: Instead of breaking POLICY_V1, we create POLICY_V2 without PII
and deprecate V1 with a sunset date.

1. Branch: `feature/policy-v2`
2. Keep POLICY_V1 unchanged (backward compatible)
3. Add POLICY_V2 in `serve.sql` without POLICYHOLDER_NAME
4. Add `contracts/policy_v2.yml`
5. Add a COMMENT on V1: "DEPRECATED — sunset 2027-03-01. Use POLICY_V2."
6. PR → check passes (no contract violation on V1)
7. Tag `v1.2.0` (minor version — additive)
8. Consumers migrate at their own pace; V1 removed in a future major release

## GitHub Setup

### Prerequisites

1. Create a GitHub repo and push this directory
2. Set up Snowflake auth — see `docs/oidc_setup.sql` (or use key-pair secrets)
3. Create GitHub environments:
   - `dev` — no protection rules
   - `test` — add a Required Reviewer for the approval gate

### Required Secrets (key-pair auth path)

| Secret | Value |
|--------|-------|
| `SNOWFLAKE_ACCOUNT` | `ZKB94920` |
| `SNOWFLAKE_USER` | `GITHUB_ACTIONS_SVC` |
| `SNOWFLAKE_PRIVATE_KEY` | Contents of `rsa_key.p8` |

### Labels

Create a PR label named `breaking-change` (the workflows check for it).

## File Reference

| File | Purpose |
|------|---------|
| `manifest.yml` | DCM project manifest (targets, templating) |
| `sources/definitions/raw.sql` | Database, schemas, POLICY table, RELEASE_LOG |
| `sources/definitions/serve.sql` | Consumer view POLICY_V1 |
| `sources/definitions/access.sql` | Grants to POLICY_ANALYST and CLAIMS_APP |
| `sources/definitions/expectations.sql` | DMF expectations (null count, duplicate count) |
| `post_deploy.sql` | Seed data + release log entry |
| `contracts/policy_v1.yml` | Published column contract |
| `scripts/check_breaking.py` | Breaking-change detector |
| `docs/oidc_setup.sql` | Snowflake OIDC setup for GitHub Actions |

test


