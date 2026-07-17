const SESSION_KEY = 'riyada_admin_session';

export const API_BASE = (import.meta.env.VITE_API_BASE || '/api').replace(/\/+$/, '');

export function formatMoney(value) {
  const n = Number(value) || 0;
  return `${n.toLocaleString('ar-IQ')} د.ع`;
}

export function formatDate(value) {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return String(value);
  return d.toLocaleString('ar-IQ', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

export function getSession() {
  try {
    return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null');
  } catch {
    return null;
  }
}

export function setSession(session) {
  localStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

export function clearSession() {
  localStorage.removeItem(SESSION_KEY);
}

export class ApiError extends Error {
  constructor(message, status, data) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth) {
    const session = getSession();
    if (session?.token) headers.Authorization = `Bearer ${session.token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body != null ? JSON.stringify(body) : undefined,
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new ApiError(data.message || 'فشل الطلب', res.status, data);
  }
  return data;
}

export const api = {
  login: (email, password) =>
    request('/login', {
      method: 'POST',
      auth: false,
      body: { email, password, expectedRole: 'admin' },
    }),
  me: () => request('/me'),
  stats: () => request('/admin/stats'),
  financials: () => request('/admin/financials'),
  users: (params = {}) => {
    const q = new URLSearchParams();
    if (params.role) q.set('role', params.role);
    if (params.q) q.set('q', params.q);
    if (params.page) q.set('page', params.page);
    if (params.limit) q.set('limit', params.limit);
    const s = q.toString();
    return request(`/admin/users${s ? `?${s}` : ''}`);
  },
  user: (id) => request(`/admin/users/${id}`),
  owners: () => request('/admin/owners'),
  owner: (id) => request(`/admin/owners/${id}`),
  ownerWallet: (id) => request(`/admin/owners/${id}/wallet`),
  setWalletStatus: (id, status) =>
    request(`/admin/owners/${id}/wallet-status`, { method: 'PATCH', body: { status } }),
  fields: () => request('/admin/fields'),
  toggleField: (id) => request(`/admin/fields/${id}/toggle`, { method: 'PATCH' }),
  updateField: (id, body) => request(`/fields/${id}`, { method: 'PUT', body }),
  bookings: (params = {}) => {
    const q = new URLSearchParams();
    if (params.status) q.set('status', params.status);
    if (params.q) q.set('q', params.q);
    if (params.page) q.set('page', params.page);
    if (params.limit) q.set('limit', params.limit || 50);
    const s = q.toString();
    return request(`/admin/bookings${s ? `?${s}` : ''}`);
  },
  pendingBookings: () => request('/admin/bookings/pending'),
  approveBooking: (bookingId) => request('/bookings/approve', { method: 'POST', body: { bookingId } }),
  rejectBooking: (bookingId) => request('/bookings/reject', { method: 'POST', body: { bookingId } }),
  cancelBooking: (bookingId) => request('/bookings/cancel', { method: 'POST', body: { bookingId } }),
  confirmCashPayment: (bookingId) =>
    request('/bookings/pay/verify', { method: 'POST', body: { bookingId } }),
  topUp: (ownerId, amount, note) =>
    request('/admin/wallets/top-up', { method: 'POST', body: { ownerId, amount, note } }),
};
