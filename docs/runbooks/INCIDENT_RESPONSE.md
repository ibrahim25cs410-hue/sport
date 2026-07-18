# SLO, monitoring, and incident response

## Service objectives

Measure rolling 30-day windows, excluding pre-announced maintenance:

- API availability: 99.9% successful synthetic `GET /api/health` requests.
- API latency: 95% of health and representative read requests below 750 ms;
  99% below 2 seconds, measured from Iraq and a second region.
- Booking correctness: 99.99% of accepted booking mutations are durable and no
  confirmed double-booking caused by the platform.
- Backup: recovery point objective (RPO) 24 hours; recovery time objective (RTO)
  4 hours until a restore drill proves a tighter value.
- Email, once Resend is integrated: 99% accepted by Resend within 5 minutes.

Page on symptoms, not only provider status. A 5-minute availability burn above
14.4x or a 1-hour burn above 6x pages the on-call operator. A 6-hour burn above
1x creates a high-priority ticket. Freeze non-remediation releases after 50% of
the monthly error budget is consumed.

## Monitoring setup

Render:

- HTTPS synthetic check of `/api/health` every minute from two regions; assert
  status 200 and JSON values `status=ok`, `storage=mongodb`,
  `paymentMode=cash_only`, and `env=production`.
- Alert on deploy failure, restart loop, sustained 5xx, p95 latency, memory near
  plan limit, and instance unavailability. Send alerts to a channel independent
  of the application.
- Free-plan cold starts can violate these objectives; use an appropriate paid plan
  before treating the SLO as contractual.

MongoDB Atlas:

- Enable alerts for cluster unavailable, replication lag, connections above 80%,
  disk above 75%/forecast exhaustion, query targeting/slow queries, backup failure,
  and suspicious access. Require TLS, IP restrictions, MFA, and least privilege.
- Review performance advisor and audit/security alerts weekly.

Sentry:

- Backend, Flutter, customer web, and admin web initialize Sentry conditionally,
  disable default PII, and redact sensitive context. Web and mobile builds accept
  release/environment values; Android CI retains obfuscation symbols. Configure
  DSNs and release values outside Git, upload matching source maps/symbols, and send
  a verified test event for every surface before relying on Sentry.
- Alert on a new fatal issue, crash-free sessions below 99.5%,
  or error-rate regression after a deploy. Never send auth tokens, passwords,
  booking notes, phone numbers, or MongoDB URIs.

Resend:

- The backend sends admin invitations through Resend when `RESEND_API_KEY`,
  `EMAIL_FROM`, and `ADMIN_INVITE_BASE_URL` are all configured. Before
  enabling it, verify SPF, DKIM, DMARC, a dedicated sending domain, suppression
  handling, idempotency, and a non-production recipient allowlist.
- Monitor API errors, webhook failures, bounce/complaint rates, and domain status.
  A Resend outage must not make booking commits fail; queue/retry notifications.

## Severity and roles

- SEV-1: booking integrity/security event, broad outage, or confirmed data loss.
  Page immediately; incident commander, operations lead, communications lead.
- SEV-2: degraded booking/admin capability or sustained SLO breach. Respond in
  15 minutes.
- SEV-3: limited impact or non-urgent monitoring defect. Track during business hours.

The incident commander owns decisions and timeline. The operations lead gathers
evidence and executes approved mitigations. One person records timestamps,
commands, deploy IDs, and customer impact. Do not paste secrets into chat/tickets.

## Response procedure

1. Acknowledge, assign severity/roles, open an incident record, and state impact.
2. Check the synthetic payload, Render deploy/log/restart state, Atlas health and
   connections, recent GitHub checks, Sentry (when integrated), and Resend status.
3. Preserve evidence and compare the current deploy/config to the last known good.
4. Mitigate:
   - Bad deploy: Render rollback to the previous successful deploy.
   - Bad environment value: restore the previous value and redeploy.
   - Atlas saturation: stop abusive traffic, inspect slow operations, and scale
     only with authorization.
   - Resend outage: disable/drain notification sending, preserve queued work.
   - Data integrity concern: isolate writers; do not restore or drop data.
5. Run `node scripts/ops/post-deploy-smoke.mjs https://SERVICE` after mitigation.
6. Monitor for at least 30 minutes, reconcile delayed work, and communicate recovery.
7. Close only when metrics are stable, owner/customer impact is understood, and
   follow-up items have owners and dates.

For SEV-1/2, publish a blameless review within five business days covering
timeline, detection gap, root cause, contributing factors, error-budget impact,
recovery evidence, and concrete prevention work.
