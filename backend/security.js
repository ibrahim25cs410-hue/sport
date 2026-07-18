const crypto = require('crypto');

const REDACTED = '[REDACTED]';
const SENSITIVE_KEYS = /^(authorization|cookie|password|token|secret|fcmToken|transactionToken|resendApiKey)$/i;

function redact(value, depth = 0) {
  if (depth > 5) return '[TRUNCATED]';
  if (Array.isArray(value)) return value.slice(0, 50).map((item) => redact(item, depth + 1));
  if (!value || typeof value !== 'object') return value;
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [
    key,
    SENSITIVE_KEYS.test(key) ? REDACTED : redact(item, depth + 1),
  ]));
}

function requestContext(logger = console) {
  return (req, res, next) => {
    const supplied = String(req.headers['x-request-id'] || '');
    req.id = /^[A-Za-z0-9._:-]{8,128}$/.test(supplied) ? supplied : crypto.randomUUID();
    res.setHeader('X-Request-Id', req.id);
    const started = Date.now();
    res.on('finish', () => {
      const entry = {
        level: res.statusCode >= 500 ? 'error' : 'info',
        event: 'http_request',
        requestId: req.id,
        method: req.method,
        path: req.originalUrl?.split('?')[0],
        statusCode: res.statusCode,
        durationMs: Date.now() - started,
        userId: req.user?.id || null,
        ip: req.ip,
      };
      (entry.level === 'error' ? logger.error : logger.log)(JSON.stringify(redact(entry)));
    });
    next();
  };
}

function allowedOrigin(origin, allowedOrigins, production) {
  if (!origin) return true; // native apps, curl, server-to-server clients
  if (!production) return allowedOrigins.length === 0 || allowedOrigins.includes('*')
    || allowedOrigins.includes(origin);
  return allowedOrigins.length > 0 && !allowedOrigins.includes('*') && allowedOrigins.includes(origin);
}

function cspConfig() {
  return {
    useDefaults: true,
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      fontSrc: ["'self'", 'data:'],
      connectSrc: ["'self'", 'https:', 'wss:'],
      objectSrc: ["'none'"],
      baseUri: ["'self'"],
      frameAncestors: ["'none'"],
      formAction: ["'self'"],
    },
  };
}

function initSentry({ dsn, environment }) {
  if (!dsn) return null;
  try {
    // Optional dependency: deployments without a DSN do not need the package.
    const Sentry = require('@sentry/node');
    Sentry.init({
      dsn,
      environment,
      sendDefaultPii: false,
      beforeSend(event) {
        const safe = redact(event);
        if (safe.request) {
          delete safe.request.cookies;
          delete safe.request.data;
          safe.request.headers = redact(safe.request.headers || {});
        }
        return safe;
      },
    });
    return Sentry;
  } catch (error) {
    console.warn(JSON.stringify({ level: 'warn', event: 'sentry_init_failed', message: error.message }));
    return null;
  }
}

module.exports = { allowedOrigin, cspConfig, initSentry, redact, requestContext };
