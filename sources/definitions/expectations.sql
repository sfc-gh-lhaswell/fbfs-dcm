-- =============================================================
-- expectations.sql — Data quality contracts (DMF expectations)
-- =============================================================

-- Contract: POLICY_ID must never be NULL
ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE FBL_POLICY_{{env}}.RAW.POLICY
    ON (POLICY_ID)
    EXPECTATION NO_NULL_POLICY_ID (value = 0);

-- Contract: POLICY_ID must be unique (no duplicates)
ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
    TO TABLE FBL_POLICY_{{env}}.RAW.POLICY
    ON (POLICY_ID)
    EXPECTATION NO_DUPLICATE_POLICY_ID (value = 0);
