export const API_BASE = (import.meta.env.VITE_API_BASE || '/api').replace(/\/+$/, '');

function authHeaders() {
  const session = storage.getSession();
  const headers = { 'Content-Type': 'application/json' };
  if (session?.token) headers.Authorization = `Bearer ${session.token}`;
  return headers;
}

async function request(path, options = {}, auth = false) {
  const url = `${API_BASE}${path}`;
  let res;
  try {
    res = await fetch(url, {
      headers: { ...(auth ? authHeaders() : { 'Content-Type': 'application/json' }), ...(options.headers || {}) },
      ...options,
    });
  } catch {
    const networkError = new Error('عذراً، لم نتمكن من الاتصال بالخادم. تأكد من اتصال الإنترنت وحاول مجدداً.');
    networkError.code = 'NETWORK_ERROR';
    networkError.retryable = true;
    throw networkError;
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const error = new Error(data.message || 'حدث خطأ');
    error.status = res.status;
    error.code = data.code;
    error.retryable = res.status >= 500 || res.status === 429;
    throw error;
  }
  return data;
}

export const api = {
  registerUser: (body) => request('/register-user', { method: 'POST', body: JSON.stringify(body) }),
  registerOwner: (body) => request('/register-owner', { method: 'POST', body: JSON.stringify(body) }),
  login: (email, password) => request('/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  getStadiums: () => request('/fields'),
  getSchedule: (id) => request(`/fields/${id}/schedule`),
  createBooking: (body) =>
    request('/bookings', { method: 'POST', body: JSON.stringify({ fieldId: body.fieldId ?? body.stadiumId, startTime: body.startTime, hours: body.hours }) }, true),
  getUserBookings: (userId) => request(`/bookings/user/${userId}`, {}, true),
  cancelBooking: (bookingId) =>
    request('/bookings/cancel', { method: 'POST', body: JSON.stringify({ bookingId }) }, true),
  getOwnerDashboard: (ownerId) => request(`/bookings/owner/${ownerId}?page=1&limit=50`, {}, true),
  approveBooking: (bookingId) =>
    request('/bookings/approve', { method: 'POST', body: JSON.stringify({ bookingId }) }, true),
  rejectBooking: (bookingId) =>
    request('/bookings/reject', { method: 'POST', body: JSON.stringify({ bookingId }) }, true),
  getNotifications: (userId) => request(`/notifications/${userId}`, {}, true),
};

export const storage = {
  saveSession: (session) => localStorage.setItem('riyada_session', JSON.stringify(session)),
  getSession: () => {
    try {
      const raw = localStorage.getItem('riyada_session');
      return raw ? JSON.parse(raw) : null;
    } catch {
      localStorage.removeItem('riyada_session');
      return null;
    }
  },
  clearSession: () => localStorage.removeItem('riyada_session'),
};

export function formatDateTime(dt) {
  return new Date(dt).toLocaleString('ar-IQ', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

export function formatDate(dt) {
  return new Date(dt).toLocaleDateString('ar-IQ', {
    weekday: 'long', day: 'numeric', month: 'long',
  });
}

export function formatTime(dt) {
  return new Date(dt).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' });
}

export function formatRemaining(hours) {
  if (hours <= 0) return 'انتهى الحجز';
  if (hours < 1) return `${Math.round(hours * 60)} دقيقة متبقية`;
  if (hours < 24) return `${Math.round(hours)} ساعة متبقية`;
  const days = Math.floor(hours / 24);
  const rem = Math.round(hours % 24);
  return `${days} يوم و ${rem} ساعة متبقية`;
}

export function formatMoney(amount) {
  return `${Number(amount).toLocaleString('ar-IQ')} د.ع`;
}
