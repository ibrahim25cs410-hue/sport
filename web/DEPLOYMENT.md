# Customer web deployment

The production build uses the `/app/` asset base and hash-based routes. Hash routing is intentional: the existing root Express static middleware can serve `public/app/index.html` without requiring a new server-side SPA fallback.

- Build locally: `npm run build`
- Produce the root-server artifact: `npm run build:deploy`
- Public URL: `/app/` (routes appear as `/app/#/home`, `/app/#/login`, and so on)
- API requests use same-origin `/api` unless `VITE_API_BASE` is explicitly set.
- The admin panel remains unchanged at `/panel/`.

Set `VITE_SENTRY_DSN` only when telemetry is desired. `VITE_SENTRY_TRACES_SAMPLE_RATE` defaults to `0`, and error events redact common personal/authentication fields.
