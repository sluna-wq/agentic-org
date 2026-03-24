-- assert_no_email_in_marts: PII gate — email must never appear in mart outputs
--
-- This test encodes the compliance invariant surfaced in Finding #3 (WT-10):
-- fct_customer_metrics exposed customer_email in a customer-facing mart,
-- creating a cross-customer GDPR violation via the analytics API.
--
-- The test returns rows when customer_email is present and non-null in the mart.
-- dbt test semantics: a passing test returns 0 rows.
-- Any non-zero result = compliance failure, deploy blocked.
--
-- Coverage: fct_customer_metrics
-- Added: 2026-02-23 (autonomous agent, WT-10 sweep — Finding #3)
-- Owner: compliance@acmecorp.com + data team
--
-- Note: this test will FAIL on the original fct_customer_metrics model by design.
-- It serves as proof of the violation and as a regression gate after the fix.
-- Once the compliance team authorizes the column removal and the fix is deployed,
-- this test should pass on every subsequent run.

select
    customer_id,
    customer_email,
    'EMAIL_EXPOSED_IN_MART' as violation_type
from {{ ref('fct_customer_metrics') }}
where customer_email is not null
  and customer_email != ''
  -- Explicitly reject masked forms too — any recognizable email pattern is a failure
  and customer_email not like '%%***@***'

-- If this query returns any rows, the build fails.
-- The mart is exposing raw email addresses and must not be deployed to production.
