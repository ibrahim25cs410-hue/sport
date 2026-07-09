const { config } = require('../config');
const { createMemoryStore } = require('./memoryStore');
const { connectMongo, disconnectMongo, createMongoStore } = require('./mongoStore');

let store;

async function initStore() {
  if (config.mongodbUri) {
    await connectMongo(config.mongodbUri);
    store = createMongoStore();
  } else {
    store = createMemoryStore();
  }
  return store;
}

function getStore() {
  if (!store) throw new Error('Store not initialized — call initStore() first');
  return store;
}

async function closeStore() {
  if (config.mongodbUri) await disconnectMongo();
  store = null;
}

module.exports = { initStore, getStore, closeStore };
