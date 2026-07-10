const API_PORT = import.meta.env.VITE_API_PORT || '3000';
const API_HOST = import.meta.env.VITE_API_HOST || 'localhost';
export const API_BASE = import.meta.env.VITE_API_BASE || `http://${API_HOST}:${API_PORT}/api`;

function authHeaders() {
  const session = storage.getSession();
  const headers = { 'Content-Type': 'application/json' };
  if (session?.token) headers.Authorization = `Bearer ${session.token}`;
  return headers;
}

async function request(path, options = {}, auth = false) {
  const url = `${API_BASE}${path}`;
  console.log('[Riyada API] →', options.method || 'GET', url);
  if (options.body) {
    try {
      const preview = JSON.parse(options.body);
      if (preview.password) preview.password = '***';
      console.log('[Riyada API]   body:', preview);
    } catch {
      console.log('[Riyada API]   body:', options.body);
    }
  }

  let res;
  try {
    res = await fetch(url, {
      headers: { ...(auth ? authHeaders() : { 'Content-Type': 'application/json' }), ...(options.headers || {}) },
      ...options,
    });
  } catch (err) {
    console.error('[Riyada API] ❌ Network error:', err);
    console.error('[Riyada API]   تحقق أن الخادم يعمل على', API_BASE);
    throw new Error('عذراً، لم نتمكن من الاتصال بالخادم. تأكد من اتصال الإنترنت وحاول مجدداً.');
  }

  const data = await res.json().catch(() => ({}));
  console.log('[Riyada API] ←', res.status, url, data);

  if (!res.ok) {
    console.error('[Riyada API] ❌ Server error:', res.status, data);
    throw new Error(data.message || 'حدث خطأ');
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
    const raw = localStorage.getItem('riyada_session');
    return raw ? JSON.parse(raw) : null;
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
