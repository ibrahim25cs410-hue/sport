/**
 * Riyada — باك إند حجز الملاعب (يطابق عقد تطبيق Flutter في mobile/).
 *
 * التخزين:
 *   - افتراضياً: في الذاكرة (in-memory) — يُمسح عند إعادة التشغيل.
 *   - إذا ضبطت MONGODB_URI: يستخدم MongoDB (يبقى محفوظاً).
 *
 * كل المسارات تحت /api ، المعرّفات أرقام صحيحة، JSON بصيغة camelCase،
 * والتواريخ بصيغة ISO 8601. المصادقة عبر JWT (Bearer) عدا التسجيل/الدخول.
 */

require('dotenv').config();

const http = require('http');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Server: SocketServer } = require('socket.io');
const {
  ADMIN_PERMISSIONS,
  effectivePermissions,
  hasPermission,
  setupAdminBackend,
} = require('./admin-backend');

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const IS_PROD = NODE_ENV === 'production';
const MONGODB_URI = process.env.MONGODB_URI || '';
const COMMISSION_RATE = 0.10;
const ELECTRONIC_PAYMENTS_ENABLED = /^(1|true|yes)$/i.test(
  String(process.env.ELECTRONIC_PAYMENTS_ENABLED || 'false'),
);
const MIN_PASSWORD_LENGTH = 6;
const SLOT_HOLD_TTL_MS = 5 * 60 * 1000;
const PENDING_PAYMENT_TTL_MS = 15 * 60 * 1000;

const JWT_SECRET = process.env.JWT_SECRET || '';
const ADMIN_EMAIL = String(process.env.ADMIN_EMAIL || '').trim().toLowerCase();
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';
const ADMIN_NAME = process.env.ADMIN_NAME || 'مدير المنصة';
const ADMIN_BOOTSTRAP_SECRET = process.env.ADMIN_BOOTSTRAP_SECRET || '';

function resolveJwtSecret() {
  if (JWT_SECRET && JWT_SECRET.length >= 32 && JWT_SECRET !== 'dev-secret-change-me') {
    return JWT_SECRET;
  }
  if (IS_PROD) {
    if (!MONGODB_URI) {
      console.error('FATAL: اضبط JWT_SECRET أو MONGODB_URI في متغيرات بيئة Render.');
      process.exit(1);
    }
    // سر ثابت مشتق من Mongo — أفضل من السر الافتراضي الضعيف؛ يُفضّل ضبط JWT_SECRET يدوياً
    const derived = crypto.createHmac('sha256', 'riyada-jwt-v1').update(MONGODB_URI).digest('hex');
    console.warn('تحذير: JWT_SECRET غير مضبوط — استخدام سر مشتق من MONGODB_URI. اضبط JWT_SECRET في Render.');
    return derived;
  }
  console.warn('تحذير تطوير: JWT_SECRET غير مضبوط — لا تستخدم هذا السر في الإنتاج.');
  return JWT_SECRET || 'dev-secret-change-me';
}

const EFFECTIVE_JWT_SECRET = resolveJwtSecret();

/* ================================================================== */
/* FCM (اختياري) — يُفعّل فقط عند توفّر بيانات اعتماد Firebase           */
/* ================================================================== */

let fcmMessaging = null;

function initFcm() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT || '';
  const hasAdc = !!process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!raw && !hasAdc) {
    console.log('FCM: غير مفعّل (لا FIREBASE_SERVICE_ACCOUNT) — الإشعارات الفورية عبر Socket.io فقط');
    return;
  }
  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      if (raw) {
        // يقبل JSON مباشرة أو Base64 لتفادي مشاكل الأسطر الجديدة في Render
        let json = raw.trim();
        if (!json.startsWith('{')) {
          json = Buffer.from(json, 'base64').toString('utf8');
        }
        const creds = JSON.parse(json);
        admin.initializeApp({ credential: admin.credential.cert(creds) });
      } else {
        admin.initializeApp({ credential: admin.credential.applicationDefault() });
      }
    }
    fcmMessaging = admin.messaging();
    console.log('FCM: مفعّل — إرسال إشعارات push حقيقية');
  } catch (e) {
    console.warn('FCM: فشل التهيئة —', e.message || e);
    fcmMessaging = null;
  }
}

async function sendFcmToUser(user, title, message, data = {}) {
  if (!fcmMessaging || !user?.fcmToken) return;
  try {
    await fcmMessaging.send({
      token: user.fcmToken,
      notification: { title, body: message },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
    });
  } catch (e) {
    const code = e?.errorInfo?.code || e?.code || '';
    // توكن غير صالح → احذفه حتى لا نعيد المحاولة
    if (String(code).includes('registration-token-not-registered')
      || String(code).includes('invalid-registration-token')) {
      try { await store.update('users', user.id, { fcmToken: null }); } catch { /* تجاهل */ }
    } else {
      console.warn('FCM send failed:', code || e.message || e);
    }
  }
}

const ALLOWED_ORIGINS = String(process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const app = express();
const server = http.createServer(app);

app.set('trust proxy', 1);
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(compression());
app.use(cors({
  origin(origin, cb) {
    // تطبيقات الموبايل وطلبات السيرفر غالباً بلا Origin
    if (!origin) return cb(null, true);
    if (ALLOWED_ORIGINS.length === 0) {
      if (IS_PROD) {
        // مؤقتاً مسموح — يُفضّل ضبط ALLOWED_ORIGINS في Render
        return cb(null, true);
      }
      return cb(null, true);
    }
    if (ALLOWED_ORIGINS.includes('*') || ALLOWED_ORIGINS.includes(origin)) {
      return cb(null, true);
    }
    return cb(null, false);
  },
  credentials: true,
}));
app.use(express.json({ limit: '2mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'طلبات كثيرة — حاول لاحقاً' },
});
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 40,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'محاولات دخول كثيرة — انتظر قليلاً' },
});
const bookingLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'طلبات حجز كثيرة — حاول لاحقاً' },
});

app.use('/api', globalLimiter);

/* ================================================================== */
/* Socket.io                                                            */
/* ================================================================== */

const io = new SocketServer(server, {
  cors: {
    origin(origin, cb) {
      if (!origin) return cb(null, true);
      if (ALLOWED_ORIGINS.length === 0) return cb(null, true);
      if (ALLOWED_ORIGINS.includes('*') || ALLOWED_ORIGINS.includes(origin)) {
        return cb(null, true);
      }
      return cb(null, false);
    },
    credentials: true,
  },
  transports: ['websocket', 'polling'],
});

/** @type {Map<number, Set<string>>} */
const userSockets = new Map();

function fieldRoom(fieldId) {
  return `field:${Number(fieldId)}`;
}

function registerSocket(userId, socketId) {
  const id = Number(userId);
  if (!Number.isFinite(id)) return;
  if (!userSockets.has(id)) userSockets.set(id, new Set());
  userSockets.get(id).add(socketId);
}

function unregisterSocket(userId, socketId) {
  const id = Number(userId);
  const set = userSockets.get(id);
  if (!set) return;
  set.delete(socketId);
  if (set.size === 0) userSockets.delete(id);
}

function emitToUser(userId, event, payload) {
  const set = userSockets.get(Number(userId));
  if (!set || set.size === 0) return false;
  for (const socketId of set) io.to(socketId).emit(event, payload);
  return true;
}

function emitToField(fieldId, event, payload) {
  io.to(fieldRoom(fieldId)).emit(event, payload);
}

io.use(async (socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;
  if (!token) return next(new Error('Authentication required'));
  try {
    const payload = jwt.verify(token, EFFECTIVE_JWT_SECRET);
    socket.user = { ...payload, id: Number(payload.id) };
    if (!Number.isFinite(socket.user.id)) return next(new Error('Invalid token'));
    if (store) {
      const current = await store.findById('users', socket.user.id);
      if (!current) return next(new Error('Invalid user'));
      if (current.role === 'admin' && current.adminStatus === 'suspended') {
        return next(new Error('Admin account suspended'));
      }
      let currentPermissions = current.customPermissions;
      if (current.role === 'admin' && current.adminRole === 'custom' && current.customRoleId) {
        const customRole = await store.findById('adminRoles', current.customRoleId);
        currentPermissions = customRole && customRole.status !== 'deleted'
          ? customRole.permissions || []
          : [];
      }
      socket.user = {
        ...socket.user,
        role: current.role,
        adminRole: current.adminRole,
        permissions: effectivePermissions({ ...current, customPermissions: currentPermissions }),
      };
    }
    return next();
  } catch {
    return next(new Error('Invalid or expired token'));
  }
});

io.on('connection', (socket) => {
  const userId = Number(socket.user.id);
  registerSocket(userId, socket.id);
  if (socket.user.role === 'admin') {
    socket.join('admin');
    socket.emit('admin:ready', {
      permissions: socket.user.permissions || ADMIN_PERMISSIONS,
    });
  }
  socket.emit('connected', { userId, socketId: socket.id });

  socket.on('joinField', (fieldId) => {
    socket.join(fieldRoom(fieldId));
    socket.data.joinedFieldId = Number(fieldId);
  });
  socket.on('leaveField', (fieldId) => {
    socket.leave(fieldRoom(fieldId));
    if (socket.data.joinedFieldId === Number(fieldId)) socket.data.joinedFieldId = null;
  });
  socket.on('joinStadium', (stadiumId) => {
    socket.join(fieldRoom(stadiumId));
    socket.data.joinedStadiumId = Number(stadiumId);
  });
  socket.on('leaveStadium', (stadiumId) => {
    socket.leave(fieldRoom(stadiumId));
    if (socket.data.joinedStadiumId === Number(stadiumId)) socket.data.joinedStadiumId = null;
  });
  socket.on('disconnect', () => unregisterSocket(userId, socket.id));
});

/* ================================================================== */
/* طبقة التخزين                                                         */
/* ================================================================== */

let store;
let adminBackend;

function createMemoryStore() {
  const data = {
    users: [], fields: [], bookings: [], notifications: [], reviews: [], walletTransactions: [],
    auditLogs: [], maintenanceBlocks: [], settlements: [], adminPreferences: [], adminAlerts: [],
    paymentCredits: [], adminRoles: [], adminInvitations: [],
  };
  const seq = {
    users: 0, fields: 0, bookings: 0, notifications: 0, reviews: 0, walletTransactions: 0,
    auditLogs: 0, maintenanceBlocks: 0, settlements: 0, adminPreferences: 0, adminAlerts: 0,
    paymentCredits: 0, adminRoles: 0, adminInvitations: 0,
  };
  const clone = (o) => (o ? JSON.parse(JSON.stringify(o)) : o);
  return {
    kind: 'memory',
    async insert(col, doc) {
      const rec = { id: ++seq[col], ...doc };
      data[col].push(rec);
      return clone(rec);
    },
    async findById(col, id) {
      const n = Number(id);
      return clone(data[col].find((r) => r.id === n || String(r.id) === String(id)) || null);
    },
    async findOne(col, pred) {
      return clone(data[col].find(pred) || null);
    },
    async find(col, pred) {
      return clone(pred ? data[col].filter(pred) : data[col]);
    },
    async update(col, id, patch) {
      const n = Number(id);
      const rec = data[col].find((r) => r.id === n || String(r.id) === String(id));
      if (!rec) return null;
      Object.assign(rec, patch);
      return clone(rec);
    },
    async applyWalletDeltaOnce(ownerId, idempotencyKey, amount) {
      const rec = data.users.find((user) => sameId(user.id, ownerId));
      if (!rec) return { applied: false, user: null };
      rec.appliedWalletKeys = Array.isArray(rec.appliedWalletKeys) ? rec.appliedWalletKeys : [];
      if (rec.appliedWalletKeys.includes(idempotencyKey)) {
        return { applied: false, user: clone(rec) };
      }
      rec.walletBalance = Number(rec.walletBalance || 0) + Number(amount);
      rec.appliedWalletKeys.push(idempotencyKey);
      return { applied: true, user: clone(rec) };
    },
    async deleteAll(col) {
      const n = data[col].length;
      data[col] = [];
      return n;
    },
    async deleteWhere(col, pred) {
      const before = data[col].length;
      data[col] = data[col].filter((r) => !pred(r));
      return before - data[col].length;
    },
    async resetCounters() {
      Object.keys(seq).forEach((k) => { seq[k] = 0; });
    },
  };
}

async function createMongoStore(uri) {
  const mongoose = require('mongoose');
  await mongoose.connect(uri);
  const { Schema } = mongoose;
  const schemaOpts = { strict: false, timestamps: true, id: false };
  const models = {
    users: mongoose.model('User', new Schema({}, schemaOpts)),
    fields: mongoose.model('Field', new Schema({}, schemaOpts)),
    bookings: mongoose.model('Booking', new Schema({}, schemaOpts)),
    notifications: mongoose.model('Notification', new Schema({}, schemaOpts)),
    reviews: mongoose.model('Review', new Schema({}, schemaOpts)),
    walletTransactions: mongoose.model('WalletTransaction', new Schema({}, schemaOpts)),
    auditLogs: mongoose.model('AuditLog', new Schema({}, schemaOpts)),
    maintenanceBlocks: mongoose.model('MaintenanceBlock', new Schema({}, schemaOpts)),
    settlements: mongoose.model('Settlement', new Schema({}, schemaOpts)),
    adminPreferences: mongoose.model('AdminPreference', new Schema({}, schemaOpts)),
    adminAlerts: mongoose.model('AdminAlert', new Schema({}, schemaOpts)),
    paymentCredits: mongoose.model('PaymentCredit', new Schema({}, schemaOpts)),
    adminRoles: mongoose.model('AdminRole', new Schema({}, schemaOpts)),
    adminInvitations: mongoose.model('AdminInvitation', new Schema({}, schemaOpts)),
  };
  const Counter = mongoose.model('Counter', new Schema({ _id: String, n: Number }));

  // Safe, additive indexes. Sparse uniqueness preserves old documents that do not have these fields.
  await Promise.all([
    models.paymentCredits.collection.createIndex(
      { idempotencyKey: 1 },
      { unique: true, sparse: true, name: 'payment_credit_idempotency' },
    ),
    models.walletTransactions.collection.createIndex(
      { idempotencyKey: 1 },
      { unique: true, sparse: true, name: 'wallet_transaction_idempotency' },
    ),
    models.settlements.collection.createIndex(
      { idempotencyKey: 1 },
      { unique: true, sparse: true, name: 'settlement_idempotency' },
    ),
    models.auditLogs.collection.createIndex({ createdAt: -1 }, { name: 'audit_created_at' }),
    models.adminAlerts.collection.createIndex({ status: 1, createdAt: -1 }, { name: 'alerts_status_created' }),
  ]);

  async function nextId(col) {
    const c = await Counter.findByIdAndUpdate(col, { $inc: { n: 1 } }, { new: true, upsert: true });
    return c.n;
  }
  const out = (doc) => {
    if (!doc) return null;
    const o = doc.toObject ? doc.toObject({ virtuals: false }) : { ...doc };
    const rawId = doc.get ? doc.get('id', null, { getters: false }) : o.id;
    delete o._id; delete o.__v; delete o.createdAt; delete o.updatedAt;
    if (rawId != null && Number.isFinite(Number(rawId))) o.id = Number(rawId);
    return o;
  };

  return {
    kind: 'mongodb',
    async insert(col, doc) {
      const id = await nextId(col);
      const created = await models[col].create({ ...doc, id });
      const mapped = out(created);
      if (!mapped || !Number.isFinite(Number(mapped.id)) || Number(mapped.id) <= 0) {
        throw new Error(`فشل إنشاء سجل في ${col}: id رقمي مفقود`);
      }
      return mapped;
    },
    async findById(col, id) {
      const n = Number(id);
      if (Number.isFinite(n)) {
        const byNum = out(await models[col].findOne({ id: n }));
        if (byNum) return byNum;
      }
      return out(await models[col].findOne({ id: String(id) }));
    },
    async findOne(col, query) {
      return out(await models[col].findOne(query));
    },
    async find(col, query) {
      return (await models[col].find(query || {})).map(out);
    },
    async update(col, id, patch) {
      const n = Number(id);
      if (Number.isFinite(n)) {
        const byNum = out(await models[col].findOneAndUpdate({ id: n }, patch, { new: true }));
        if (byNum) return byNum;
      }
      return out(await models[col].findOneAndUpdate({ id: String(id) }, patch, { new: true }));
    },
    async applyWalletDeltaOnce(ownerId, idempotencyKey, amount) {
      const numericId = Number(ownerId);
      const idQuery = Number.isFinite(numericId)
        ? { $in: [numericId, String(ownerId)] }
        : String(ownerId);
      const updated = await models.users.findOneAndUpdate(
        { id: idQuery, appliedWalletKeys: { $ne: idempotencyKey } },
        {
          $inc: { walletBalance: Number(amount) },
          $addToSet: { appliedWalletKeys: idempotencyKey },
        },
        { new: true },
      );
      if (updated) return { applied: true, user: out(updated) };
      return {
        applied: false,
        user: out(await models.users.findOne({ id: idQuery })),
      };
    },
    async deleteAll(col) {
      const result = await models[col].deleteMany({});
      return result.deletedCount || 0;
    },
    async deleteWhere(col, pred) {
      const all = await models[col].find({});
      let n = 0;
      for (const doc of all) {
        const o = out(doc);
        if (o && pred(o)) {
          await models[col].deleteOne({ _id: doc._id });
          n += 1;
        }
      }
      return n;
    },
    async resetCounters() {
      await Counter.deleteMany({});
    },
  };
}

const isMongo = () => store.kind === 'mongodb';

async function findUserByEmail(email) {
  const norm = String(email || '').trim().toLowerCase();
  if (!norm) return null;
  return isMongo()
    ? store.findOne('users', { email: norm })
    : store.findOne('users', (u) => String(u.email || '').trim().toLowerCase() === norm);
}
async function fieldsByOwner(ownerId, { includeInactive = true } = {}) {
  const all = await store.find('fields');
  return all.filter((f) => {
    if (!sameId(f.ownerId, ownerId)) return false;
    if (!includeInactive && f.isActive === false) return false;
    return true;
  });
}
async function allFields({ includeInactive = false } = {}) {
  const all = await store.find('fields');
  return includeInactive ? all : all.filter((f) => f.isActive !== false);
}
async function bookingsByUser(userId) {
  const all = await store.find('bookings');
  return all.filter((b) => sameId(b.userId, userId));
}
async function bookingsByField(fieldId) {
  const all = await store.find('bookings');
  return all.filter((b) => sameId(b.fieldId, fieldId) || sameId(b.fieldPublicId, fieldId));
}
async function notificationsByUser(userId) {
  const all = await store.find('notifications');
  return all.filter((n) => sameId(n.userId, userId));
}
async function reviewsByField(fieldId) {
  const all = await store.find('reviews');
  return all.filter((r) => sameId(r.fieldId, fieldId) || sameId(r.fieldPublicId, fieldId));
}
async function walletTxByOwner(ownerId) {
  const all = await store.find('walletTransactions');
  return all
    .filter((t) => sameId(t.ownerId, ownerId))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

/* ================================================================== */
/* أدوات المصادقة                                                       */
/* ================================================================== */

function sign(user) {
  return jwt.sign(
    {
      id: Number(user.id),
      role: user.role,
      name: user.name,
      ...(user.role === 'admin' ? { adminRole: user.adminRole || 'admin' } : {}),
    },
    EFFECTIVE_JWT_SECRET,
    { expiresIn: '30d' },
  );
}

async function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'مطلوب تسجيل الدخول' });
  try {
    const payload = jwt.verify(token, EFFECTIVE_JWT_SECRET);
    req.user = { ...payload, id: Number(payload.id) };
    if (!Number.isFinite(req.user.id)) {
      return res.status(401).json({ message: 'انتهت الجلسة' });
    }
    // Load mutable authorization state on every request so permission changes and role revocation
    // take effect immediately instead of waiting for a long-lived JWT to expire.
    const current = await store.findById('users', req.user.id);
    if (!current) return res.status(401).json({ message: 'الحساب غير موجود' });
    if (current.role === 'admin' && current.adminStatus === 'suspended') {
      return res.status(403).json({ message: 'الحساب الإداري موقوف' });
    }
    let currentPermissions = current.customPermissions;
    if (current.role === 'admin' && current.adminRole === 'custom' && current.customRoleId) {
      const customRole = await store.findById('adminRoles', current.customRoleId);
      currentPermissions = customRole && customRole.status !== 'deleted'
        ? customRole.permissions || []
        : [];
    }
    req.user = {
      ...req.user,
      role: current.role,
      name: current.name,
      email: current.email,
      adminRole: current.adminRole,
      customPermissions: currentPermissions,
      deniedPermissions: current.deniedPermissions,
    };
    return next();
  } catch {
    return res.status(401).json({ message: 'انتهت الجلسة' });
  }
}

function optionalAuth(req, _res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (token) {
    try {
      const payload = jwt.verify(token, EFFECTIVE_JWT_SECRET);
      req.user = { ...payload, id: Number(payload.id) };
    } catch { /* تجاهل */ }
  }
  next();
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ message: 'غير مصرح — للمدير فقط' });
  }
  return next();
}

function requireAdminPermission(permission) {
  return (req, res, next) => {
    if (req.user?.role !== 'admin') {
      return res.status(403).json({ message: 'غير مصرح — للمدير فقط' });
    }
    if (!hasPermission(req.user, permission)) {
      return res.status(403).json({
        message: 'لا تملك الصلاحية المطلوبة',
        requiredPermission: permission,
      });
    }
    return next();
  };
}

function requireOwnerOrAdmin(req, res, next) {
  if (req.user?.role !== 'owner' && req.user?.role !== 'admin') {
    return res.status(403).json({ message: 'غير مصرح' });
  }
  return next();
}

function requireOwnerOrAdminPermission(permission) {
  return (req, res, next) => {
    if (req.user?.role === 'owner') return next();
    return requireAdminPermission(permission)(req, res, next);
  };
}

function safeError(res, status, message) {
  return res.status(status).json({ message });
}

/* ================================================================== */
/* أدوات التسلسل (DTO)                                                  */
/* ================================================================== */

const publicUser = (u) => ({
  id: Number(u.id), name: u.name, email: u.email, phone: u.phone || '',
  province: u.province || 'نينوى', image: u.image || null,
  role: u.role, loyaltyPoints: u.loyaltyPoints || 0,
  ...(u.role === 'admin' ? {
    adminRole: u.adminRole || 'admin',
    permissions: effectivePermissions(u),
  } : {}),
});

function flutterStableId(field) {
  const seed = `${field.name || ''}|${field.phone || ''}|${field.address || ''}`;
  let h = 0;
  for (let i = 0; i < seed.length; i += 1) {
    const c = seed.charCodeAt(i);
    h = 0x1fffffff & (h + c);
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
  h ^= h >> 11;
  h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
  const n = Math.abs(h);
  return n === 0 ? 1 : n;
}

function publicNumericId(field) {
  const n = Number(field.id);
  if (Number.isFinite(n) && n > 0) return n;
  return flutterStableId(field);
}

const publicField = (f) => ({
  id: publicNumericId(f), name: f.name, address: f.address || '', phone: f.phone || '',
  image: f.image || null, pricePerHour: f.pricePerHour || 0, ownerId: Number(f.ownerId) || 0,
  averageRating: f.averageRating || 0, reviewCount: f.reviewCount || 0,
  latitude: f.latitude ?? null, longitude: f.longitude ?? null,
  isActive: f.isActive !== false,
});

async function resolveField(publicId) {
  const n = Number(publicId);
  if (!Number.isFinite(n) || n <= 0) return null;
  const byId = await store.findById('fields', n);
  if (byId) return byId;
  const all = await allFields({ includeInactive: true });
  return all.find((f) => publicNumericId(f) === n || flutterStableId(f) === n) || null;
}

function sameId(a, b) {
  if (a == null || b == null) return false;
  const sa = String(a).trim();
  const sb = String(b).trim();
  if (sa === sb) return true;
  const na = Number(a);
  const nb = Number(b);
  return Number.isFinite(na) && Number.isFinite(nb) && na === nb;
}

function authedOwnerId(req) {
  return Number(req.user.id);
}

function endTimeOf(startIso, hours) {
  return new Date(new Date(startIso).getTime() + (hours || 1) * 3600 * 1000).toISOString();
}

function userBookingDto(b, field) {
  return {
    id: Number(b.id),
    referenceCode: b.referenceCode || null,
    fieldName: field?.name || b.fieldName || '',
    fieldPhone: field?.phone || '',
    fieldImage: field?.image || null,
    fieldAddress: field?.address || '',
    startTime: b.startTime,
    endTime: endTimeOf(b.startTime, b.hours),
    hours: b.hours,
    totalPrice: b.totalPrice,
    status: b.status,
    paymentStatus: b.paymentStatus || 'unpaid',
    paymentMethod: b.paymentMethod || 'cash',
    remainingHours: 0,
    canCancel: b.status === 'pending' || b.status === 'approved',
  };
}

function ownerBookingDto(b, user, field) {
  const fieldKey = field != null ? publicNumericId(field) : (Number(b.fieldId) || 0);
  return {
    id: Number(b.id),
    referenceCode: b.referenceCode || null,
    fieldId: fieldKey,
    fieldName: field?.name || b.fieldName || '',
    userName: user?.name || '',
    userPhone: user?.phone || '',
    userEmail: user?.email || '',
    startTime: b.startTime,
    hours: b.hours,
    totalPrice: b.totalPrice,
    status: b.status,
  };
}

function paged(items, page, limit) {
  const p = Math.max(1, Number(page) || 1);
  const l = Math.min(100, Math.max(1, Number(limit) || 20));
  const start = (p - 1) * l;
  const slice = items.slice(start, start + l);
  return {
    items: slice,
    page: p,
    limit: l,
    totalCount: items.length,
    hasNextPage: start + l < items.length,
  };
}

async function notify(userId, title, message, data = {}) {
  const uid = Number(userId);
  if (!Number.isFinite(uid) || uid <= 0) return null;
  const n = await store.insert('notifications', {
    userId: uid, title, message, isRead: false, createdAt: new Date().toISOString(),
  });
  emitToUser(uid, 'notification', {
    id: n.id, title: n.title, message: n.message, isRead: false, createdAt: n.createdAt,
  });
  // إشعار push حقيقي عبر FCM إذا كان التطبيق مغلقاً (لا يعطّل الطلب عند الفشل)
  if (fcmMessaging) {
    store.findById('users', uid)
      .then((user) => sendFcmToUser(user, title, message, { notificationId: String(n.id), ...data }))
      .catch(() => { /* تجاهل */ });
  }
  return n;
}

function emitBookingUpdated(userId, booking, titleKey, messageKey, messageArgs = {}) {
  emitToUser(userId, 'bookingUpdated', {
    bookingId: Number(booking.id),
    status: booking.status,
    titleKey,
    messageKey,
    messageArgs,
  });
}

async function resolveBooking(bookingId, referenceCode) {
  const ref = String(referenceCode || '').trim().replace(/^#/, '');
  if (ref) {
    const all = await store.find('bookings');
    const byRef = all.find((b) => String(b.referenceCode || '') === ref);
    if (byRef) return byRef;
  }
  if (bookingId == null || bookingId === '' || bookingId === 0 || bookingId === '0') return null;
  const byId = await store.findById('bookings', bookingId);
  if (byId) return byId;
  const all = await store.find('bookings');
  const s = String(bookingId).trim().replace(/^#/, '');
  return all.find((b) => sameId(b.id, bookingId) || String(b.referenceCode || '') === s) || null;
}

function fieldKeys(field) {
  const keys = new Set();
  if (field == null) return keys;
  if (field.id != null) keys.add(String(field.id));
  const n = Number(field.id);
  if (Number.isFinite(n) && n > 0) keys.add(String(n));
  keys.add(String(publicNumericId(field)));
  keys.add(String(flutterStableId(field)));
  return keys;
}

function bookingBelongsToField(b, field) {
  if (!b || !field) return false;
  const keys = fieldKeys(field);
  if (keys.has(String(b.fieldId))) return true;
  if (b.fieldPublicId != null && keys.has(String(b.fieldPublicId))) return true;
  return false;
}

function bookingBelongsToOwner(b, ownerId, ownedFields) {
  if (sameId(b.ownerId, ownerId)) return true;
  return (ownedFields || []).some((f) => bookingBelongsToField(b, f));
}

/* ================================================================== */
/* Slot holds + pending payments                                        */
/* ================================================================== */

/** @type {Map<string, { fieldId: number, userId: number, startTime: string, hours: number, expiresAt: string }>} */
const slotHolds = new Map();
/** @type {Map<string, { bookingId: number, userId: number, amount: number, expiresAt: number }>} */
const pendingPayments = new Map();

function holdKey(fieldId, startTime, hours) {
  const start = new Date(startTime).toISOString();
  return `${fieldId}:${start.slice(0, 13)}:${hours || 1}`;
}

function purgeExpiredHolds() {
  const now = Date.now();
  for (const [key, hold] of slotHolds.entries()) {
    if (new Date(hold.expiresAt).getTime() <= now) slotHolds.delete(key);
  }
}

function getActiveHold(fieldId, startIso) {
  purgeExpiredHolds();
  const hourKey = new Date(startIso).toISOString().slice(0, 13);
  for (const hold of slotHolds.values()) {
    if (Number(hold.fieldId) === Number(fieldId)
      && new Date(hold.startTime).toISOString().slice(0, 13) === hourKey) {
      return hold;
    }
  }
  return null;
}

function purgeExpiredPayments() {
  const now = Date.now();
  for (const [token, p] of pendingPayments.entries()) {
    if (p.expiresAt <= now) pendingPayments.delete(token);
  }
}

/* ================================================================== */
/* Wallet helpers                                                       */
/* ================================================================== */

async function ensureOwnerWallet(ownerId) {
  const user = await store.findById('users', ownerId);
  if (!user) return null;
  if (user.walletBalance == null) {
    return store.update('users', ownerId, { walletBalance: 0, walletStatus: 'active' });
  }
  return user;
}

async function addWalletTx({
  ownerId, amount, type, typeLabel, description, bookingId, bookingReference, adminNote,
  idempotencyKey,
}) {
  if (idempotencyKey) {
    const existing = (await store.find('walletTransactions'))
      .find((tx) => tx.idempotencyKey === idempotencyKey);
    if (existing) {
      return { user: await store.findById('users', ownerId), tx: existing, duplicate: true };
    }
  }
  const user = await ensureOwnerWallet(ownerId);
  if (!user) throw new Error('المالك غير موجود');
  if (idempotencyKey) {
    await store.applyWalletDeltaOnce(ownerId, idempotencyKey, amount);
  } else {
    const balance = Number(user.walletBalance || 0) + Number(amount);
    const status = user.walletStatus || 'active';
    await store.update('users', ownerId, { walletBalance: balance, walletStatus: status });
  }
  let tx;
  try {
    tx = await store.insert('walletTransactions', {
      ownerId: Number(ownerId),
      amount: Number(amount),
      type,
      typeLabel,
      description,
      bookingId: bookingId != null ? Number(bookingId) : null,
      bookingReference: bookingReference || null,
      adminNote: adminNote || null,
      ...(idempotencyKey ? { idempotencyKey } : {}),
      createdAt: new Date().toISOString(),
    });
  } catch (error) {
    if (!idempotencyKey || String(error?.code) !== '11000') throw error;
    tx = (await store.find('walletTransactions'))
      .find((item) => item.idempotencyKey === idempotencyKey);
    if (!tx) throw error;
  }
  return { user: await store.findById('users', ownerId), tx };
}

async function walletDetailDto(ownerId) {
  const user = await ensureOwnerWallet(ownerId);
  if (!user) return null;
  const transactions = (await walletTxByOwner(ownerId)).map((t) => ({
    id: Number(t.id),
    amount: Number(t.amount),
    type: t.type,
    typeLabel: t.typeLabel || t.type,
    description: t.description || '',
    bookingId: t.bookingId != null ? Number(t.bookingId) : null,
    bookingReference: t.bookingReference || null,
    adminNote: t.adminNote || null,
    createdAt: t.createdAt,
  }));
  return {
    walletId: Number(ownerId),
    ownerId: Number(ownerId),
    balance: Number(user.walletBalance || 0),
    status: user.walletStatus || 'active',
    lastUpdated: new Date().toISOString(),
    transactions,
  };
}

const paymentCreditLocks = new Map();

async function creditOwnerForPaidBooking(booking) {
  if (!booking?.ownerId || booking.walletCredited || booking.paymentStatus !== 'paid') return null;
  const key = `booking:${booking.id}:paid:v1`;
  if (paymentCreditLocks.has(key)) return paymentCreditLocks.get(key);

  const task = (async () => {
    const fresh = await store.findById('bookings', booking.id);
    if (!fresh || fresh.walletCredited || fresh.paymentStatus !== 'paid') return null;
    const existingCredits = await store.find('paymentCredits');
    const existing = existingCredits.find((credit) => credit.idempotencyKey === key);
    if (existing?.status === 'completed') {
      await store.update('bookings', fresh.id, {
        walletCredited: true,
        walletCreditedAt: existing.completedAt || existing.createdAt,
      });
      return existing;
    }
    if (existing?.status === 'processing'
      && Date.now() - new Date(existing.createdAt || 0).getTime() < 5 * 60 * 1000) {
      return existing;
    }

    let credit = existing;
    if (!credit) {
      try {
        credit = await store.insert('paymentCredits', {
          idempotencyKey: key,
          bookingId: Number(fresh.id),
          ownerId: Number(fresh.ownerId),
          grossAmountIqd: Number(fresh.totalPrice) || 0,
          commissionRate: COMMISSION_RATE,
          status: 'processing',
          createdAt: new Date().toISOString(),
        });
      } catch (error) {
        // A different process may have inserted the unique key. Re-read and avoid double crediting.
        const afterRace = (await store.find('paymentCredits'))
          .find((item) => item.idempotencyKey === key);
        if (afterRace) return afterRace;
        throw error;
      }
    }

    const total = Number(fresh.totalPrice) || 0;
    const commission = Math.round(total * COMMISSION_RATE);
    if (total > 0) {
      await addWalletTx({
        ownerId: fresh.ownerId,
        amount: total,
        type: 'booking_credit',
        typeLabel: 'إيراد محقق',
        description: `إيراد حجز مدفوع ${fresh.referenceCode || fresh.id}`,
        bookingId: fresh.id,
        bookingReference: fresh.referenceCode,
        idempotencyKey: `${key}:gross`,
      });
    }
    if (commission > 0) {
      await addWalletTx({
        ownerId: fresh.ownerId,
        amount: -commission,
        type: 'commission_debit',
        typeLabel: 'عمولة المنصة',
        description: `عمولة 10% على حجز مدفوع ${fresh.referenceCode || fresh.id}`,
        bookingId: fresh.id,
        bookingReference: fresh.referenceCode,
        idempotencyKey: `${key}:commission`,
      });
    }
    const completedAt = new Date().toISOString();
    const completed = await store.update('paymentCredits', credit.id, {
      status: 'completed',
      netAmountIqd: total - commission,
      commissionAmountIqd: commission,
      completedAt,
    });
    await store.update('bookings', fresh.id, { walletCredited: true, walletCreditedAt: completedAt });
    return completed;
  })().finally(() => paymentCreditLocks.delete(key));

  paymentCreditLocks.set(key, task);
  return task;
}

// Kept as an internal compatibility alias for old approval call sites.
async function creditOwnerForApprovedBooking(booking) {
  return creditOwnerForPaidBooking(booking);
}

async function refreshFieldRatings(field) {
  const list = await reviewsByField(publicNumericId(field));
  const reviewCount = list.length;
  const averageRating = reviewCount
    ? Math.round((list.reduce((s, r) => s + Number(r.rating || 0), 0) / reviewCount) * 10) / 10
    : 0;
  if (field.id != null) {
    await store.update('fields', field.id, { averageRating, reviewCount });
  }
  return { averageRating, reviewCount };
}

/* ================================================================== */
/* المسارات — Auth                                                      */
/* ================================================================== */

app.get('/api/health', (_req, res) => res.json({
  status: 'ok',
  storage: store?.kind || 'starting',
  realtime: true,
  electronicPaymentsEnabled: ELECTRONIC_PAYMENTS_ENABLED,
  paymentMode: ELECTRONIC_PAYMENTS_ENABLED ? 'cash_and_electronic' : 'cash_only',
  env: IS_PROD ? 'production' : 'development',
}));

// Capture successful legacy admin mutations as well as the new modular admin routes.
// The response listener is deliberately best-effort and never changes the API response.
app.use('/api', (req, res, next) => {
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) return next();
  res.on('finish', () => {
    if (res.statusCode >= 400 || req.user?.role !== 'admin' || req.auditRecorded || !adminBackend) return;
    adminBackend.audit(
      req,
      `${req.method.toLowerCase()}.${req.path.replace(/^\/+/, '').replace(/[/:]+/g, '.')}`,
      'api',
      req.params?.id || req.params?.bookingId || req.params?.ownerId || null,
      { statusCode: res.statusCode },
    ).catch((error) => console.warn('تعذر تسجيل التدقيق:', error.message || error));
  });
  return next();
});

app.post('/api/register-user', authLimiter, async (req, res) => {
  try {
    const { name, email, password, phone, province, image } = req.body || {};
    if (!name || !email || !password) return safeError(res, 400, 'الاسم والبريد وكلمة المرور مطلوبة');
    if (String(password).length < MIN_PASSWORD_LENGTH) {
      return safeError(res, 400, `كلمة المرور يجب أن تكون ${MIN_PASSWORD_LENGTH} أحرف على الأقل`);
    }
    const normEmail = String(email).trim().toLowerCase();
    if (await findUserByEmail(normEmail)) return safeError(res, 409, 'البريد مستخدم مسبقاً');
    const hashed = await bcrypt.hash(password, 10);
    const user = await store.insert('users', {
      name, email: normEmail, password: hashed, phone: phone || '', province: province || 'نينوى',
      image: image || null, role: 'user', loyaltyPoints: 0, walletBalance: 0, walletStatus: 'active',
    });
    res.status(201).json({ token: sign(user), user: publicUser(user) });
  } catch (e) {
    console.error('register-user:', e);
    return safeError(res, 500, 'خطأ في الخادم');
  }
});

app.post('/api/register-owner', authLimiter, async (req, res) => {
  try {
    const {
      name, email, password, phone, stadiumName, stadiumAddress, stadiumPhone, pricePerHour, stadiumImage,
    } = req.body || {};
    if (!name || !email || !password || !stadiumName) return safeError(res, 400, 'بيانات ناقصة');
    if (String(password).length < MIN_PASSWORD_LENGTH) {
      return safeError(res, 400, `كلمة المرور يجب أن تكون ${MIN_PASSWORD_LENGTH} أحرف على الأقل`);
    }
    const normEmail = String(email).trim().toLowerCase();
    if (await findUserByEmail(normEmail)) return safeError(res, 409, 'البريد مستخدم مسبقاً');
    const hashed = await bcrypt.hash(password, 10);
    const user = await store.insert('users', {
      name, email: normEmail, password: hashed, phone: phone || '', province: 'نينوى',
      image: null, role: 'owner', loyaltyPoints: 0, walletBalance: 0, walletStatus: 'active',
    });
    const field = await store.insert('fields', {
      name: stadiumName, address: stadiumAddress || '', phone: stadiumPhone || phone || '',
      image: stadiumImage || null, pricePerHour: Number(pricePerHour) || 0, ownerId: Number(user.id),
      averageRating: 0, reviewCount: 0, latitude: null, longitude: null, isActive: true,
    });
    res.status(201).json({ token: sign(user), user: publicUser(user), field: publicField(field) });
  } catch (e) {
    console.error('register-owner:', e);
    return safeError(res, 500, 'خطأ في الخادم');
  }
});

app.post('/api/login', authLimiter, async (req, res) => {
  try {
    const { email, password, expectedRole } = req.body || {};
    if (!email || !password) return safeError(res, 400, 'البريد وكلمة المرور مطلوبة');
    const normEmail = String(email).trim().toLowerCase();

    let user = await findUserByEmail(normEmail);
    const passwordOk = user && user.password
      ? await bcrypt.compare(password, user.password)
      : false;

    // حساب الأدمن من Environment على Render — حتى لو البذرة لم تشتغل أو الباسوورد قديم
    if (!passwordOk) {
      const ensured = await ensureAdminFromEnv(normEmail, password);
      if (ensured) {
        user = ensured;
      } else {
        return safeError(res, 401, 'بيانات الدخول غير صحيحة');
      }
    } else if (
      ADMIN_EMAIL
      && normEmail === ADMIN_EMAIL
      && String(password) === ADMIN_PASSWORD
      && user.role !== 'admin'
    ) {
      user = await store.update('users', user.id, { role: 'admin' }) || user;
    }

    const role = String(expectedRole || '').trim().toLowerCase();
    if (role === 'owner' && user.role !== 'owner' && user.role !== 'admin') {
      return safeError(res, 403, 'هذا حساب مستخدم — استخدم تسجيل دخول المستخدم');
    }
    if (role === 'user' && user.role === 'owner') {
      return safeError(res, 403, 'هذا حساب صاحب ملعب — استخدم تسجيل دخول أصحاب الملاعب');
    }
    if (role === 'admin' && user.role !== 'admin') {
      return safeError(res, 403, 'هذا الحساب ليس أدمن');
    }
    const body = { token: sign(user), user: publicUser(user) };
    if (user.role === 'owner') {
      const owned = await fieldsByOwner(user.id);
      if (owned[0]) body.field = publicField(owned[0]);
    }
    res.json(body);
  } catch (e) {
    console.error('login:', e);
    return safeError(res, 500, 'خطأ في الخادم');
  }
});

app.get('/api/me', auth, async (req, res) => {
  const user = await store.findById('users', req.user.id);
  if (!user) return safeError(res, 404, 'غير موجود');
  const body = { user: publicUser(user) };
  if (user.role === 'owner') {
    const owned = await fieldsByOwner(user.id);
    if (owned[0]) body.field = publicField(owned[0]);
  }
  res.json(body);
});

app.put('/api/me', auth, async (req, res) => {
  const { name, phone, image, password } = req.body || {};
  const patch = {};
  if (name != null) patch.name = name;
  if (phone != null) patch.phone = phone;
  if (image != null) patch.image = image;
  if (password) {
    if (String(password).length < MIN_PASSWORD_LENGTH) {
      return safeError(res, 400, `كلمة المرور يجب أن تكون ${MIN_PASSWORD_LENGTH} أحرف على الأقل`);
    }
    patch.password = await bcrypt.hash(password, 10);
  }
  const updated = await store.update('users', req.user.id, patch);
  res.json(publicUser(updated));
});

/* ================================================================== */
/* المسارات — Fields                                                    */
/* ================================================================== */

app.get('/api/fields', optionalAuth, async (req, res) => {
  const list = (await allFields()).map(publicField);
  res.json(paged(list, req.query.page, req.query.limit));
});

app.post('/api/fields', auth, async (req, res) => {
  try {
    if (req.user.role !== 'owner' && req.user.role !== 'admin') {
      return safeError(res, 403, 'غير مصرح — حساب صاحب ملعب فقط');
    }
    if (req.user.role === 'admin' && !hasPermission(req.user, 'fields.manage')) {
      return safeError(res, 403, 'لا تملك صلاحية إدارة الملاعب');
    }
    const { name, address, phone, pricePerHour, image, latitude, longitude } = req.body || {};
    if (!name || !String(name).trim()) return safeError(res, 400, 'اسم الملعب مطلوب');
    const price = Number(pricePerHour);
    if (!Number.isFinite(price) || price < 1000) return safeError(res, 400, 'سعر الساعة غير صالح');
    const field = await store.insert('fields', {
      name: String(name).trim(),
      address: String(address || '').trim(),
      phone: String(phone || '').trim(),
      image: image || null,
      pricePerHour: Math.round(price),
      ownerId: Number(req.user.id),
      averageRating: 0,
      reviewCount: 0,
      latitude: latitude != null ? Number(latitude) : null,
      longitude: longitude != null ? Number(longitude) : null,
      isActive: true,
    });
    adminBackend.publish('admin:field.created', {
      field: publicField(field),
      actorId: Number(req.user.id),
    });
    res.status(201).json(publicField(field));
  } catch (e) {
    console.error('POST /fields:', e);
    return safeError(res, 500, 'فشل إنشاء الملعب');
  }
});

// مسارات المسح القديمة — معطّلة نهائياً (كانت خطرة على الإنتاج)
app.post('/api/admin/clear-fields', auth, (_req, res) => {
  res.status(410).json({ message: 'تم تعطيل مسح الملاعب لأسباب أمنية' });
});
app.post('/api/admin/clear-all', (_req, res) => {
  res.status(410).json({ message: 'تم تعطيل المسح الكامل لأسباب أمنية' });
});

app.get('/api/fields/:id', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f || f.isActive === false) return safeError(res, 404, 'الملعب غير موجود');
  res.json(publicField(f));
});

app.put('/api/fields/:id', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f) return safeError(res, 404, 'الملعب غير موجود');
  if (!sameId(f.ownerId, req.user.id) && req.user.role !== 'admin') {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !hasPermission(req.user, 'fields.manage')) {
    return safeError(res, 403, 'لا تملك صلاحية إدارة الملاعب');
  }
  const { name, address, phone, pricePerHour, image } = req.body || {};
  const patch = {};
  if (name != null) patch.name = name;
  if (address != null) patch.address = address;
  if (phone != null) patch.phone = phone;
  if (pricePerHour != null) patch.pricePerHour = Number(pricePerHour);
  if (image != null) patch.image = image;
  const updated = f.id != null
    ? await store.update('fields', f.id, patch)
    : { ...f, ...patch };
  adminBackend.publish('admin:field.updated', {
    field: publicField(updated),
    actorId: Number(req.user.id),
  });
  res.json(publicField(updated));
});

app.get('/api/fields/:id/schedule', optionalAuth, async (req, res) => {
  try {
    const f = await resolveField(req.params.id);
    if (!f || f.isActive === false) return safeError(res, 404, 'الملعب غير موجود');
    const fieldKey = f.id != null ? f.id : publicNumericId(f);
    const publicId = publicNumericId(f);
    const booked = (await bookingsByField(fieldKey)).filter((b) => b.status === 'pending' || b.status === 'approved');
    const maintenanceDefinitions = (await store.find('maintenanceBlocks')).filter((block) => (
      block.status !== 'cancelled'
      && (sameId(block.fieldId, f.id) || sameId(block.fieldId, publicId))
    ));
    purgeExpiredHolds();

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const maintenanceBlocks = maintenanceDefinitions.flatMap((block) => (
      adminBackend.expandMaintenanceBlock(block, today, new Date(today.getTime() + 7 * 86400000))
    ));
    const schedule = [];
    for (let d = 0; d < 7; d++) {
      const day = new Date(today.getTime() + d * 86400000);
      const slots = [];
      for (let h = 10; h <= 22; h++) {
        const start = new Date(day); start.setHours(h, 0, 0, 0);
        const end = new Date(start.getTime() + 3600000);
        const hold = getActiveHold(publicId, start.toISOString());
        const heldByOther = hold && (!req.user || Number(hold.userId) !== Number(req.user.id));
        const bookingConflict = booked.some((booking) => {
          const bookingStart = new Date(booking.startTime);
          const bookingEnd = new Date(bookingStart.getTime() + (Number(booking.hours) || 1) * 3600000);
          return start < bookingEnd && end > bookingStart;
        });
        const maintenance = maintenanceBlocks.find((block) => {
          const blockStart = new Date(block.startTime);
          const blockEnd = new Date(block.endTime);
          return !Number.isNaN(blockStart.getTime()) && !Number.isNaN(blockEnd.getTime())
            && start < blockEnd && end > blockStart;
        });
        slots.push({
          startTime: start.toISOString(),
          endTime: end.toISOString(),
          isAvailable: !bookingConflict && !heldByOther && !maintenance && start > new Date(),
          status: maintenance ? 'maintenance' : (hold ? 'held' : null),
          heldUntil: hold?.expiresAt || null,
          maintenanceReason: maintenance?.reason || null,
        });
      }
      schedule.push({ date: day.toISOString(), slots });
    }
    res.json({
      id: publicId,
      name: f.name,
      pricePerHour: f.pricePerHour || 0,
      schedule,
    });
  } catch (e) {
    console.error('schedule error:', e);
    return safeError(res, 500, 'فشل تحميل جدول المواعيد');
  }
});

/* ================================================================== */
/* Reviews                                                              */
/* ================================================================== */

app.get('/api/fields/:id/review-eligibility', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f) return safeError(res, 404, 'الملعب غير موجود');
  const publicId = publicNumericId(f);
  const userBookings = (await bookingsByUser(req.user.id))
    .filter((b) => bookingBelongsToField(b, f) && (b.status === 'approved' || b.status === 'completed'));
  const hasBooked = userBookings.length > 0;
  const existing = (await reviewsByField(publicId)).find((r) => sameId(r.userId, req.user.id));
  res.json({
    canReview: hasBooked && !existing,
    hasBooked,
    userRating: existing?.rating ?? null,
    averageRating: f.averageRating || 0,
    reviewCount: f.reviewCount || 0,
  });
});

app.get('/api/fields/:id/reviews', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f) return safeError(res, 404, 'الملعب غير موجود');
  const list = await reviewsByField(publicNumericId(f));
  const items = [];
  for (const r of list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))) {
    const user = await store.findById('users', r.userId);
    items.push({
      id: Number(r.id),
      userId: Number(r.userId),
      userName: user?.name || 'مستخدم',
      rating: Number(r.rating),
      comment: r.comment || null,
      createdAt: r.createdAt,
    });
  }
  res.json(items);
});

app.post('/api/fields/:id/reviews', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f) return safeError(res, 404, 'الملعب غير موجود');
  const rating = Number(req.body?.rating);
  if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
    return safeError(res, 400, 'التقييم يجب أن يكون بين 1 و 5');
  }
  const publicId = publicNumericId(f);
  const hasBooked = (await bookingsByUser(req.user.id))
    .some((b) => bookingBelongsToField(b, f) && (b.status === 'approved' || b.status === 'completed'));
  if (!hasBooked) return safeError(res, 403, 'يجب حجز الملعب أولاً قبل التقييم');
  const existing = (await reviewsByField(publicId)).find((r) => sameId(r.userId, req.user.id));
  if (existing) return safeError(res, 409, 'لقد قيّمت هذا الملعب مسبقاً');
  await store.insert('reviews', {
    fieldId: f.id != null ? f.id : publicId,
    fieldPublicId: publicId,
    userId: Number(req.user.id),
    rating: Math.round(rating),
    comment: String(req.body?.comment || '').trim() || null,
    createdAt: new Date().toISOString(),
  });
  const stats = await refreshFieldRatings(f);
  res.status(201).json({ ok: true, ...stats });
});

/* ================================================================== */
/* Slots                                                                */
/* ================================================================== */

app.post('/api/slots/select', auth, async (req, res) => {
  const { fieldId, startTime, hours } = req.body || {};
  if (!fieldId || !startTime) return safeError(res, 400, 'الملعب ووقت البدء مطلوبان');
  const f = await resolveField(fieldId);
  if (!f) return safeError(res, 404, 'الملعب غير موجود');
  const publicId = publicNumericId(f);
  const hrs = Number(hours) || 1;
  purgeExpiredHolds();
  const key = holdKey(publicId, startTime, hrs);
  const existing = slotHolds.get(key);
  if (existing && Number(existing.userId) !== Number(req.user.id)
    && new Date(existing.expiresAt) > new Date()) {
    return res.status(409).json({ code: 'ConflictError', messageKey: 'slotUnderSelection' });
  }
  const booked = (await bookingsByField(f.id != null ? f.id : publicId))
    .filter((b) => b.status === 'pending' || b.status === 'approved');
  const start = new Date(startTime).toISOString();
  if (booked.some((b) => new Date(b.startTime).toISOString().slice(0, 13) === start.slice(0, 13))) {
    return res.status(409).json({ code: 'ConflictError', messageKey: 'slotJustBooked' });
  }
  const expiresAt = new Date(Date.now() + SLOT_HOLD_TTL_MS).toISOString();
  const hold = {
    fieldId: publicId,
    userId: Number(req.user.id),
    startTime: start,
    hours: hrs,
    expiresAt,
  };
  slotHolds.set(key, hold);
  emitToField(publicId, 'slotSelection', hold);
  res.json({ expiresAt });
});

app.post('/api/slots/release', auth, (req, res) => {
  const { fieldId, startTime, hours } = req.body || {};
  if (!fieldId || !startTime) return res.json({ ok: true });
  const publicId = Number(fieldId);
  const key = holdKey(publicId, startTime, Number(hours) || 1);
  const existing = slotHolds.get(key);
  if (existing && Number(existing.userId) === Number(req.user.id)) {
    slotHolds.delete(key);
    emitToField(publicId, 'slotRelease', {
      fieldId: publicId,
      startTime: new Date(startTime).toISOString(),
      hours: Number(hours) || 1,
    });
  }
  res.json({ ok: true });
});

/* ================================================================== */
/* Bookings                                                             */
/* ================================================================== */

app.post('/api/bookings', auth, bookingLimiter, async (req, res) => {
  const { fieldId, startTime, hours, paymentMethod } = req.body || {};
  if (!fieldId || !startTime) return safeError(res, 400, 'الملعب ووقت البدء مطلوبان');
  const field = await resolveField(fieldId);
  if (!field || field.isActive === false) return safeError(res, 404, 'الملعب غير موجود');

  const hrs = Number(hours) || 1;
  const start = new Date(startTime).toISOString();
  const resolvedFieldId = publicNumericId(field);

  const hold = getActiveHold(resolvedFieldId, start);
  if (hold && Number(hold.userId) !== Number(req.user.id)) {
    return res.status(409).json({ code: 'ConflictError', messageKey: 'slotUnderSelection' });
  }

  const existing = (await bookingsByField(field.id != null ? field.id : resolvedFieldId))
    .filter((b) => b.status === 'pending' || b.status === 'approved');
  const clash = existing.some((b) => new Date(b.startTime).toISOString().slice(0, 13) === start.slice(0, 13));
  if (clash) return res.status(409).json({ code: 'ConflictError', messageKey: 'slotJustBooked' });
  const adminConflict = adminBackend
    ? await adminBackend.bookingConflict(field, start, hrs)
    : null;
  if (adminConflict) {
    return res.status(409).json({
      code: adminConflict.type === 'maintenance' ? 'MaintenanceConflict' : 'ConflictError',
      messageKey: adminConflict.type === 'maintenance' ? 'fieldUnderMaintenance' : 'slotJustBooked',
      conflictId: Number(adminConflict.record.id),
    });
  }

  const hourlyRate = field.pricePerHour || 0;
  const totalPrice = hourlyRate * hrs;
  const requestedMethod = String(paymentMethod || 'cash').toLowerCase();
  const method = ELECTRONIC_PAYMENTS_ENABLED && requestedMethod !== 'cash' ? 'online' : 'cash';
  const paymentStatus = method === 'cash' ? 'pay_at_venue' : 'unpaid';
  const ownerId = Number(field.ownerId) || 0;
  const storedFieldId = field.id != null ? field.id : resolvedFieldId;
  const booking = await store.insert('bookings', {
    fieldId: storedFieldId,
    fieldPublicId: resolvedFieldId,
    ownerId,
    userId: Number(req.user.id),
    startTime: start, hours: hrs, totalPrice, status: 'pending',
    paymentStatus,
    paymentMethod: method,
    referenceCode: 'REF-' + Date.now().toString().slice(-6),
    createdAt: new Date().toISOString(),
    walletCredited: false,
  });

  slotHolds.delete(holdKey(resolvedFieldId, start, hrs));
  emitToField(resolvedFieldId, 'slotRelease', {
    fieldId: resolvedFieldId, startTime: start, hours: hrs,
  });

  await notify(
    ownerId,
    'طلب حجز جديد',
    method === 'cash'
      ? `طلب حجز نقدي على ${field.name} — بانتظار موافقتك`
      : `طلب حجز على ${field.name}`,
  );
  await notify(
    req.user.id,
    'تم إرسال طلب الحجز',
    `حجزك على ${field.name} بانتظار موافقة صاحب الملعب`,
  );
  emitBookingUpdated(req.user.id, booking, 'bookingPending', 'bookingPendingMessage', {
    fieldName: field.name,
  });
  emitBookingUpdated(ownerId, booking, 'bookingPending', 'newBookingRequest', {
    fieldName: field.name,
  });
  adminBackend.publish('admin:booking.created', {
    bookingId: Number(booking.id),
    referenceCode: booking.referenceCode,
    fieldId: resolvedFieldId,
    fieldName: field.name,
    ownerId,
    userId: Number(req.user.id),
    startTime: booking.startTime,
    status: booking.status,
    paymentStatus: booking.paymentStatus,
    totalPrice: booking.totalPrice,
    source: 'app',
  });
  await adminBackend.createAlert({
    type: 'booking',
    severity: 'info',
    title: 'طلب حجز جديد',
    message: `${field.name} — ${booking.referenceCode || booking.id}`,
    actionUrl: `/bookings/${booking.id}`,
    entityType: 'booking',
    entityId: booking.id,
    dedupeKey: `booking:${booking.id}:pending`,
    data: { bookingId: booking.id, fieldId: resolvedFieldId, ownerId },
  });

  res.status(201).json({
    id: Number(booking.id),
    referenceCode: booking.referenceCode,
    paymentStatus: booking.paymentStatus,
    paymentMethod: booking.paymentMethod,
    totalPrice: booking.totalPrice,
    discountAmount: 0,
    isDiscountApplied: false,
    hourlyRate,
    loyaltyPoints: 0,
    status: 'pending',
    fieldId: resolvedFieldId,
    fieldName: field.name,
    startTime: booking.startTime,
    hours: booking.hours,
  });
});

async function listUserBookings(userId, { activeOnly = false, page, limit } = {}) {
  let list = await bookingsByUser(userId);
  if (activeOnly) {
    list = list.filter((b) => b.status === 'pending' || b.status === 'approved');
  }
  const fieldsCache = {};
  const items = [];
  for (const b of list.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
    if (!Number.isFinite(Number(b.id)) || Number(b.id) <= 0) continue;
    fieldsCache[b.fieldId] ??= await store.findById('fields', b.fieldId)
      ?? (await allFields({ includeInactive: true })).find((f) => bookingBelongsToField(b, f))
      ?? null;
    items.push(userBookingDto(b, fieldsCache[b.fieldId]));
  }
  return paged(items, page, limit);
}

app.get('/api/bookings/user/me', auth, async (req, res) => {
  res.json(await listUserBookings(Number(req.user.id), {
    activeOnly: true, page: req.query.page, limit: req.query.limit,
  }));
});

app.get('/api/bookings/user/me/history', auth, async (req, res) => {
  res.json(await listUserBookings(Number(req.user.id), {
    page: req.query.page, limit: req.query.limit,
  }));
});

app.get('/api/bookings/user/:userId', auth, async (req, res) => {
  if (req.user.role === 'admin') {
    if (!hasPermission(req.user, 'bookings.read')) return safeError(res, 403, 'لا تملك صلاحية عرض الحجوزات');
    return res.json(await listUserBookings(Number(req.params.userId), {
      activeOnly: true, page: req.query.page, limit: req.query.limit,
    }));
  }
  if (!sameId(req.params.userId, req.user.id)) {
    return safeError(res, 403, 'غير مصرح');
  }
  res.json(await listUserBookings(Number(req.user.id), {
    activeOnly: true, page: req.query.page, limit: req.query.limit,
  }));
});

app.get('/api/bookings/user/:userId/history', auth, async (req, res) => {
  if (req.user.role === 'admin') {
    if (!hasPermission(req.user, 'bookings.read')) return safeError(res, 403, 'لا تملك صلاحية عرض الحجوزات');
    return res.json(await listUserBookings(Number(req.params.userId), {
      page: req.query.page, limit: req.query.limit,
    }));
  }
  if (!sameId(req.params.userId, req.user.id)) {
    return safeError(res, 403, 'غير مصرح');
  }
  res.json(await listUserBookings(Number(req.user.id), {
    page: req.query.page, limit: req.query.limit,
  }));
});

app.post('/api/bookings/cancel', auth, async (req, res) => {
  const { bookingId, referenceCode } = req.body || {};
  const b = await resolveBooking(bookingId, referenceCode);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
  if (!sameId(b.userId, req.user.id) && req.user.role !== 'admin') {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !hasPermission(req.user, 'bookings.manage')) {
    return safeError(res, 403, 'لا تملك صلاحية إدارة الحجوزات');
  }
  if (b.status === 'cancelled') {
    return res.json({ message: 'تم الإلغاء مسبقاً', tier: 'free', penaltyIqd: 0, ownerShareIqd: 0, platformShareIqd: 0 });
  }
  const updated = await store.update('bookings', b.id, { status: 'cancelled' });
  await notify(b.ownerId, 'إلغاء حجز', 'قام المستخدم بإلغاء حجز');
  emitBookingUpdated(b.userId, updated || { ...b, status: 'cancelled' }, 'bookingCancelled', 'bookingCancelled');
  emitBookingUpdated(b.ownerId, updated || { ...b, status: 'cancelled' }, 'bookingCancelled', 'bookingCancelled');
  if (b.fieldPublicId || b.fieldId) {
    emitToField(b.fieldPublicId || b.fieldId, 'slotRelease', {
      fieldId: Number(b.fieldPublicId || b.fieldId),
      startTime: b.startTime,
      hours: b.hours || 1,
    });
  }
  adminBackend.publish('admin:booking.cancelled', {
    bookingId: Number(b.id),
    status: 'cancelled',
    actorId: Number(req.user.id),
    actorRole: req.user.role,
  });
  await adminBackend.closeEntityAlerts('booking', b.id, 'dismissed', 'booking_cancelled', 'booking');
  res.json({ message: 'تم الإلغاء', tier: 'free', penaltyIqd: 0, ownerShareIqd: 0, platformShareIqd: 0 });
});

async function buildOwnerDashboard(ownerId) {
  const owned = await fieldsByOwner(ownerId);
  const field = owned[0] || null;
  const allBookings = await store.find('bookings');
  const list = allBookings.filter((b) => {
    if (!Number.isFinite(Number(b.id)) || Number(b.id) <= 0) return false;
    return bookingBelongsToOwner(b, ownerId, owned);
  });
  const usersCache = {};
  const bookings = [];
  const byField = owned.map((f) => ({ field: publicField(f), bookings: [] }));
  let totalRevenue = 0;
  let pendingCount = 0;
  for (const b of list.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
    try {
      const f = owned.find((of) => bookingBelongsToField(b, of))
        || owned.find((of) => sameId(of.id, b.fieldId) || sameId(publicNumericId(of), b.fieldPublicId))
        || null;
      usersCache[b.userId] ??= await store.findById('users', b.userId);
      const dto = ownerBookingDto(b, usersCache[b.userId], f);
      bookings.push(dto);
      const bucket = byField.find((x) => sameId(x.field.id, dto.fieldId)
        || (f && sameId(x.field.id, publicNumericId(f))));
      if (bucket) bucket.bookings.push(dto);
      if (b.status === 'approved') totalRevenue += Number(b.totalPrice) || 0;
      if (b.status === 'pending') pendingCount++;
    } catch (e) {
      console.error('تخطي حجز تالف في لوحة المالك:', e.message || e);
    }
  }
  const appCommission = Math.round(totalRevenue * COMMISSION_RATE);
  return {
    field: field ? publicField(field) : null,
    fields: byField,
    bookings,
    totalRevenue,
    appCommission,
    netRevenue: totalRevenue - appCommission,
    pendingCount,
  };
}

app.get('/api/bookings/owner/me', auth, requireOwnerOrAdminPermission('bookings.read'), async (req, res) => {
  try {
    res.json(await buildOwnerDashboard(authedOwnerId(req)));
  } catch (e) {
    console.error('owner/me dashboard:', e);
    return safeError(res, 500, 'فشل تحميل لوحة المالك');
  }
});

app.get('/api/bookings/owner/:ownerId', auth, async (req, res) => {
  try {
    if (req.user.role === 'admin') {
      if (!hasPermission(req.user, 'bookings.read')) return safeError(res, 403, 'لا تملك صلاحية عرض الحجوزات');
      return res.json(await buildOwnerDashboard(Number(req.params.ownerId)));
    }
    if (req.user.role !== 'owner') return safeError(res, 403, 'غير مصرح');
    res.json(await buildOwnerDashboard(authedOwnerId(req)));
  } catch (e) {
    console.error('owner dashboard:', e);
    return safeError(res, 500, 'فشل تحميل لوحة المالك');
  }
});

app.post('/api/bookings/approve', auth, requireOwnerOrAdminPermission('bookings.manage'), async (req, res) => {
  const { bookingId, referenceCode } = req.body || {};
  const b = await resolveBooking(bookingId, referenceCode);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
  if (b.status === 'approved') {
    await creditOwnerForPaidBooking(b);
    return res.json({ ok: true, unchanged: true });
  }
  const owned = await fieldsByOwner(req.user.id);
  const ownsBooking = req.user.role === 'admin' || bookingBelongsToOwner(b, req.user.id, owned);
  if (!ownsBooking) return safeError(res, 403, 'غير مصرح');
  const updated = await store.update('bookings', b.id, {
    status: 'approved',
    ownerId: Number(b.ownerId || req.user.id),
  });
  await creditOwnerForApprovedBooking(updated || { ...b, status: 'approved' });
  await notify(
    b.userId,
    'تمت الموافقة على حجزك',
    b.referenceCode
      ? `تمت الموافقة على حجزك — الرقم المرجعي: ${b.referenceCode}`
      : 'تمت الموافقة على حجزك — يمكنك مراجعته من قائمة الحجوزات',
  );
  emitBookingUpdated(b.userId, updated || { ...b, status: 'approved' }, 'bookingApproved', 'bookingApproved');
  adminBackend.publish('admin:booking.approved', {
    bookingId: Number(b.id),
    status: 'approved',
    actorId: Number(req.user.id),
    actorRole: req.user.role,
  });
  await adminBackend.closeEntityAlerts('booking', b.id, 'resolved', 'booking_approved', 'booking');
  res.json({ ok: true });
});

app.post('/api/bookings/reject', auth, requireOwnerOrAdminPermission('bookings.manage'), async (req, res) => {
  const { bookingId, referenceCode } = req.body || {};
  const b = await resolveBooking(bookingId, referenceCode);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
  if (b.status === 'rejected') return res.json({ ok: true, unchanged: true });
  const owned = await fieldsByOwner(req.user.id);
  const ownsBooking = req.user.role === 'admin' || bookingBelongsToOwner(b, req.user.id, owned);
  if (!ownsBooking) return safeError(res, 403, 'غير مصرح');
  const updated = await store.update('bookings', b.id, {
    status: 'rejected',
    ownerId: Number(b.ownerId || req.user.id),
  });
  await notify(b.userId, 'تم الرفض', 'عذراً، تم رفض حجزك');
  emitBookingUpdated(b.userId, updated || { ...b, status: 'rejected' }, 'bookingRejected', 'bookingRejected');
  if (b.fieldPublicId || b.fieldId) {
    emitToField(b.fieldPublicId || b.fieldId, 'slotRelease', {
      fieldId: Number(b.fieldPublicId || b.fieldId),
      startTime: b.startTime,
      hours: b.hours || 1,
    });
  }
  adminBackend.publish('admin:booking.rejected', {
    bookingId: Number(b.id),
    status: 'rejected',
    actorId: Number(req.user.id),
    actorRole: req.user.role,
  });
  await adminBackend.closeEntityAlerts('booking', b.id, 'dismissed', 'booking_rejected', 'booking');
  res.json({ ok: true });
});

/* ================================================================== */
/* Payments — تسجيل داخلي آمن (بدون بوابة خارجية وهمية)                   */
/* ================================================================== */

app.post('/api/bookings/:bookingId/pay/initiate', auth, async (req, res) => {
  if (!ELECTRONIC_PAYMENTS_ENABLED) {
    return res.status(503).json({
      code: 'ELECTRONIC_PAYMENTS_DISABLED',
      paymentMode: 'cash_only',
      message: 'الدفع الإلكتروني سيتوفر قريباً — الدفع الحالي نقداً في الملعب فقط',
    });
  }
  purgeExpiredPayments();
  const b = await resolveBooking(req.params.bookingId);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
  if (!sameId(b.userId, req.user.id) && req.user.role !== 'admin') {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !hasPermission(req.user, 'finance.manage')) {
    return safeError(res, 403, 'لا تملك صلاحية إدارة المدفوعات');
  }
  if (b.paymentStatus === 'paid') {
    return res.json({
      transactionToken: null,
      gateway: req.body?.gateway || 'card',
      amount: 0,
      checkoutUrl: null,
      message: 'الحجز مدفوع مسبقاً',
    });
  }
  const token = `pay-${b.id}-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  pendingPayments.set(token, {
    bookingId: Number(b.id),
    userId: Number(req.user.id),
    amount: Number(b.totalPrice) || 0,
    expiresAt: Date.now() + PENDING_PAYMENT_TTL_MS,
  });
  res.json({
    transactionToken: token,
    gateway: req.body?.gateway || 'manual',
    amount: Number(b.totalPrice) || 0,
    checkoutUrl: null,
    message: 'ادفع في الملعب أو أكّد عبر المالك — لا توجد بوابة إلكترونية مفعّلة حالياً',
  });
});

app.post('/api/bookings/pay/verify', auth, async (req, res) => {
  purgeExpiredPayments();
  const token = String(req.body?.transactionToken || '');
  const bookingId = req.body?.bookingId;
  let b = null;

  if (token) {
    const pending = pendingPayments.get(token);
    if (!pending) {
      return res.status(400).json({
        success: false,
        status: 'failed',
        message: 'رمز الدفع غير صالح أو منتهٍ',
      });
    }
    b = await store.findById('bookings', pending.bookingId);
  } else if (bookingId != null) {
    b = await resolveBooking(bookingId);
  }

  if (!b) return safeError(res, 404, 'الحجز غير موجود');
  if (b.paymentStatus === 'paid') {
    return res.json({
      success: true,
      status: 'paid',
      invoiceId: `INV-${b.id}`,
      outstandingAmount: 0,
      message: 'الحجز مدفوع مسبقاً',
    });
  }

  const owned = await fieldsByOwner(req.user.id);
  const isOwner = req.user.role === 'admin' || bookingBelongsToOwner(b, req.user.id, owned);
  const isBookingUser = sameId(b.userId, req.user.id);

  // لا بوابة إلكترونية حقيقية — تأكيد الدفع النقدي للمالك فقط
  if (b.paymentMethod !== 'cash' && b.paymentStatus !== 'pay_at_venue') {
    return res.status(503).json({
      success: false,
      status: 'unavailable',
      invoiceId: null,
      outstandingAmount: Number(b.totalPrice) || 0,
      message: 'بوابة الدفع الإلكتروني غير مفعّلة — استخدم الدفع نقداً في الملعب',
    });
  }

  if (!isOwner) {
    return res.status(403).json({
      success: false,
      status: 'forbidden',
      message: isBookingUser
        ? 'تأكيد الدفع النقدي يتم عبر صاحب الملعب'
        : 'غير مصرح',
    });
  }
  if (req.user.role === 'admin' && !hasPermission(req.user, 'finance.manage')) {
    return res.status(403).json({
      success: false, status: 'forbidden', message: 'لا تملك صلاحية إدارة المدفوعات',
    });
  }

  const paidBooking = await store.update('bookings', b.id, {
    paymentStatus: 'paid',
    paidAt: b.paidAt || new Date().toISOString(),
    paymentConfirmedBy: Number(req.user.id),
  });
  await creditOwnerForPaidBooking(paidBooking || { ...b, paymentStatus: 'paid' });
  adminBackend.publish('admin:payment.verified', {
    bookingId: Number(b.id),
    ownerId: Number(b.ownerId) || null,
    amountIqd: Number(b.totalPrice) || 0,
    paymentStatus: 'paid',
    confirmedBy: Number(req.user.id),
  });
  await adminBackend.createAlert({
    type: 'finance',
    severity: 'info',
    title: 'تم تأكيد دفعة',
    message: `تم تحقيق إيراد الحجز ${b.referenceCode || b.id}`,
    actionUrl: `/bookings/${b.id}`,
    entityType: 'booking',
    entityId: b.id,
    dedupeKey: `booking:${b.id}:paid`,
    data: { bookingId: b.id, ownerId: b.ownerId, amountIqd: Number(b.totalPrice) || 0 },
  });
  if (token) pendingPayments.delete(token);
  res.json({
    success: true,
    status: 'paid',
    invoiceId: `INV-${b.id}`,
    outstandingAmount: 0,
    message: 'تم تأكيد الدفع',
  });
});

app.get('/api/payments/owner/me/account', auth, requireOwnerOrAdminPermission('finance.read'), async (req, res) => {
  const dash = await buildOwnerDashboard(authedOwnerId(req));
  res.json({
    outstandingAmount: dash.appCommission,
    outstandingHours: 0,
    totalPaid: Math.max(0, dash.totalRevenue - dash.appCommission),
    pendingInvoices: [],
    paidInvoices: [],
    recentPayments: [],
  });
});

app.get('/api/payments/owner/:ownerId/account', auth, async (req, res) => {
  let ownerId = Number(req.user.id);
  if (req.user.role === 'admin') {
    if (!hasPermission(req.user, 'finance.read')) return safeError(res, 403, 'لا تملك صلاحية عرض البيانات المالية');
    ownerId = Number(req.params.ownerId);
  }
  else if (req.user.role !== 'owner') return safeError(res, 403, 'غير مصرح');
  const dash = await buildOwnerDashboard(ownerId);
  res.json({
    outstandingAmount: dash.appCommission,
    outstandingHours: 0,
    totalPaid: Math.max(0, dash.totalRevenue - dash.appCommission),
    pendingInvoices: [],
    paidInvoices: [],
    recentPayments: [],
  });
});

app.post('/api/payments/initiate', auth, (_req, res) => {
  res.status(503).json({
    message: 'بوابة دفع العمولات غير مفعّلة حالياً — تواصل مع الإدارة',
  });
});

app.post('/api/payments/verify', auth, (_req, res) => {
  res.status(503).json({
    success: false,
    status: 'unavailable',
    invoiceId: null,
    outstandingAmount: null,
    message: 'بوابة الدفع غير مفعّلة',
  });
});

/* ================================================================== */
/* Stats / Notifications                                                */
/* ================================================================== */

app.get('/api/stats/user/:userId', auth, async (req, res) => {
  if (req.user.role !== 'admin' && !sameId(req.params.userId, req.user.id)) {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !hasPermission(req.user, 'users.read')) {
    return safeError(res, 403, 'لا تملك صلاحية عرض المستخدمين');
  }
  const uid = req.user.role === 'admin' ? Number(req.params.userId) : Number(req.user.id);
  const list = await bookingsByUser(uid);
  const notifs = await notificationsByUser(uid);
  const now = new Date();
  res.json({
    upcomingBookings: list.filter((b) => b.status === 'approved' && new Date(b.startTime) > now).length,
    pendingBookings: list.filter((b) => b.status === 'pending').length,
    unreadNotifications: notifs.filter((n) => !n.isRead).length,
    totalHoursBooked: list.filter((b) => b.status === 'approved').reduce((s, b) => s + (b.hours || 0), 0),
  });
});

app.get('/api/notifications/me', auth, async (req, res) => {
  const list = (await notificationsByUser(Number(req.user.id)))
    .filter((n) => !String(n.title || '').startsWith('__'))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .map((n) => ({ id: n.id, title: n.title, message: n.message, isRead: n.isRead, createdAt: n.createdAt }));
  res.json(paged(list, req.query.page, req.query.limit));
});

app.get('/api/notifications/:userId', auth, async (req, res) => {
  if (req.user.role !== 'admin' && !sameId(req.params.userId, req.user.id)) {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !hasPermission(req.user, 'users.read')) {
    return safeError(res, 403, 'لا تملك صلاحية عرض المستخدمين');
  }
  const uid = req.user.role === 'admin' ? Number(req.params.userId) : Number(req.user.id);
  const list = (await notificationsByUser(uid))
    .filter((n) => !String(n.title || '').startsWith('__'))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .map((n) => ({ id: n.id, title: n.title, message: n.message, isRead: n.isRead, createdAt: n.createdAt }));
  res.json(paged(list, req.query.page, req.query.limit));
});

app.post('/api/notifications/:id/read', auth, async (req, res) => {
  const n = await store.findById('notifications', req.params.id);
  if (!n) return safeError(res, 404, 'الإشعار غير موجود');
  if (!sameId(n.userId, req.user.id) && req.user.role !== 'admin') {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !sameId(n.userId, req.user.id)
    && !hasPermission(req.user, 'users.manage')) {
    return safeError(res, 403, 'لا تملك صلاحية إدارة المستخدمين');
  }
  await store.update('notifications', n.id, { isRead: true });
  res.json({ ok: true });
});

app.post('/api/notifications/user/:userId/read-all', auth, async (req, res) => {
  if (req.user.role !== 'admin' && !sameId(req.params.userId, req.user.id)) {
    return safeError(res, 403, 'غير مصرح');
  }
  if (req.user.role === 'admin' && !sameId(req.params.userId, req.user.id)
    && !hasPermission(req.user, 'users.manage')) {
    return safeError(res, 403, 'لا تملك صلاحية إدارة المستخدمين');
  }
  const uid = req.user.role === 'admin' ? Number(req.params.userId) : Number(req.user.id);
  const list = await notificationsByUser(uid);
  for (const n of list) await store.update('notifications', n.id, { isRead: true });
  res.json({ ok: true });
});

/* ================================================================== */
/* FCM token + Wallet                                                   */
/* ================================================================== */

app.post('/api/users/update-token', auth, async (req, res) => {
  const token = String(req.body?.token || req.body?.fcmToken || '').trim();
  if (!token) return safeError(res, 400, 'رمز الإشعار مطلوب');
  await store.update('users', req.user.id, {
    fcmToken: token,
    fcmUpdatedAt: new Date().toISOString(),
  });
  res.json({ ok: true });
});

app.get('/api/owner/wallet/status', auth, requireOwnerOrAdminPermission('finance.read'), async (req, res) => {
  const detail = await walletDetailDto(authedOwnerId(req));
  if (!detail) return safeError(res, 404, 'غير موجود');
  res.json({
    ownerId: detail.ownerId,
    balance: detail.balance,
    status: detail.status,
    message: detail.status === 'blocked' ? 'المحفظة موقوفة' : null,
  });
});

app.get('/api/owner/wallet', auth, requireOwnerOrAdminPermission('finance.read'), async (req, res) => {
  const detail = await walletDetailDto(authedOwnerId(req));
  if (!detail) return safeError(res, 404, 'غير موجود');
  res.json(detail);
});

/* ================================================================== */
/* Admin                                                                */
/* ================================================================== */

app.get('/api/admin/stats', auth, requireAdminPermission('dashboard.read'), async (_req, res) => {
  const users = await store.find('users');
  const fields = await allFields({ includeInactive: true });
  const bookings = await store.find('bookings');
  const owners = users.filter((u) => u.role === 'owner');
  const approved = bookings.filter((b) => b.status === 'approved');
  const paid = bookings.filter((b) => b.paymentStatus === 'paid');
  const totalRevenueIqd = approved.reduce((s, b) => s + (Number(b.totalPrice) || 0), 0);
  const realizedRevenueIqd = paid.reduce((s, b) => s + (Number(b.totalPrice) || 0), 0);
  res.json({
    totalUsers: users.filter((u) => u.role === 'user').length,
    totalOwners: owners.length,
    totalFields: fields.length,
    totalBookings: bookings.length,
    paidBookings: paid.length,
    totalRevenueIqd,
    expectedRevenueIqd: totalRevenueIqd,
    realizedRevenueIqd,
    platformCommissionIqd: Math.round(totalRevenueIqd * COMMISSION_RATE),
    realizedPlatformCommissionIqd: Math.round(realizedRevenueIqd * COMMISSION_RATE),
  });
});

app.get('/api/admin/financials', auth, requireAdminPermission('finance.read'), async (_req, res) => {
  const bookings = await store.find('bookings');
  const approved = bookings.filter((b) => b.status === 'approved');
  const paid = bookings.filter((b) => b.paymentStatus === 'paid');
  const totalRevenueIqd = approved.reduce((s, b) => s + (Number(b.totalPrice) || 0), 0);
  const realizedRevenueIqd = paid.reduce((s, b) => s + (Number(b.totalPrice) || 0), 0);
  res.json({
    paidBookings: paid.length,
    totalRevenueIqd,
    expectedRevenueIqd: totalRevenueIqd,
    realizedRevenueIqd,
    outstandingRevenueIqd: Math.max(0, totalRevenueIqd - realizedRevenueIqd),
    platformCommissionIqd: Math.round(totalRevenueIqd * COMMISSION_RATE),
    realizedPlatformCommissionIqd: Math.round(realizedRevenueIqd * COMMISSION_RATE),
  });
});

app.get('/api/admin/owners', auth, requireAdminPermission('users.read'), async (_req, res) => {
  const users = await store.find('users');
  const fields = await allFields({ includeInactive: true });
  const owners = [];
  for (const o of users.filter((u) => u.role === 'owner')) {
    const wallet = await walletDetailDto(o.id);
    owners.push({
      id: Number(o.id),
      name: o.name,
      email: o.email,
      phone: o.phone || '',
      fieldCount: fields.filter((f) => sameId(f.ownerId, o.id)).length,
      walletBalance: wallet?.balance ?? 0,
      walletStatus: wallet?.status || 'active',
    });
  }
  res.json(owners);
});

app.get('/api/admin/owners/:ownerId', auth, requireAdminPermission('users.read'), async (req, res) => {
  const ownerId = Number(req.params.ownerId);
  const owner = await store.findById('users', ownerId);
  if (!owner || owner.role !== 'owner') return safeError(res, 404, 'المالك غير موجود');
  const dash = await buildOwnerDashboard(ownerId);
  const wallet = await walletDetailDto(ownerId);
  const payments = {
    outstandingAmount: dash.appCommission,
    totalPaid: Math.max(0, dash.totalRevenue - dash.appCommission),
  };
  res.json({
    owner: {
      id: Number(owner.id),
      name: owner.name,
      email: owner.email,
      phone: owner.phone || '',
      province: owner.province || 'نينوى',
    },
    dashboard: dash,
    wallet,
    payments,
  });
});

app.get('/api/admin/owners/:ownerId/wallet', auth, requireAdminPermission('finance.read'), async (req, res) => {
  const ownerId = Number(req.params.ownerId);
  const owner = await store.findById('users', ownerId);
  if (!owner || owner.role !== 'owner') return safeError(res, 404, 'المالك غير موجود');
  const detail = await walletDetailDto(ownerId);
  res.json(detail);
});

app.patch('/api/admin/owners/:ownerId/wallet-status', auth, requireAdminPermission('finance.manage'), async (req, res) => {
  const ownerId = Number(req.params.ownerId);
  const owner = await store.findById('users', ownerId);
  if (!owner || owner.role !== 'owner') return safeError(res, 404, 'المالك غير موجود');
  const status = String(req.body?.status || '').toLowerCase() === 'blocked' ? 'blocked' : 'active';
  await store.update('users', ownerId, { walletStatus: status });
  const detail = await walletDetailDto(ownerId);
  res.json(detail);
});

app.get('/api/admin/users', auth, requireAdminPermission('users.read'), async (req, res) => {
  const role = String(req.query.role || '').trim().toLowerCase();
  const q = String(req.query.q || '').trim().toLowerCase();
  let users = await store.find('users');
  if (role === 'user' || role === 'owner' || role === 'admin') {
    users = users.filter((u) => u.role === role);
  }
  if (q) {
    users = users.filter((u) => {
      const hay = `${u.name || ''} ${u.email || ''} ${u.phone || ''}`.toLowerCase();
      return hay.includes(q);
    });
  }
  const items = users
    .sort((a, b) => Number(b.id) - Number(a.id))
    .map((u) => ({
      id: Number(u.id),
      name: u.name,
      email: u.email,
      phone: u.phone || '',
      province: u.province || 'نينوى',
      role: u.role,
      loyaltyPoints: u.loyaltyPoints || 0,
    }));
  res.json(paged(items, req.query.page, req.query.limit));
});

app.get('/api/admin/users/:userId', auth, requireAdminPermission('users.read'), async (req, res) => {
  const user = await store.findById('users', req.params.userId);
  if (!user) return safeError(res, 404, 'المستخدم غير موجود');
  const stats = await bookingsByUser(user.id);
  const now = new Date();
  res.json({
    user: publicUser(user),
    stats: {
      upcomingBookings: stats.filter((b) => b.status === 'approved' && new Date(b.startTime) > now).length,
      pendingBookings: stats.filter((b) => b.status === 'pending').length,
      totalBookings: stats.length,
      totalHoursBooked: stats.filter((b) => b.status === 'approved').reduce((s, b) => s + (b.hours || 0), 0),
    },
  });
});

app.get('/api/admin/bookings', auth, requireAdminPermission('bookings.read'), async (req, res) => {
  const items = await adminBackend.hydratedBookings(req.query);
  res.json(adminBackend.paginate(items, req.query));
});

app.get('/api/admin/bookings/pending', auth, requireAdminPermission('bookings.read'), async (_req, res) => {
  const bookings = (await store.find('bookings')).filter((b) => b.status === 'pending');
  const items = [];
  for (const b of bookings) {
    const user = await store.findById('users', b.userId);
    const field = await store.findById('fields', b.fieldId);
    items.push({
      id: Number(b.id),
      fieldName: field?.name || b.fieldName || '',
      userName: user?.name || '',
      startTime: b.startTime,
      hours: b.hours,
      totalPrice: b.totalPrice,
      status: b.status,
    });
  }
  res.json(items);
});

app.get('/api/admin/fields', auth, requireAdminPermission('fields.read'), async (_req, res) => {
  const fields = await allFields({ includeInactive: true });
  const items = [];
  for (const f of fields) {
    const owner = await store.findById('users', f.ownerId);
    items.push({
      id: publicNumericId(f),
      name: f.name,
      address: f.address || '',
      ownerId: Number(f.ownerId) || 0,
      ownerName: owner?.name || '',
      isActive: f.isActive !== false,
    });
  }
  res.json(items);
});

app.patch('/api/admin/fields/:id/toggle', auth, requireAdminPermission('fields.manage'), async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f || f.id == null) return safeError(res, 404, 'الملعب غير موجود');
  const isActive = f.isActive === false;
  const updated = await store.update('fields', f.id, { isActive });
  adminBackend.publish('admin:field.toggled', {
    fieldId: publicNumericId(f),
    isActive,
    fieldName: updated?.name || f.name,
    actorId: Number(req.user.id),
  });
  if (!isActive) {
    await adminBackend.createAlert({
      type: 'field',
      severity: 'warning',
      title: 'تم تعطيل ملعب',
      message: `${updated?.name || f.name} غير متاح للحجوزات`,
      actionUrl: '/fields',
      entityType: 'field',
      entityId: publicNumericId(f),
      dedupeKey: `field:${publicNumericId(f)}:inactive`,
      data: { fieldId: publicNumericId(f), isActive: false },
    });
  } else {
    await adminBackend.closeEntityAlerts(
      'field', publicNumericId(f), 'resolved', 'field_reactivated', 'field',
    );
  }
  res.json({ isActive });
});

app.post('/api/admin/wallets/top-up', auth, requireAdminPermission('finance.manage'), async (req, res) => {
  const ownerId = Number(req.body?.ownerId);
  const amount = Number(req.body?.amount);
  const note = String(req.body?.note || '').trim();
  if (!Number.isFinite(ownerId) || ownerId <= 0) return safeError(res, 400, 'معرّف المالك مطلوب');
  if (!Number.isFinite(amount) || amount <= 0) return safeError(res, 400, 'المبلغ غير صالح');
  const owner = await store.findById('users', ownerId);
  if (!owner || owner.role !== 'owner') return safeError(res, 404, 'المالك غير موجود');
  await addWalletTx({
    ownerId,
    amount: Math.round(amount),
    type: 'admin_credit',
    typeLabel: 'شحن إداري',
    description: note || 'شحن رصيد من الإدارة',
    adminNote: note || null,
  });
  const detail = await walletDetailDto(ownerId);
  adminBackend.publish('admin:wallet.topped-up', {
    ownerId,
    amountIqd: Math.round(amount),
    balanceIqd: detail.balance,
    actorId: Number(req.user.id),
  });
  await adminBackend.createAlert({
    type: 'finance',
    severity: 'info',
    title: 'شحن محفظة إداري',
    message: `تم شحن ${Math.round(amount)} د.ع لمحفظة ${owner.name}`,
    actionUrl: `/owners/${ownerId}`,
    entityType: 'owner',
    entityId: ownerId,
    dedupeKey: `wallet-topup:${ownerId}:${Date.now()}`,
    data: { ownerId, amountIqd: Math.round(amount), balanceIqd: detail.balance },
  });
  res.json(detail);
});

adminBackend = setupAdminBackend({
  app,
  auth,
  getStore: () => store,
  io,
  resolveField,
  publicNumericId,
  bookingBelongsToField,
  notify,
  emitBookingUpdated,
  emitToField,
  commissionRate: COMMISSION_RATE,
  electronicPaymentsEnabled: ELECTRONIC_PAYMENTS_ENABLED,
  creditOwnerForPaidBooking,
});

/**
 * ترقية حساب موجود إلى أدمن — محمي بسر ADMIN_BOOTSTRAP_SECRET.
 * يُستخدم مرة واحدة لإنشاء أول أدمن دون الحاجة لتعديل قاعدة البيانات يدوياً.
 */
app.post('/api/admin/bootstrap', async (req, res) => {
  if (!ADMIN_BOOTSTRAP_SECRET) {
    return safeError(res, 410, 'التهيئة الإدارية غير مفعّلة — اضبط ADMIN_BOOTSTRAP_SECRET');
  }
  if (String(req.body?.secret || '') !== ADMIN_BOOTSTRAP_SECRET) {
    return safeError(res, 403, 'سر غير صحيح');
  }
  const email = String(req.body?.email || '').trim().toLowerCase();
  if (!email) return safeError(res, 400, 'البريد مطلوب');
  const user = await findUserByEmail(email);
  if (!user) return safeError(res, 404, 'المستخدم غير موجود — سجّل الحساب أولاً');
  if (user.role === 'admin') return res.json({ ok: true, message: 'الحساب أدمن مسبقاً' });
  await store.update('users', user.id, {
    role: 'admin',
    adminRole: user.adminRole || 'super_admin',
    customPermissions: user.customPermissions || [],
    deniedPermissions: user.deniedPermissions || [],
  });
  console.log(`تمت ترقية ${email} إلى أدمن عبر bootstrap`);
  res.json({ ok: true, message: 'تمت الترقية إلى أدمن' });
});

/* ================================================================== */
/* 404 / errors + Admin panel SPA                                       */
/* ================================================================== */

app.use('/api', (_req, res) => res.status(404).json({ message: 'المسار غير موجود' }));

const panelDir = path.join(__dirname, 'public', 'panel');
const panelIndex = path.join(panelDir, 'index.html');

app.get(['/panel', '/admin'], (_req, res) => {
  res.redirect(302, '/panel/');
});

app.use('/panel', express.static(panelDir, { index: 'index.html', fallthrough: true }));

app.get('/panel/*', (req, res, next) => {
  if (!fs.existsSync(panelIndex)) {
    return res.status(503).json({
      message: 'لوحة الأدمن غير مبنية — شغّل npm run build على السيرفر',
    });
  }
  // لا تIntercept ملفات الأصول
  if (path.extname(req.path)) return next();
  return res.sendFile(panelIndex);
});

app.use((_req, res) => {
  // إن وُجدت لوحة الأدمن، وجّه الجذر إليها
  if (fs.existsSync(panelIndex)) {
    return res.redirect(302, '/panel/');
  }
  return res.sendFile(path.join(__dirname, 'public', 'index.html'), (err) => {
    if (err) res.status(404).json({ message: 'غير موجود' });
  });
});

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('خطأ غير متوقع:', err);
  res.status(500).json({ message: 'خطأ في الخادم' });
});

/* ================================================================== */
/* التشغيل                                                              */
/* ================================================================== */

async function seedAdmin() {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) return;
  if (ADMIN_PASSWORD.length < MIN_PASSWORD_LENGTH) {
    console.warn('تخطي بذر الأدمن: ADMIN_PASSWORD قصيرة جداً');
    return;
  }
  const hashed = await bcrypt.hash(ADMIN_PASSWORD, 10);
  const existing = await findUserByEmail(ADMIN_EMAIL);
  if (existing) {
    await store.update('users', existing.id, {
      role: 'admin',
      adminRole: existing.adminRole || 'super_admin',
      password: hashed,
      name: existing.name || ADMIN_NAME,
    });
    console.log(`تم مزامنة حساب الأدمن: ${ADMIN_EMAIL} (role + password من Environment)`);
    return;
  }
  await store.insert('users', {
    name: ADMIN_NAME, email: ADMIN_EMAIL, password: hashed, phone: '',
    province: 'نينوى', image: null, role: 'admin', loyaltyPoints: 0,
    adminRole: 'super_admin', customPermissions: [], deniedPermissions: [],
    walletBalance: 0, walletStatus: 'active',
  });
  console.log(`تم إنشاء حساب أدمن: ${ADMIN_EMAIL}`);
}

/** إذا تطابقت بيانات الدخول مع ADMIN_EMAIL/PASSWORD من Render — أنشئ/رقِّ الأدمن فوراً */
async function ensureAdminFromEnv(email, password) {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) return null;
  if (ADMIN_PASSWORD.length < MIN_PASSWORD_LENGTH) return null;
  if (String(email).trim().toLowerCase() !== ADMIN_EMAIL) return null;
  if (String(password) !== ADMIN_PASSWORD) return null;

  const hashed = await bcrypt.hash(ADMIN_PASSWORD, 10);
  let user = await findUserByEmail(ADMIN_EMAIL);
  if (user) {
    user = await store.update('users', user.id, {
      role: 'admin',
      adminRole: user.adminRole || 'super_admin',
      password: hashed,
      name: user.name || ADMIN_NAME,
    });
  } else {
    user = await store.insert('users', {
      name: ADMIN_NAME, email: ADMIN_EMAIL, password: hashed, phone: '',
      province: 'نينوى', image: null, role: 'admin', loyaltyPoints: 0,
      adminRole: 'super_admin', customPermissions: [], deniedPermissions: [],
      walletBalance: 0, walletStatus: 'active',
    });
  }
  console.log(`تم تأكيد أدمن عبر Environment عند تسجيل الدخول: ${ADMIN_EMAIL}`);
  return user;
}

async function backfillAdminData() {
  const [users, bookings, credits] = await Promise.all([
    store.find('users'),
    store.find('bookings'),
    store.find('paymentCredits'),
  ]);
  for (const user of users) {
    if (user.role === 'admin' && !user.adminRole) {
      await store.update('users', user.id, {
        adminRole: 'admin',
        customPermissions: Array.isArray(user.customPermissions) ? user.customPermissions : [],
        deniedPermissions: Array.isArray(user.deniedPermissions) ? user.deniedPermissions : [],
      });
    }
  }

  // Ledger markers for old wallet credits prevent the new paid-credit path from crediting them twice.
  const creditKeys = new Set(credits.map((credit) => credit.idempotencyKey));
  for (const booking of bookings) {
    if (!booking.walletCredited || !booking.id) continue;
    const idempotencyKey = `booking:${booking.id}:paid:v1`;
    if (creditKeys.has(idempotencyKey)) continue;
    try {
      await store.insert('paymentCredits', {
        idempotencyKey,
        bookingId: Number(booking.id),
        ownerId: Number(booking.ownerId) || null,
        grossAmountIqd: Number(booking.totalPrice) || 0,
        commissionRate: COMMISSION_RATE,
        status: 'completed',
        legacy: true,
        createdAt: booking.createdAt || new Date().toISOString(),
        completedAt: booking.walletCreditedAt || new Date().toISOString(),
      });
      creditKeys.add(idempotencyKey);
    } catch (error) {
      if (String(error?.code) !== '11000') throw error;
    }
  }
}

async function start() {
  if (MONGODB_URI) {
    store = await createMongoStore(MONGODB_URI);
    console.log('التخزين: MongoDB');
  } else {
    store = createMemoryStore();
    console.log('التخزين: في الذاكرة (in-memory)');
  }

  // لا يوجد مسح تلقائي عند الإقلاع — حماية بيانات الإنتاج

  initFcm();
  try {
    await seedAdmin();
  } catch (e) {
    console.warn('تحذير: فشل بذر الأدمن:', e.message || e);
  }
  try {
    await backfillAdminData();
  } catch (e) {
    console.warn('تحذير: فشل ترحيل بيانات الأدمن الآمن:', e.message || e);
  }

  server.listen(PORT, () => {
    console.log(`الخادم يعمل على المنفذ ${PORT} (HTTP + Socket.io)`);
  });
}

start().catch((err) => {
  console.error('فشل بدء الخادم:', err);
  process.exit(1);
});
