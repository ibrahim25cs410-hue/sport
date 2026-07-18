const SESSION_KEY = 'riyada_admin_session';

export const API_BASE = (import.meta.env.VITE_API_BASE || '/api').replace(/\/+$/, '');

export function formatMoney(value, locale = 'ar') {
  const n = Number(value) || 0;
  const tag = locale === 'en' ? 'en-IQ' : 'ar-IQ';
  const suffix = locale === 'en' ? 'IQD' : 'د.ع';
  return `${n.toLocaleString(tag)} ${suffix}`;
}

export function formatDate(value, locale = 'ar') {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return String(value);
  const tag = locale === 'en' ? 'en-GB' : 'ar-IQ';
  return d.toLocaleString(tag, {
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

function queryString(params = {}) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '' && value !== 'all') q.set(key, value);
  });
  const value = q.toString();
  return value ? `?${value}` : '';
}

async function request(path, { method = 'GET', body, auth = true, signal } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth) {
    const session = getSession();
    if (session?.token) headers.Authorization = `Bearer ${session.token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body != null ? JSON.stringify(body) : undefined,
    signal,
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status === 401 && auth) {
      clearSession();
      window.dispatchEvent(new CustomEvent('riyada:unauthorized'));
    }
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
  acceptInvitation: (token, password) =>
    request('/admin/invitations/accept', {
      method: 'POST',
      auth: false,
      body: { token, password },
    }),
  me: () => request('/me'),
  stats: () => request('/admin/stats'),
  financials: () => request('/admin/financials'),
  users: (params = {}) => request(`/admin/users${queryString(params)}`),
  user: (id) => request(`/admin/users/${id}`),
  owners: () => request('/admin/owners'),
  owner: (id) => request(`/admin/owners/${id}`),
  ownerWallet: (id) => request(`/admin/owners/${id}/wallet`),
  setWalletStatus: (id, status) =>
    request(`/admin/owners/${id}/wallet-status`, { method: 'PATCH', body: { status } }),
  fields: () => request('/admin/fields'),
  toggleField: (id) => request(`/admin/fields/${id}/toggle`, { method: 'PATCH' }),
  updateField: (id, body) => request(`/fields/${id}`, { method: 'PUT', body }),
  bookings: (params = {}) => request(`/admin/bookings${queryString({ limit: 50, ...params })}`),
  pendingBookings: () => request('/admin/bookings/pending'),
  approveBooking: (bookingId) => request('/bookings/approve', { method: 'POST', body: { bookingId } }),
  rejectBooking: (bookingId) => request('/bookings/reject', { method: 'POST', body: { bookingId } }),
  cancelBooking: (bookingId) => request('/bookings/cancel', { method: 'POST', body: { bookingId } }),
  confirmCashPayment: (bookingId) =>
    request('/bookings/pay/verify', { method: 'POST', body: { bookingId } }),
  topUp: (ownerId, amount, note) =>
    request('/admin/wallets/top-up', { method: 'POST', body: { ownerId, amount, note } }),
  dashboardAnalytics: (params) => request(`/admin/analytics/dashboard${queryString(params)}`),
  permissions: () => request('/admin/permissions'),
  preferences: () => request('/admin/preferences'),
  updatePreferences: (body) => request('/admin/preferences', { method: 'PUT', body }),
  calendar: (params) => request(`/admin/calendar${queryString(params)}`),
  alerts: (params) => request(`/admin/alerts${queryString(params)}`),
  markAlertRead: (id) => request(`/admin/alerts/${id}/read`, { method: 'PATCH' }),
  markAllAlertsRead: () => request('/admin/alerts/read-all', { method: 'PATCH' }),
  updateAlert: (id, body) => request(`/admin/alerts/${id}`, { method: 'PATCH', body }),
  reports: (params) => request(`/admin/reports${queryString(params)}`),
  exportReport: (body) => request('/admin/reports/exports', { method: 'POST', body }),
  settlements: (params) => request(`/admin/settlements${queryString(params)}`),
  settlement: (id) => request(`/admin/settlements/${id}`),
  createSettlement: (body) => request('/admin/settlements', { method: 'POST', body }),
  updateSettlement: (id, body) => request(`/admin/settlements/${id}`, { method: 'PATCH', body }),
  staff: (params) => request(`/admin/staff${queryString(params)}`),
  inviteStaff: (body) => request('/admin/staff/invitations', { method: 'POST', body }),
  updateStaff: (id, body) => request(`/admin/staff/${id}`, { method: 'PATCH', body }),
  roles: () => request('/admin/roles'),
  createRole: (body) => request('/admin/roles', { method: 'POST', body }),
  updateRole: (id, body) => request(`/admin/roles/${id}`, { method: 'PUT', body }),
  auditLog: (params) => request(`/admin/audit-logs${queryString(params)}`),
  globalSearch: (q) => request(`/admin/search${queryString({ q })}`),
  booking: (id) => request(`/admin/bookings/${id}`),
  createBooking: (body) => request('/admin/bookings', { method: 'POST', body }),
  updateBooking: (id, body) => request(`/admin/bookings/${id}`, { method: 'PATCH', body }),
  rescheduleBooking: (id, body) => request(`/admin/bookings/${id}/reschedule`, { method: 'POST', body }),
  bulkBookings: (bookingIds, action) => request('/admin/bookings/bulk', { method: 'POST', body: { bookingIds, action } }),
  maintenance: (params) => request(`/admin/maintenance-blocks${queryString(params)}`),
  createMaintenance: (body) => request('/admin/maintenance-blocks', { method: 'POST', body }),
  updateMaintenance: (id, body) => request(`/admin/maintenance-blocks/${id}`, { method: 'PATCH', body }),
  deleteMaintenance: (id) => request(`/admin/maintenance-blocks/${id}`, { method: 'DELETE' }),
  realtimeToken: () => request('/admin/realtime/token'),
};
