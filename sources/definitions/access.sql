-- =============================================================
-- access.sql — Consumer grants on SERVE views
-- =============================================================

-- Consumer roles need database + schema usage before SELECT
GRANT USAGE ON DATABASE FBL_POLICY_{{env}} TO ROLE POLICY_ANALYST;
GRANT USAGE ON DATABASE FBL_POLICY_{{env}} TO ROLE CLAIMS_APP;

GRANT USAGE ON SCHEMA FBL_POLICY_{{env}}.SERVE TO ROLE POLICY_ANALYST;
GRANT USAGE ON SCHEMA FBL_POLICY_{{env}}.SERVE TO ROLE CLAIMS_APP;

-- SELECT on the versioned consumer view
GRANT SELECT ON VIEW FBL_POLICY_{{env}}.SERVE.POLICY_V1 TO ROLE POLICY_ANALYST;
GRANT SELECT ON VIEW FBL_POLICY_{{env}}.SERVE.POLICY_V1 TO ROLE CLAIMS_APP;
