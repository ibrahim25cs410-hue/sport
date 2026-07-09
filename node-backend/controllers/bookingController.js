const { getStore } = require('../db');
const { publicBooking } = require('../utils/dto');
const { serverError } = require('../utils/errors');
const { sendNotification } = require('../utils/notifications');
const { emitBookingUpdated } = require('../utils/realtime');

const ACTIVE_BOOKING_STATUSES = new Set(['pending', 'confirmed']);
const OWNER_DECISION_STATUSES = new Set(['confirmed', 'rejected']);

const store = () => getStore();
const isMongo = () => store().kind === 'mongodb';

function paged(items, page, limit) {
  return {
    items,
    page: Number(page) || 1,
    limit: Number(limit) || items.length,
    totalCount: items.length,
    hasNextPage: false,
  };
}

function toDate(value) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function overlaps(startA, endA, startB, endB) {
  return startA < endB && endA > startB;
}

async function bookingsByStadium(stadiumId) {
  const id = Number(stadiumId);
  if (isMongo()) {
    return store().find('bookings', { stadiumId: id });
  }
  return store().find('bookings', (booking) => booking.stadiumId === id);
}

async function stadiumBookingsByUser(userId) {
  const id = Number(userId);
  if (isMongo()) {
    return store().find('bookings', { userId: id, stadiumId: { $exists: true, $ne: null } });
  }
  return store().find('bookings', (booking) => booking.userId === id && booking.stadiumId != null);
}

async function stadiumBookingsByOwner(ownerId) {
  const id = Number(ownerId);
  if (isMongo()) {
    return store().find('bookings', { ownerId: id, stadiumId: { $exists: true, $ne: null } });
  }
  return store().find('bookings', (booking) => booking.ownerId === id && booking.stadiumId != null);
}

async function hasScheduleConflict(stadiumId, startTime, endTime, excludeBookingId = null) {
  const existing = await bookingsByStadium(stadiumId);
  return existing.some((booking) => {
    if (excludeBookingId != null && Number(booking.id) === Number(excludeBookingId)) return false;
    if (!ACTIVE_BOOKING_STATUSES.has(booking.status)) return false;
    if (!booking.endTime) return false;
    const existingStart = toDate(booking.startTime);
    const existingEnd = toDate(booking.endTime);
    if (!existingStart || !existingEnd) return false;
    return overlaps(startTime, endTime, existingStart, existingEnd);
  });
}

/**
 * POST /api/bookings — stadium booking (user only)
 * Body: { stadiumId, startTime, endTime }
 */
async function createBooking(req, res) {
  try {
    const { stadiumId, startTime, endTime } = req.body || {};

    if (!stadiumId || !startTime || !endTime) {
      return res.status(400).json({ message: 'stadiumId, startTime, and endTime are required' });
    }

    const start = toDate(startTime);
    const end = toDate(endTime);
    if (!start || !end) {
      return res.status(400).json({ message: 'Invalid startTime or endTime' });
    }
    if (end <= start) {
      return res.status(400).json({ message: 'endTime must be after startTime' });
    }
    if (start <= new Date()) {
      return res.status(400).json({ message: 'startTime must be in the future' });
    }

    const stadium = await store().findById('stadiums', stadiumId);
    if (!stadium || stadium.isActive === false) {
      return res.status(404).json({ message: 'Stadium not found or inactive' });
    }

    if (await hasScheduleConflict(stadium.id, start, end)) {
      return res.status(409).json({ message: 'This time slot is already booked' });
    }

    const booking = await store().insert('bookings', {
      userId: Number(req.user.id),
      stadiumId: Number(stadium.id),
      ownerId: Number(stadium.ownerId),
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      status: 'pending',
    });

    await sendNotification(stadium.ownerId, {
      title: 'New booking request',
      message: `New booking request for ${stadium.name}`,
    });

    emitBookingUpdated({
      booking,
      status: 'pending',
      stadiumName: stadium.name,
    });

    return res.status(201).json(publicBooking(booking, { stadium }));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * PATCH /api/bookings/:id/status — owner only (confirmed | rejected)
 * Body: { status: 'confirmed' | 'rejected' }
 */
async function updateBookingStatus(req, res) {
  try {
    const { status } = req.body || {};
    if (!OWNER_DECISION_STATUSES.has(status)) {
      return res.status(400).json({ message: "status must be 'confirmed' or 'rejected'" });
    }

    const booking = await store().findById('bookings', req.params.id);
    if (!booking || booking.stadiumId == null) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    const stadium = await store().findById('stadiums', booking.stadiumId);
    if (!stadium || Number(stadium.ownerId) !== Number(req.user.id)) {
      return res.status(403).json({ message: 'You can only manage bookings for your own stadiums' });
    }

    if (booking.status !== 'pending') {
      return res.status(400).json({ message: 'Only pending bookings can be updated' });
    }

    const updated = await store().update('bookings', booking.id, { status });

    const title = status === 'confirmed' ? 'Booking confirmed' : 'Booking rejected';
    const message = status === 'confirmed'
      ? `Your booking for ${stadium.name} has been confirmed`
      : `Your booking for ${stadium.name} has been rejected`;

    await sendNotification(booking.userId, { title, message });

    emitBookingUpdated({
      booking: updated,
      status,
      stadiumName: stadium.name,
    });

    return res.json(publicBooking(updated, { stadium }));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * GET /api/bookings/user/me — authenticated user's stadium booking history
 */
async function getUserBookings(req, res) {
  try {
    const list = await stadiumBookingsByUser(req.user.id);
    const stadiumCache = {};
    const items = [];

    for (const booking of list.sort((a, b) => new Date(b.startTime) - new Date(a.startTime))) {
      stadiumCache[booking.stadiumId] ??= await store().findById('stadiums', booking.stadiumId);
      items.push(publicBooking(booking, { stadium: stadiumCache[booking.stadiumId] }));
    }

    return res.json(paged(items, req.query.page, req.query.limit));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * GET /api/bookings/owner/me — all booking requests for owner's stadiums
 */
async function getOwnerBookings(req, res) {
  try {
    const list = await stadiumBookingsByOwner(req.user.id);
    const stadiumCache = {};
    const userCache = {};
    const items = [];

    for (const booking of list.sort((a, b) => new Date(b.startTime) - new Date(a.startTime))) {
      stadiumCache[booking.stadiumId] ??= await store().findById('stadiums', booking.stadiumId);
      userCache[booking.userId] ??= await store().findById('users', booking.userId);
      items.push(publicBooking(booking, {
        stadium: stadiumCache[booking.stadiumId],
        user: userCache[booking.userId],
      }));
    }

    const pendingCount = items.filter((item) => item.status === 'pending').length;

    return res.json({
      ...paged(items, req.query.page, req.query.limit),
      pendingCount,
    });
  } catch (error) {
    return serverError(res, error);
  }
}

module.exports = {
  createBooking,
  updateBookingStatus,
  getUserBookings,
  getOwnerBookings,
};
