/**
 * Repository Pattern — كل عمليات API تمر عبر هذه الطبقة.
 * الشاشات والمكوّنات لا تستدعي fetch مباشرة.
 */
import { smartApi, clearSmartCache } from '../lib/smartApi';
import { api } from '../api';

export const riyadaRepository = {
  // Auth
  login: (email, password) => smartApi.login(email, password),
  registerUser: (body) => smartApi.registerUser(body),
  registerOwner: (body) => smartApi.registerOwner(body),

  // Fields & schedule
  getFields: (page = 1, limit = 20) => smartApi.getStadiums(page, limit),
  invalidateFields: () => clearSmartCache('/stadiums'),
  getSchedule: (fieldId) => smartApi.getSchedule(fieldId),

  // Bookings
  getUserBookings: (userId) => smartApi.getUserBookings(userId),
  getBookingHistory: (userId) => smartApi.getBookingHistory(userId),
  getReviewEligibility: (fieldId) => smartApi.getReviewEligibility(fieldId),
  submitReview: (fieldId, body) => smartApi.submitReview(fieldId, body),
  getOwnerDashboard: (ownerId) => api.getOwnerDashboard(ownerId),
  createBooking: (body) => smartApi.createBooking(body),
  cancelBooking: (bookingId) => smartApi.cancelBooking(bookingId),
  approveBooking: (bookingId) => api.approveBooking(bookingId),
  rejectBooking: (bookingId) => api.rejectBooking(bookingId),

  // Slots
  selectSlot: (body) => smartApi.selectSlot(body),
  releaseSlot: (body) => smartApi.releaseSlot(body),

  // Notifications
  getNotifications: (userId) => smartApi.getNotifications(userId),
  markNotificationRead: (id) => smartApi.markNotificationRead(id),
  markAllNotificationsRead: (userId) => smartApi.markAllNotificationsRead(userId),

  invalidateBookings: () => clearSmartCache('/bookings/user'),
  invalidateNotifications: () => clearSmartCache('/notifications'),
  invalidateSchedule: (fieldId) => clearSmartCache(`/stadiums/${fieldId}/schedule`),
  getUserStats: (userId) => smartApi.getUserStats(userId),

  // Admin
  getAdminStats: () => smartApi.adminGet('/admin/stats'),
  getAdminFinancials: () => smartApi.adminGet('/admin/financials'),
  getAdminOwners: () => smartApi.adminGet('/admin/owners'),
  getAdminFields: () => smartApi.adminGet('/admin/fields'),
  getAdminPendingBookings: () => smartApi.adminGet('/admin/bookings/pending'),
  toggleAdminField: (id) => smartApi.adminPatch(`/admin/fields/${id}/toggle`),
  adminTopUp: (ownerId, amount, note) =>
    smartApi.adminPost('/admin/wallets/top-up', { ownerId, amount, note }),
};
