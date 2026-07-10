const { publicNumericId, flutterStableId } = require('./fieldResolve');

const publicUser = (user) => ({
  id: Number(user.id) || flutterStableId({ name: user.email || user.name, phone: user.phone || '', address: '' }),
  name: user.name,
  email: user.email,
  phone: user.phone || '',
  province: user.province || 'نينوى',
  image: user.image || null,
  role: String(user.role || 'user').toLowerCase(),
  loyaltyPoints: Number(user.loyaltyPoints) || 0,
});

const publicField = (field) => ({
  id: publicNumericId(field),
  name: field.name,
  address: field.address || '',
  phone: field.phone || '',
  image: field.image || null,
  pricePerHour: Number(field.pricePerHour) || 0,
  ownerId: Number(field.ownerId) || 0,
  averageRating: Number(field.averageRating) || 0,
  reviewCount: Number(field.reviewCount) || 0,
  latitude: field.latitude ?? null,
  longitude: field.longitude ?? null,
});

const publicStadium = (stadium) => ({
  id: stadium.id,
  name: stadium.name,
  address: stadium.address || '',
  phone: stadium.phone || '',
  image: stadium.image || null,
  pricePerHour: stadium.pricePerHour || 0,
  ownerId: stadium.ownerId,
  description: stadium.description || '',
  latitude: stadium.latitude ?? null,
  longitude: stadium.longitude ?? null,
});

const publicBooking = (booking, { stadium, user } = {}) => ({
  id: booking.id,
  userId: booking.userId,
  stadiumId: booking.stadiumId,
  startTime: booking.startTime instanceof Date
    ? booking.startTime.toISOString()
    : booking.startTime,
  endTime: booking.endTime instanceof Date
    ? booking.endTime.toISOString()
    : booking.endTime,
  status: booking.status,
  stadium: stadium ? publicStadium(stadium) : null,
  user: user ? { id: user.id, name: user.name, email: user.email } : null,
  createdAt: booking.createdAt || null,
});

module.exports = { publicUser, publicField, publicStadium, publicBooking };
