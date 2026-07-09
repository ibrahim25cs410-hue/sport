const { emitSlotSelection, emitSlotRelease } = require('./realtime');

/** @type {Map<string, { fieldId: number, userId: number, startTime: string, hours: number, expiresAt: string }>} */
const holds = new Map();

function holdKey(fieldId, startTime, hours) {
  const start = new Date(startTime).toISOString();
  return `${fieldId}:${start.slice(0, 13)}:${hours || 1}`;
}

function purgeExpired() {
  const now = Date.now();
  for (const [key, hold] of holds.entries()) {
    if (new Date(hold.expiresAt).getTime() <= now) holds.delete(key);
  }
}

function selectSlot({ fieldId, userId, startTime, hours = 1, ttlMs = 5 * 60 * 1000 }) {
  purgeExpired();
  const key = holdKey(fieldId, startTime, hours);
  const existing = holds.get(key);
  if (existing && existing.userId !== Number(userId) && new Date(existing.expiresAt) > new Date()) {
    return { conflict: true, messageKey: 'slotUnderSelection' };
  }

  const expiresAt = new Date(Date.now() + ttlMs).toISOString();
  const hold = {
    fieldId: Number(fieldId),
    userId: Number(userId),
    startTime: new Date(startTime).toISOString(),
    hours: Number(hours) || 1,
    expiresAt,
  };
  holds.set(key, hold);

  emitSlotSelection(fieldId, {
    fieldId: hold.fieldId,
    startTime: hold.startTime,
    hours: hold.hours,
    userId: hold.userId,
    expiresAt: hold.expiresAt,
  });

  return { conflict: false, expiresAt };
}

function releaseSlot({ fieldId, userId, startTime, hours = 1 }) {
  const key = holdKey(fieldId, startTime, hours);
  const existing = holds.get(key);
  if (!existing) return false;
  if (Number(existing.userId) !== Number(userId)) return false;

  holds.delete(key);
  emitSlotRelease(fieldId, {
    fieldId: Number(fieldId),
    startTime: new Date(startTime).toISOString(),
    hours: Number(hours) || 1,
  });
  return true;
}

module.exports = { selectSlot, releaseSlot, purgeExpired };
