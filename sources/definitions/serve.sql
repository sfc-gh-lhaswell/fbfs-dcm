-- =============================================================
-- serve.sql — Consumer views (versioned data contracts)
-- =============================================================

DEFINE VIEW FBL_POLICY_{{env}}.SERVE.POLICY_V1
AS
SELECT
    POLICY_ID,
    POLICYHOLDER_NAME,
    PRODUCT_TYPE,
    ISSUE_DATE,
    PREMIUM_AMT,
    STATUS
FROM FBL_POLICY_{{env}}.RAW.POLICY;
