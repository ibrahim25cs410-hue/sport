/**
 * تخزين في الذاكرة — للتطوير المحلي فقط.
 */

function createMemoryStore() {
  const data = { users: [], fields: [], stadiums: [], bookings: [], notifications: [] };
  const seq = { users: 0, fields: 0, stadiums: 0, bookings: 0, notifications: 0 };
  const clone = (o) => (o ? JSON.parse(JSON.stringify(o)) : o);

  return {
    kind: 'memory',

    async insert(col, doc) {
      const rec = { id: ++seq[col], ...doc };
      data[col].push(rec);
      return clone(rec);
    },

    async findById(col, id) {
      return clone(data[col].find((r) => r.id === Number(id)) || null);
    },

    async findOne(col, pred) {
      if (typeof pred === 'function') return clone(data[col].find(pred) || null);
      return clone(data[col].find((r) => Object.entries(pred).every(([k, v]) => r[k] === v)) || null);
    },

    async find(col, pred) {
      if (!pred) return clone(data[col]);
      if (typeof pred === 'function') return clone(data[col].filter(pred));
      return clone(data[col].filter((r) => Object.entries(pred).every(([k, v]) => r[k] === v)));
    },

    async update(col, id, patch) {
      const rec = data[col].find((r) => r.id === Number(id));
      if (!rec) return null;
      Object.assign(rec, patch);
      return clone(rec);
    },

    async softDeleteField(id) {
      return this.update('fields', id, { isActive: false });
    },

    async softDeleteStadium(id) {
      return this.update('stadiums', id, { isActive: false });
    },

    async markAllNotificationsRead(userId) {
      const list = data.notifications.filter((n) => n.userId === Number(userId) && !n.isRead);
      for (const n of list) n.isRead = true;
      return list.length;
    },

    async findUserByEmailWithPassword(email) {
      return clone(data.users.find((u) => u.email === email.toLowerCase().trim()) || null);
    },
  };
}

module.exports = { createMemoryStore };
