export const queryKeys = {
  fields: ['fields'],
  bookings: (userId) => ['bookings', userId],
  bookingHistory: (userId) => ['bookingHistory', userId],
  notifications: (userId) => ['notifications', userId],
  schedule: (fieldId) => ['schedule', fieldId],
  ownerDashboard: (ownerId) => ['ownerDashboard', ownerId],
};
