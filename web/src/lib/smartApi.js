/**
 * طبقة API ذكية — Fast Mode
 * - تخزين مؤقت في الذاكرة (stale-while-revalidate)
 * - رسائل خطأ ودودة للمستخدم
 * - قياس Latency في وضع التطوير
 */
import { API_BASE, storage } from '../api';
import { unwrapPagedList } from './pagedResponse';

const pageQs = (page = 1, limit = 50) => `?page=${page}&limit=${limit}`;

const memoryCache = new Map();
const DEFAULT_TTL_MS = 30_000;

const FRIENDLY = {
  network: 'تعذّر الاتصال بالخادم. تحقق من الإنترنت أو شغّل API ثم أعد المحاولة.',
  timeout: 'استغرق الخادم وقتاً طويلاً. جرّب مرة أخرى خلال ثوانٍ.',
  400: 'البيانات المدخلة غير صحيحة.',
  401: 'انتهت الجلسة أو بيانات الدخول غير صحيحة.',
  403: 'ليس لديك صلاحية لهذا الإجراء.',
  404: 'المورد المطلوب غير موجود.',
  409: 'تعارض — ربما البريد أو الحجز مستخدم مسبقاً.',
  500: 'خطأ مؤقت في الخادم. نعيد المحاولة تلقائياً…',
};

export class SmartApiError extends Error {
  constructor(message, { code, status, retryable, raw } = {}) {
    super(message);
    this.name = 'SmartApiError';
    this.code = code;
    this.status = status;
    this.retryable = retryable ?? false;
    this.raw = raw;
  }
}

function authHeaders() {
  const session = storage.getSession();
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
  if (session?.token) headers.Authorization = `Bearer ${session.token}`;
  return headers;
}

function cacheKey(method, path, body) {
  return `${method}:${path}:${body ?? ''}`;
}

export function clearSmartCache(prefix = '') {
  if (!prefix) {
    memoryCache.clear();
    return;
  }
  for (const k of memoryCache.keys()) {
    if (k.includes(prefix)) memoryCache.delete(k);
  }
}

/**
 * @param {string} path - مثل /stadiums
 * @param {object} options
 * @param {boolean} options.auth
 * @param {number} options.ttlMs - Fast Mode cache (0 = بدون cache)
 * @param {number} options.retries
 */
export async function smartFetch(path, options = {}) {
  const {
    method = 'GET',
    body,
    auth = false,
    ttlMs = method === 'GET' ? DEFAULT_TTL_MS : 0,
    retries = method === 'GET' ? 2 : 0,
  } = options;

  const url = `${API_BASE}${path}`;
  const key = cacheKey(method, path, body);

  if (ttlMs > 0 && method === 'GET') {
    const hit = memoryCache.get(key);
    if (hit && Date.now() - hit.ts < ttlMs) {
      if (import.meta.env.DEV) console.log('[FastMode] cache hit', path);
      return hit.data;
    }
  }

  let lastError;
  for (let attempt = 0; attempt <= retries; attempt++) {
    const started = performance.now();
    try {
      if (import.meta.env.DEV) {
        console.log(`[Riyada API] → ${method} ${url}`, attempt > 0 ? `(retry ${attempt})` : '');
      }

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15_000);

      const res = await fetch(url, {
        method,
        headers: { ...(auth ? authHeaders() : { 'Content-Type': 'application/json' }), ...options.headers },
        body: body != null ? JSON.stringify(body) : undefined,
        signal: controller.signal,
      });
      clearTimeout(timeout);

      const data = await res.json().catch(() => ({}));
      const ms = Math.round(performance.now() - started);
      if (import.meta.env.DEV) console.log(`[Riyada API] ← ${res.status} ${ms}ms`, data);

      if (!res.ok) {
        throw new SmartApiError(data.message || FRIENDLY[res.status] || 'حدث خطأ', {
          status: res.status,
          code: data.code,
          retryable: res.status >= 500,
          raw: data,
        });
      }

      if (ttlMs > 0 && method === 'GET') {
        memoryCache.set(key, { data, ts: Date.now() });
      }
      return data;
    } catch (err) {
      lastError = err;
      if (err.name === 'AbortError') {
        lastError = new SmartApiError(FRIENDLY.timeout, { code: 'TIMEOUT', retryable: true });
      } else if (err instanceof TypeError) {
        lastError = new SmartApiError(FRIENDLY.network, { code: 'NETWORK', retryable: true });
      }
      if (!(lastError instanceof SmartApiError && lastError.retryable) || attempt === retries) break;
      await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
    }
  }

  if (import.meta.env.DEV) console.error('[Riyada API] ❌', lastError);
  throw lastError;
}

export const smartApi = {
  getStadiums: (page = 1, limit = 50) =>
    smartFetch(`/stadiums${pageQs(page, limit)}`, { ttlMs: 60_000 }).then(unwrapPagedList),
  getUserBookings: (userId, page = 1, limit = 50) =>
    smartFetch(`/bookings/user/${userId}${pageQs(page, limit)}`, { auth: true, ttlMs: 15_000 }).then(unwrapPagedList),
  getBookingHistory: (userId, page = 1, limit = 50) =>
    smartFetch(`/bookings/user/${userId}/history${pageQs(page, limit)}`, { auth: true, ttlMs: 15_000 }).then(unwrapPagedList),
  getNotifications: (userId, page = 1, limit = 30) =>
    smartFetch(`/notifications/${userId}${pageQs(page, limit)}`, { auth: true, ttlMs: 10_000 }).then(unwrapPagedList),
  getUserStats: (userId) => smartFetch(`/stats/user/${userId}`, { auth: true, ttlMs: 15_000 }),
  markNotificationRead: (id) =>
    smartFetch(`/notifications/${id}/read`, { method: 'POST', auth: true }).then((r) => {
      clearSmartCache('/notifications');
      return r;
    }),
  markAllNotificationsRead: (userId) =>
    smartFetch(`/notifications/user/${userId}/read-all`, { method: 'POST', auth: true }).then((r) => {
      clearSmartCache('/notifications');
      return r;
    }),
  selectSlot: (body) =>
    smartFetch('/slots/select', {
      method: 'POST',
      body: { fieldId: body.fieldId ?? body.stadiumId, startTime: body.startTime, hours: body.hours },
      auth: true,
    }),
  releaseSlot: (body) =>
    smartFetch('/slots/release', {
      method: 'POST',
      body: { fieldId: body.fieldId ?? body.stadiumId, startTime: body.startTime, hours: body.hours },
      auth: true,
    }),
  getSchedule: (id) => smartFetch(`/stadiums/${id}/schedule`, { ttlMs: 20_000 }),
  getReviewEligibility: (fieldId) => smartFetch(`/fields/${fieldId}/review-eligibility`, { auth: true }),
  submitReview: (fieldId, body) =>
    smartFetch(`/fields/${fieldId}/reviews`, { method: 'POST', body, auth: true }).then((r) => {
      clearSmartCache('/stadiums');
      clearSmartCache(`/stadiums/${fieldId}/schedule`);
      return r;
    }),
  cancelBooking: (bookingId) =>
    smartFetch('/bookings/cancel', { method: 'POST', body: { bookingId }, auth: true }).then((r) => {
      clearSmartCache('/bookings/user');
      return r;
    }),
  createBooking: (body) =>
    smartFetch('/bookings', {
      method: 'POST',
      body: { fieldId: body.fieldId ?? body.stadiumId, startTime: body.startTime, hours: body.hours },
      auth: true,
    }).then((r) => {
      clearSmartCache('/bookings/user');
      return r;
    }),
  registerUser: (body) => smartFetch('/register-user', { method: 'POST', body }),
  registerOwner: (body) => smartFetch('/register-owner', { method: 'POST', body }),
  login: (email, password) => smartFetch('/login', { method: 'POST', body: { email, password } }),
  adminGet: (path) => smartFetch(path, { auth: true, ttlMs: 10_000 }),
  adminPatch: (path) => smartFetch(path, { method: 'PATCH', auth: true }),
  adminPost: (path, body) => smartFetch(path, { method: 'POST', body, auth: true }),
};
