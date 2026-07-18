import * as Sentry from '@sentry/react';

const dsn = import.meta.env.VITE_SENTRY_DSN;

const redact = (value) => {
  if (!value || typeof value !== 'object') return value;
  const clone = structuredClone(value);
  const sensitive = /authorization|cookie|email|phone|password|token|name|address/i;
  const visit = (item) => {
    if (!item || typeof item !== 'object') return;
    Object.keys(item).forEach((key) => {
      if (sensitive.test(key)) item[key] = '[Redacted]';
      else visit(item[key]);
    });
  };
  visit(clone);
  return clone;
};

export function initMonitoring() {
  if (!dsn || import.meta.env.MODE === 'test') return false;
  Sentry.init({
    dsn,
    environment: import.meta.env.MODE,
    release: import.meta.env.VITE_APP_VERSION,
    sendDefaultPii: false,
    tracesSampleRate: Number(import.meta.env.VITE_SENTRY_TRACES_SAMPLE_RATE || 0),
    beforeSend(event) {
      const safe = redact(event);
      if (safe.request) {
        delete safe.request.cookies;
        delete safe.request.data;
        safe.request.headers = redact(safe.request.headers);
      }
      safe.user = safe.user?.id ? { id: String(safe.user.id) } : undefined;
      return safe;
    },
  });
  return true;
}

export function captureException(error, context = {}) {
  if (!dsn) return;
  Sentry.captureException(error, { extra: redact(context) });
}
