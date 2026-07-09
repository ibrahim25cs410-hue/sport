/**
 * تخزين MongoDB عبر Mongoose — للإنتاج.
 */

const mongoose = require('mongoose');
const { Counter, User, Field, Stadium, Booking, Notification } = require('../models');

const MODEL_MAP = {
  users: User,
  fields: Field,
  stadiums: Stadium,
  bookings: Booking,
  notifications: Notification,
};

function toPlain(doc) {
  if (!doc) return null;
  return doc.toJSON ? doc.toJSON() : doc;
}

async function connectMongo(uri) {
  mongoose.set('strictQuery', true);
  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 15000,
    maxPoolSize: 10,
  });
  console.log('✅ اتصال MongoDB ناجح');
}

async function disconnectMongo() {
  await mongoose.disconnect();
}

function createMongoStore() {
  return {
    kind: 'mongodb',

    async insert(col, doc) {
      const Model = MODEL_MAP[col];
      const id = await Counter.nextId(col);
      const created = await Model.create({ id, ...doc });
      return toPlain(created);
    },

    async findById(col, id) {
      const doc = await MODEL_MAP[col].findOne({ id: Number(id) }).lean();
      if (!doc) return null;
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      return rest;
    },

    async findOne(col, query) {
      const doc = await MODEL_MAP[col].findOne(query).lean();
      if (!doc) return null;
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      if (col === 'users' && rest.password) delete rest.password;
      return rest;
    },

    async find(col, query = {}) {
      const docs = await MODEL_MAP[col].find(query).lean();
      return docs.map((doc) => {
        const { _id, __v, createdAt, updatedAt, ...rest } = doc;
        if (col === 'users' && rest.password) delete rest.password;
        return rest;
      });
    },

    async update(col, id, patch) {
      const doc = await MODEL_MAP[col].findOneAndUpdate(
        { id: Number(id) },
        { $set: patch },
        { new: true },
      ).lean();
      if (!doc) return null;
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      if (col === 'users' && rest.password) delete rest.password;
      return rest;
    },

    async findUserByEmailWithPassword(email) {
      const doc = await User.findOne({ email: email.toLowerCase().trim() }).select('+password').lean();
      if (!doc) return null;
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      return rest;
    },

    async softDeleteField(id) {
      return this.update('fields', id, { isActive: false });
    },

    async softDeleteStadium(id) {
      return this.update('stadiums', id, { isActive: false });
    },

    async markAllNotificationsRead(userId) {
      const result = await Notification.updateMany(
        { userId: Number(userId), isRead: false },
        { $set: { isRead: true } },
      );
      return result.modifiedCount;
    },
  };
}

module.exports = { connectMongo, disconnectMongo, createMongoStore };
