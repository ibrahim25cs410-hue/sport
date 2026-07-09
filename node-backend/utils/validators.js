const isEmail = (value) =>
  typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());

const isStrongEnough = (value) => typeof value === 'string' && value.length >= 6;

const normalizeEmail = (email) => String(email).trim().toLowerCase();

module.exports = { isEmail, isStrongEnough, normalizeEmail };
