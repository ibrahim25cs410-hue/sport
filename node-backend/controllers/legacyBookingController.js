const { getStore } = require('../db');
const { serverError } = require('../utils/errors');
const { sendNotification } = require('../utils/notifications');
const { emitBookingUpdated } = require('../utils/realtime');
const { publicField } = require('../utils/dto');
const { resolveField } = require('../utils/fieldResolve');

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

function endTimeOf(startIso, hours) {
  return new Date(new Date(startIso).getTime() + (hours || 1) * 3600 * 1000).toISOString();
}

function userBookingDto(booking, field) {
  return {
    id: Number(booking.id) || 0,
    referenceCode: booking.referenceCode || null,
    fieldName: field?.name || booking.fieldName || '',
    fieldPhone: field?.phone || '',
    fieldImage: field?.image || null,
    fieldAddress: field?.address || '',
    startTime: booking.startTime,
    endTime: endTimeOf(booking.startTime, booking.hours),
    hours: Number(booking.hours) || 1,
    totalPrice: Number(booking.totalPrice) || 0,
    status: booking.status || 'pending',
    paymentStatus: booking.paymentStatus || 'unpaid',
    remainingHours: 0,
    canCancel: booking.status === 'pending' || booking.status === 'approved',
  };
}

function ownerBookingDto(booking, user) {
  return {
    id: Number(booking.id) || 0,
    referenceCode: booking.referenceCode || null,
    userName: user?.name || '',
    userPhone: user?.phone || '',
    userEmail: user?.email || '',
    startTime: booking.startTime,
    hours: Number(booking.hours) || 1,
    totalPrice: Number(booking.totalPrice) || 0,
    status: booking.status || 'pending',
  };
}

async function bookingsByUser(userId) {
  return isMongo()
    ? store().find('bookings', { userId: Number(userId) })
    : store().find('bookings', (b) => b.userId === Number(userId));
}

async function bookingsByOwner(ownerId) {
  return isMongo()
    ? store().find('bookings', { ownerId: Number(ownerId) })
    : store().find('bookings', (b) => b.ownerId === Number(ownerId));
}

async function bookingsByField(fieldId) {
  return isMongo()
    ? store().find('bookings', { fieldId: Number(fieldId) })
    : store().find('bookings', (b) => b.fieldId === Number(fieldId));
}

async function fieldsByOwner(ownerId) {
  const q = { ownerId: Number(ownerId), isActive: { $ne: false } };
  if (!isMongo()) {
    return store().find('fields', (f) => f.ownerId === Number(ownerId) && f.isActive !== false);
  }
  return store().find('fields', q);
}

/**
 * POST /api/bookings — legacy field booking (Flutter app, body.fieldId)
 */
async function createFieldBooking(req, res) {
  try {
    const { fieldId, startTime, hours, paymentMethod } = req.body || {};
    if (!fieldId || !startTime) {
      return res.status(400).json({ message: 'الملعب ووقت البدء مطلوبان' });
    }

    const field = await resolveField(fieldId);
    if (!field || field.isActive === false) {
      return res.status(404).json({ message: 'الملعب غير موجود' });
    }

    const pub = publicField(field);
    const resolvedFieldId = pub.id;
    const hrs = Number(hours) || 1;
    const start = new Date(startTime).toISOString();
    const end = endTimeOf(start, hrs);

    const existing = (await bookingsByField(resolvedFieldId))
      .filter((b) => b.status === 'pending' || b.status === 'approved');
    const clash = existing.some(
      (b) => new Date(b.startTime).toISOString().slice(0, 13) === start.slice(0, 13),
    );
    if (clash) {
      return res.status(409).json({ code: 'ConflictError', messageKey: 'slotJustBooked' });
    }

    const hourlyRate = Number(field.pricePerHour) || 0;
    const totalPrice = hourlyRate * hrs;
    const booking = await store().insert('bookings', {
      fieldId: resolvedFieldId,
      ownerId: Number(field.ownerId) || 0,
      userId: req.user.id,
      startTime: start,
      endTime: end,
      hours: hrs,
      totalPrice,
      status: 'pending',
      paymentStatus: 'unpaid',
      paymentMethod: paymentMethod || 'online',
      referenceCode: `REF-${Date.now().toString().slice(-6)}`,
    });

    if (field.ownerId) {
      await sendNotification(field.ownerId, {
        title: 'طلب حجز جديد',
        message: `طلب حجز على ${field.name}`,
      });
    }

    emitBookingUpdated({
      booking,
      status: 'pending',
      fieldName: field.name,
      userName: req.user?.name,
      referenceCode: booking.referenceCode,
    });

    return res.status(201).json({
      id: Number(booking.id) || 0,
      referenceCode: booking.referenceCode,
      paymentStatus: booking.paymentStatus,
      totalPrice: booking.totalPrice,
      discountAmount: 0,
      isDiscountApplied: false,
      hourlyRate,
      loyaltyPoints: 0,
    });
  } catch (error) {
    return serverError(res, error);
  }
}

async function getUserFieldBookings(req, res) {
  try {
    const list = await bookingsByUser(req.params.userId);
    const active = list.filter((b) => b.status === 'pending' || b.status === 'approved');
    const fieldsCache = {};
    const items = [];

    for (const booking of active.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
      fieldsCache[booking.fieldId] ??= await resolveField(booking.fieldId);
      items.push(userBookingDto(booking, fieldsCache[booking.fieldId]));
    }

    return res.json(paged(items, req.query.page, req.query.limit));
  } catch (error) {
    return serverError(res, error);
  }
}

async function getUserFieldBookingHistory(req, res) {
  try {
    const list = await bookingsByUser(req.params.userId);
    const fieldsCache = {};
    const items = [];

    for (const booking of list.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
      fieldsCache[booking.fieldId] ??= await resolveField(booking.fieldId);
      items.push(userBookingDto(booking, fieldsCache[booking.fieldId]));
    }

    return res.json(paged(items, req.query.page, req.query.limit));
  } catch (error) {
    return serverError(res, error);
  }
}

async function cancelFieldBooking(req, res) {
  try {
    const { bookingId } = req.body || {};
    const booking = await store().findById('bookings', bookingId);
    if (!booking) return res.status(404).json({ message: 'الحجز غير موجود' });
    if (Number(booking.userId) !== Number(req.user.id)) {
      return res.status(403).json({ message: 'غير مصرح' });
    }

    await store().update('bookings', bookingId, { status: 'cancelled' });
    await sendNotification(booking.ownerId, {
      title: 'إلغاء حجز',
      message: 'قام المستخدم بإلغاء حجز',
    });

    emitBookingUpdated({ booking: { ...booking, status: 'cancelled' }, status: 'cancelled' });

    return res.json({
      message: 'تم الإلغاء',
      tier: 'free',
      penaltyIqd: 0,
      ownerShareIqd: 0,
      platformShareIqd: 0,
    });
  } catch (error) {
    return serverError(res, error);
  }
}

async function getOwnerFieldBookings(req, res) {
  try {
    const ownerId = Number(req.params.ownerId);
    if (Number(req.user.id) !== ownerId) {
      return res.status(403).json({ message: 'غير مصرح' });
    }

    const owned = await fieldsByOwner(ownerId);
    const field = owned[0] || null;
    const list = await bookingsByOwner(ownerId);
    const usersCache = {};
    const bookings = [];
    let totalRevenue = 0;
    let pendingCount = 0;

    for (const booking of list.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
      usersCache[booking.userId] ??= await store().findById('users', booking.userId);
      bookings.push(ownerBookingDto(booking, usersCache[booking.userId]));
      if (booking.status === 'approved') totalRevenue += booking.totalPrice;
      if (booking.status === 'pending') pendingCount++;
    }

    const commissionRate = 0.10;
    const appCommission = Math.round(totalRevenue * commissionRate);

    return res.json({
      field: field
        ? publicField(field)
        : {
            id: 0,
            name: 'ملعبك',
            address: '',
            phone: '',
            image: null,
            pricePerHour: 0,
            ownerId: ownerId,
            averageRating: 0,
            reviewCount: 0,
            latitude: null,
            longitude: null,
          },
      bookings,
      totalRevenue,
      appCommission,
      netRevenue: totalRevenue - appCommission,
      pendingCount,
    });
  } catch (error) {
    return serverError(res, error);
  }
}

async function approveFieldBooking(req, res) {
  try {
    const { bookingId } = req.body || {};
    const booking = await store().findById('bookings', bookingId);
    if (!booking) return res.status(404).json({ message: 'الحجز غير موجود' });
    if (Number(booking.ownerId) !== Number(req.user.id)) {
      return res.status(403).json({ message: 'غير مصرح' });
    }

    await store().update('bookings', bookingId, { status: 'approved' });
    await sendNotification(booking.userId, {
      title: 'تمت الموافقة',
      message: 'تمت الموافقة على حجزك',
    });

    const updated = { ...booking, status: 'approved' };
    emitBookingUpdated({ booking: updated, status: 'approved' });

    return res.json({ ok: true });
  } catch (error) {
    return serverError(res, error);
  }
}

async function rejectFieldBooking(req, res) {
  try {
    const { bookingId } = req.body || {};
    const booking = await store().findById('bookings', bookingId);
    if (!booking) return res.status(404).json({ message: 'الحجز غير موجود' });
    if (Number(booking.ownerId) !== Number(req.user.id)) {
      return res.status(403).json({ message: 'غير مصرح' });
    }

    await store().update('bookings', bookingId, { status: 'rejected' });
    await sendNotification(booking.userId, {
      title: 'تم الرفض',
      message: 'عذراً، تم رفض حجزك',
    });

    const updated = { ...booking, status: 'rejected' };
    emitBookingUpdated({ booking: updated, status: 'rejected' });

    return res.json({ ok: true });
  } catch (error) {
    return serverError(res, error);
  }
}

module.exports = {
  createFieldBooking,
  getUserFieldBookings,
  getUserFieldBookingHistory,
  cancelFieldBooking,
  getOwnerFieldBookings,
  approveFieldBooking,
  rejectFieldBooking,
};
