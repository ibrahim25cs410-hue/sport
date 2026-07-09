const { getStore } = require('../db');
const { emitToUser } = require('../socketHandler');

const store = () => getStore();

/**
 * Persist a notification and push it in real time via Socket.io.
 *
 * @param {number} userId - Recipient user/owner ID
 * @param {string|{ title?: string, message: string }} payload
 * @returns {Promise<object>} Saved notification record
 */
async function sendNotification(userId, payload) {
  const title = typeof payload === 'string' ? 'Notification' : (payload.title || 'Notification');
  const message = typeof payload === 'string' ? payload : payload.message;

  const record = await store().insert('notifications', {
    userId: Number(userId),
    title,
    message,
    isRead: false,
    createdAt: new Date().toISOString(),
  });

  emitToUser(Number(userId), 'notification', {
    id: record.id,
    userId: record.userId,
    title,
    message,
    isRead: false,
    createdAt: record.createdAt,
  });

  return record;
}

/** @deprecated Use sendNotification instead */
async function notify(userId, title, message) {
  return sendNotification(userId, { title, message });
}

module.exports = { sendNotification, notify };
