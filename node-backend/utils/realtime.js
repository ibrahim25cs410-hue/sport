const {
  emitToUser,
  emitToRoom,
  fieldRoom,
  stadiumRoom,
} = require('../socketHandler');

const STATUS_META = {
  pending: {
    titleKey: 'rtTitleNewBooking',
    messageKey: 'rtMsgNewBooking',
  },
  approved: {
    titleKey: 'rtTitleBookingApproved',
    messageKey: 'rtMsgBookingApproved',
  },
  confirmed: {
    titleKey: 'rtTitleBookingApproved',
    messageKey: 'rtMsgBookingApproved',
  },
  rejected: {
    titleKey: 'rtTitleBookingRejected',
    messageKey: 'rtMsgBookingRejected',
  },
  cancelled: {
    titleKey: 'rtTitleBookingCancelled',
    messageKey: 'rtMsgBookingCancelled',
  },
};

function buildBookingUpdatedPayload({
  booking,
  status,
  fieldName = '',
  stadiumName = '',
  userName = '',
  referenceCode = '',
}) {
  const resolvedStatus = status || booking.status;
  const meta = STATUS_META[resolvedStatus] || {
    titleKey: 'rtTitleBookingPending',
    messageKey: 'rtMsgBookingPending',
  };
  const name = fieldName || stadiumName || '';
  const start = booking.startTime ? new Date(booking.startTime).toISOString() : '';

  return {
    bookingId: Number(booking.id),
    status: resolvedStatus,
    titleKey: meta.titleKey,
    messageKey: meta.messageKey,
    messageArgs: {
      fieldName: name,
      stadiumName: name,
      userName: userName || '',
      referenceCode: referenceCode || booking.referenceCode || String(booking.id),
      dateTime: start,
    },
  };
}

/**
 * Broadcast booking state changes to user, owner, and field/stadium rooms.
 */
function emitBookingUpdated({
  booking,
  status,
  fieldName,
  stadiumName,
  userName,
  referenceCode,
}) {
  const payload = buildBookingUpdatedPayload({
    booking,
    status,
    fieldName,
    stadiumName,
    userName,
    referenceCode,
  });

  emitToUser(booking.userId, 'bookingUpdated', payload);
  if (booking.ownerId) emitToUser(booking.ownerId, 'bookingUpdated', payload);
  if (booking.fieldId) emitToRoom(fieldRoom(booking.fieldId), 'bookingUpdated', payload);
  if (booking.stadiumId) emitToRoom(stadiumRoom(booking.stadiumId), 'bookingUpdated', payload);

  return payload;
}

function emitSlotSelection(fieldId, payload) {
  emitToRoom(fieldRoom(fieldId), 'slotSelection', payload);
}

function emitSlotRelease(fieldId, payload) {
  emitToRoom(fieldRoom(fieldId), 'slotRelease', payload);
}

module.exports = {
  buildBookingUpdatedPayload,
  emitBookingUpdated,
  emitSlotSelection,
  emitSlotRelease,
};
