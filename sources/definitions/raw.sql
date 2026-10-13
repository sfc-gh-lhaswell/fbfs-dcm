-- =============================================================
-- raw.sql — Database, schemas, and source table for FBL Policy
-- =============================================================

DEFINE DATABASE FBL_POLICY_{{env}}
    COMMENT = '{{env}} environment — FBL life insurance policy data';

DEFINE SCHEMA FBL_POLICY_{{env}}.RAW
    COMMENT = 'Landing zone for policy source data';

DEFINE SCHEMA FBL_POLICY_{{env}}.SERVE
    COMMENT = 'Consumer-facing views and data products';

DEFINE TABLE FBL_POLICY_{{env}}.RAW.POLICY (
    POLICY_ID        NUMBER       NOT NULL,
    POLICYHOLDER_NAME VARCHAR(200) NOT NULL,
    PRODUCT_TYPE     VARCHAR(50)  NOT NULL,
    ISSUE_DATE       DATE         NOT NULL,
    PREMIUM_AMT      NUMBER(12,2) NOT NULL,
    STATUS           VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE'
)
CHANGE_TRACKING = TRUE
DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES'
COMMENT = 'Life insurance policies — source of truth';

-- Release log table for deployment traceability
DEFINE TABLE FBL_POLICY_{{env}}.RAW.RELEASE_LOG (
    VERSION     VARCHAR(50)  NOT NULL,
    ENV         VARCHAR(10)  NOT NULL,
    GIT_SHA     VARCHAR(40),
    DEPLOYED_BY VARCHAR(100),
    DEPLOYED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Deployment history — one row per release';
