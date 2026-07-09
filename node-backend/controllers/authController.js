const bcrypt = require('bcryptjs');
const { getStore } = require('../db');
const { signToken } = require('../utils/jwt');
const { publicUser, publicField } = require('../utils/dto');
const { isEmail, isStrongEnough, normalizeEmail } = require('../utils/validators');
const { serverError } = require('../utils/errors');

const BCRYPT_ROUNDS = 12;
const DUPLICATE_EMAIL_MSG = 'Account already exists, please login';
const VALID_ROLES = new Set(['user', 'owner']);

const store = () => getStore();
const isMongo = () => store().kind === 'mongodb';

async function findUserByEmail(email) {
  const norm = normalizeEmail(email);
  return isMongo()
    ? store().findOne('users', { email: norm })
    : store().findOne('users', (user) => user.email === norm);
}

async function findUserByEmailWithPassword(email) {
  return store().findUserByEmailWithPassword(normalizeEmail(email));
}

async function fieldsByOwner(ownerId) {
  const query = { ownerId: Number(ownerId), isActive: { $ne: false } };
  if (!isMongo()) {
    return store().find('fields', (field) => field.ownerId === Number(ownerId) && field.isActive !== false);
  }
  return store().find('fields', query);
}

async function hashPassword(password) {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

function validateCredentials({ name, email, password }) {
  if (!name || !email || !password) {
    return 'Name, email, and password are required';
  }
  if (!isEmail(email)) {
    return 'Invalid email format';
  }
  if (!isStrongEnough(password)) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

async function attachOwnerField(body, user) {
  if (user.role !== 'owner') return body;
  const owned = await fieldsByOwner(user.id);
  if (owned[0]) body.field = publicField(owned[0]);
  return body;
}

/**
 * POST /api/auth/register
 * Body: { name, email, password, role?, phone?, province?, image? }
 */
async function register(req, res) {
  try {
    const { name, email, password, role = 'user', phone, province, image } = req.body || {};

    const validationError = validateCredentials({ name, email, password });
    if (validationError) return res.status(400).json({ message: validationError });

    const userRole = String(role).toLowerCase();
    if (!VALID_ROLES.has(userRole)) {
      return res.status(400).json({ message: "Role must be 'user' or 'owner'" });
    }

    const normEmail = normalizeEmail(email);
    if (await findUserByEmail(normEmail)) {
      return res.status(409).json({ message: DUPLICATE_EMAIL_MSG });
    }

    const hashed = await hashPassword(password);
    const user = await store().insert('users', {
      name: String(name).trim(),
      email: normEmail,
      password: hashed,
      phone: phone || '',
      province: province || 'نينوى',
      image: image || null,
      role: userRole,
      loyaltyPoints: 0,
    });

    return res.status(201).json({
      token: signToken(user),
      user: publicUser(user),
    });
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * POST /api/register-user (legacy Flutter contract)
 */
async function registerUser(req, res) {
  try {
    const { name, email, password, phone, province, image } = req.body || {};

    const validationError = validateCredentials({ name, email, password });
    if (validationError) return res.status(400).json({ message: validationError });

    const normEmail = normalizeEmail(email);
    if (await findUserByEmail(normEmail)) {
      return res.status(409).json({ message: DUPLICATE_EMAIL_MSG });
    }

    const hashed = await hashPassword(password);
    const user = await store().insert('users', {
      name: String(name).trim(),
      email: normEmail,
      password: hashed,
      phone: phone || '',
      province: province || 'نينوى',
      image: image || null,
      role: 'user',
      loyaltyPoints: 0,
    });

    return res.status(201).json({
      token: signToken(user),
      user: publicUser(user),
    });
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * POST /api/register-owner (legacy Flutter contract — also creates first stadium)
 */
async function registerOwner(req, res) {
  try {
    const {
      name, email, password, phone,
      stadiumName, stadiumAddress, stadiumPhone, pricePerHour, stadiumImage,
    } = req.body || {};

    if (!name || !email || !password || !stadiumName) {
      return res.status(400).json({ message: 'Name, email, password, and stadium name are required' });
    }

    const validationError = validateCredentials({ name, email, password });
    if (validationError) return res.status(400).json({ message: validationError });

    const normEmail = normalizeEmail(email);
    if (await findUserByEmail(normEmail)) {
      return res.status(409).json({ message: DUPLICATE_EMAIL_MSG });
    }

    const hashed = await hashPassword(password);
    const user = await store().insert('users', {
      name: String(name).trim(),
      email: normEmail,
      password: hashed,
      phone: phone || '',
      province: 'نينوى',
      image: null,
      role: 'owner',
      loyaltyPoints: 0,
    });

    const field = await store().insert('fields', {
      name: stadiumName,
      address: stadiumAddress || '',
      phone: stadiumPhone || phone || '',
      image: stadiumImage || null,
      pricePerHour: Number(pricePerHour) || 0,
      ownerId: user.id,
      averageRating: 0,
      reviewCount: 0,
      latitude: null,
      longitude: null,
      isActive: true,
    });

    return res.status(201).json({
      token: signToken(user),
      user: publicUser(user),
      field: publicField(field),
    });
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * POST /api/auth/login | POST /api/login
 */
async function login(req, res) {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await findUserByEmailWithPassword(email);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    delete user.password;
    const body = {
      token: signToken(user),
      user: publicUser(user),
    };

    await attachOwnerField(body, user);
    return res.json(body);
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * GET /api/auth/me | GET /api/me
 */
async function getMe(req, res) {
  try {
    const user = await store().findById('users', req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const body = { user: publicUser(user) };
    await attachOwnerField(body, user);
    return res.json(body);
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * PUT /api/auth/me | PUT /api/me
 */
async function updateMe(req, res) {
  try {
    const { name, phone, image, password } = req.body || {};
    const patch = {};

    if (name != null) patch.name = String(name).trim();
    if (phone != null) patch.phone = phone;
    if (image != null) patch.image = image;
    if (password) {
      if (!isStrongEnough(password)) {
        return res.status(400).json({ message: 'Password must be at least 6 characters' });
      }
      patch.password = await hashPassword(password);
    }

    const updated = await store().update('users', req.user.id, patch);
    if (!updated) return res.status(404).json({ message: 'User not found' });

    return res.json(publicUser(updated));
  } catch (error) {
    return serverError(res, error);
  }
}

module.exports = {
  register,
  registerUser,
  registerOwner,
  login,
  getMe,
  updateMe,
};
