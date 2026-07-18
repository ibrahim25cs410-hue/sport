# Production release checklist

## One-time external setup

- Protect `main`/`master`: require the **CI** workflow and at least one review.
- Connect the Render Blueprint and verify **Auto Deploy = After CI Checks Pass**.
- Set GitHub variable `PRODUCTION_ORIGIN` to the HTTPS service origin and
  `PRODUCTION_API_BASE_URL` to the URL ending in `/api`.
- Configure the four Android secrets only in GitHub Actions:
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,
  and `ANDROID_STORE_PASSWORD`, plus `MOBILE_PRODUCTION_DEFINES_BASE64` containing
  the reviewed Firebase/API/Sentry production define JSON. Keep the original keystore in a separate,
  access-controlled vault; losing it can prevent app updates.
- Enable GitHub code scanning and dependency graph so SARIF uploads and
  dependency review are accepted.

## Render environment

Set values in Render, never in Git:

- `MONGODB_URI`: Atlas least-privilege application user, TLS enabled.
- `JWT_SECRET`: random 32 bytes or more; rotate through a planned logout window.
- `ALLOWED_ORIGINS`: exact HTTPS browser origins, comma-separated.
- `ADMIN_EMAIL` and `ADMIN_PASSWORD`: initial bootstrap only. Remove the password
  after the account exists and verify the account is protected.
- `ADMIN_BOOTSTRAP_SECRET`: leave unset except during a controlled bootstrap;
  remove immediately afterward.
- `ELECTRONIC_PAYMENTS_ENABLED=false`: mandatory for the cash-only launch.
- `SENTRY_DSN`: enables the backend integration after a successful verification
  event. Mobile Sentry values are supplied separately at build time.
- `RESEND_API_KEY`, `EMAIL_FROM`, and `ADMIN_INVITE_BASE_URL`: required
  together for admin invitation delivery; verify the sender/domain first.
- Firebase service-account material, if used, belongs in Render's secret store.

Render's `free` plan in `render.yaml` can cold-start and has limited production
assurances. Select a paid plan, minimum instances, and region in the Render
dashboard after cost/availability approval; do not silently change billing via Git.

## Before every release

1. Confirm CI passes for root backend, admin web, customer web, Flutter, release
   configuration, audits, and repository security scan.
2. Review `npm audit` exceptions; do not suppress high/critical findings without
   an owner, expiry date, and risk note.
3. Run `node scripts/ops/validate-release-config.mjs`.
4. Verify a successful encrypted MongoDB backup and its checksum from the last
   24 hours. Confirm the latest quarterly restore drill passed.
5. Confirm Atlas has sufficient storage, no sustained connection saturation, and
   no active security alerts.
6. Confirm `GET /api/health` reports `env=production`, `storage=mongodb`, and
   `paymentMode=cash_only`; confirm `GET /api/ready` reports `ready=true` with no
   missing indexes.
7. Record release owner, commit SHA, Render deploy ID, and rollback deploy ID.

## Deploy and verify

Render deploys only after required GitHub checks pass. The GitHub
`Post-deploy smoke` workflow runs when a provider creates a successful GitHub
deployment status; otherwise dispatch it manually with the Render service URL:

```bash
node scripts/ops/post-deploy-smoke.mjs https://sports-x7v7.onrender.com
```

The smoke is read-only: it checks HTTPS health/readiness, MongoDB indexes, production
mode, cash-only mode, the public fields collection, `/panel/`, and `/app/`. Then
manually verify admin login, one existing field, and Socket.io connectivity without
creating a real booking.

## Android release

Run **Signed Android release** manually or push a reviewed `v*` tag. It fails unless
all signing secrets and validated Firebase production defines exist, never falls
back to debug signing, and uploads the AAB (30 days) plus obfuscation symbols
(90 days). Download symbols into the release archive and upload them to Sentry for
the matching release.

## Rollback decision

- Application regression with healthy data: use Render **Rollback** to the recorded
  previous successful deploy, then rerun post-deploy smoke.
- Bad configuration: restore the previous Render environment value and redeploy.
- Suspected data corruption: stop writes/escalate first. Do not run a database
  restore until the incident commander and database owner approve the recovery
  point and scope. Follow `BACKUP_RESTORE.md`.
