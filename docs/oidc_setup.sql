-- =============================================================
-- oidc_setup.sql — Snowflake-side OIDC / Workload Identity setup
--                   for GitHub Actions → Snowflake auth
--
-- Run this ONCE as ACCOUNTADMIN in your Snowflake account.
-- Then configure your GitHub repo (no secrets needed for OIDC).
-- =============================================================

-- 1. Create a security integration that trusts GitHub's OIDC provider
CREATE OR REPLACE SECURITY INTEGRATION github_actions_oidc
    TYPE = EXTERNAL_OAUTH
    ENABLED = TRUE
    EXTERNAL_OAUTH_TYPE = CUSTOM
    EXTERNAL_OAUTH_ISSUER = 'https://token.actions.githubusercontent.com'
    EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://token.actions.githubusercontent.com/.well-known/jwks'
    EXTERNAL_OAUTH_AUDIENCE_LIST = ('https://github.com/<YOUR_ORG>')  -- replace with your GitHub org URL
    EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'actor'
    EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME'
    EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE';

-- 2. Create a service user for GitHub Actions
CREATE USER IF NOT EXISTS GITHUB_ACTIONS_SVC
    LOGIN_NAME = 'github-actions'          -- must match the GitHub actor or sub claim
    DEFAULT_ROLE = DCM_DEV_DEPLOYER
    DEFAULT_WAREHOUSE = FBL_DEMO_WH
    COMMENT = 'Service user for GitHub Actions CI/CD'
    MUST_CHANGE_PASSWORD = FALSE
    TYPE = SERVICE;

-- 3. Grant deployer roles to the service user
GRANT ROLE DCM_DEV_DEPLOYER  TO USER GITHUB_ACTIONS_SVC;
GRANT ROLE DCM_TEST_DEPLOYER TO USER GITHUB_ACTIONS_SVC;

-- ============================================================
-- ALTERNATIVE: Key-pair authentication (simpler for demos)
-- ============================================================
-- If OIDC is too complex for the demo, use key-pair auth instead:
--
-- 1. Generate a key pair locally:
--    openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
--    openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
--
-- 2. Set the public key on the user:
--    ALTER USER GITHUB_ACTIONS_SVC SET RSA_PUBLIC_KEY='<contents of rsa_key.pub>';
--
-- 3. Store in GitHub repo secrets:
--    SNOWFLAKE_ACCOUNT   = ZKB94920
--    SNOWFLAKE_USER      = GITHUB_ACTIONS_SVC
--    SNOWFLAKE_PRIVATE_KEY = <contents of rsa_key.p8>
--
-- The workflows include both OIDC and key-pair auth paths.
