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
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Server: SocketServer } = require('socket.io');

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const IS_PROD = NODE_ENV === 'production';
const MONGODB_URI = process.env.MONGODB_URI || '';
const COMMISSION_RATE = 0.10;
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

io.use((socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;
  if (!token) return next(new Error('Authentication required'));
  try {
    const payload = jwt.verify(token, EFFECTIVE_JWT_SECRET);
    socket.user = { ...payload, id: Number(payload.id) };
    if (!Number.isFinite(socket.user.id)) return next(new Error('Invalid token'));
    return next();
  } catch {
    return next(new Error('Invalid or expired token'));
  }
});

io.on('connection', (socket) => {
  const userId = Number(socket.user.id);
  registerSocket(userId, socket.id);
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

function createMemoryStore() {
  const data = {
    users: [], fields: [], bookings: [], notifications: [], reviews: [], walletTransactions: [],
  };
  const seq = {
    users: 0, fields: 0, bookings: 0, notifications: 0, reviews: 0, walletTransactions: 0,
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
  };
  const Counter = mongoose.model('Counter', new Schema({ _id: String, n: Number }));

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
    { id: Number(user.id), role: user.role, name: user.name },
    EFFECTIVE_JWT_SECRET,
    { expiresIn: '30d' },
  );
}

function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'مطلوب تسجيل الدخول' });
  try {
    const payload = jwt.verify(token, EFFECTIVE_JWT_SECRET);
    req.user = { ...payload, id: Number(payload.id) };
    if (!Number.isFinite(req.user.id)) {
      return res.status(401).json({ message: 'انتهت الجلسة' });
    }
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

function requireOwnerOrAdmin(req, res, next) {
  if (req.user?.role !== 'owner' && req.user?.role !== 'admin') {
    return res.status(403).json({ message: 'غير مصرح' });
  }
  return next();
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
    paymentMethod: b.paymentMethod || 'online',
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

async function addWalletTx({ ownerId, amount, type, typeLabel, description, bookingId, bookingReference, adminNote }) {
  const user = await ensureOwnerWallet(ownerId);
  if (!user) throw new Error('المالك غير موجود');
  const balance = Number(user.walletBalance || 0) + Number(amount);
  const status = user.walletStatus || 'active';
  await store.update('users', ownerId, { walletBalance: balance, walletStatus: status });
  const tx = await store.insert('walletTransactions', {
    ownerId: Number(ownerId),
    amount: Number(amount),
    type,
    typeLabel,
    description,
    bookingId: bookingId != null ? Number(bookingId) : null,
    bookingReference: bookingReference || null,
    adminNote: adminNote || null,
    createdAt: new Date().toISOString(),
  });
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

async function creditOwnerForApprovedBooking(booking) {
  if (!booking?.ownerId || booking.walletCredited) return;
  const total = Number(booking.totalPrice) || 0;
  const commission = Math.round(total * COMMISSION_RATE);
  if (total > 0) {
    await addWalletTx({
      ownerId: booking.ownerId,
      amount: total,
      type: 'booking_credit',
      typeLabel: 'إيراد حجز',
      description: `إيراد حجز ${booking.referenceCode || booking.id}`,
      bookingId: booking.id,
      bookingReference: booking.referenceCode,
    });
  }
  if (commission > 0) {
    await addWalletTx({
      ownerId: booking.ownerId,
      amount: -commission,
      type: 'commission_debit',
      typeLabel: 'عمولة المنصة',
      description: `عمولة 10% على حجز ${booking.referenceCode || booking.id}`,
      bookingId: booking.id,
      bookingReference: booking.referenceCode,
    });
  }
  await store.update('bookings', booking.id, { walletCredited: true });
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
  env: IS_PROD ? 'production' : 'development',
}));

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
    const user = await findUserByEmail(normEmail);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return safeError(res, 401, 'بيانات الدخول غير صحيحة');
    }
    const role = String(expectedRole || '').trim().toLowerCase();
    if (role === 'owner' && user.role !== 'owner' && user.role !== 'admin') {
      return safeError(res, 403, 'هذا حساب مستخدم — استخدم تسجيل دخول المستخدم');
    }
    if (role === 'user' && user.role === 'owner') {
      return safeError(res, 403, 'هذا حساب صاحب ملعب — استخدم تسجيل دخول أصحاب الملاعب');
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
  res.json(publicField(updated));
});

app.get('/api/fields/:id/schedule', optionalAuth, async (req, res) => {
  try {
    const f = await resolveField(req.params.id);
    if (!f || f.isActive === false) return safeError(res, 404, 'الملعب غير موجود');
    const fieldKey = f.id != null ? f.id : publicNumericId(f);
    const publicId = publicNumericId(f);
    const booked = (await bookingsByField(fieldKey)).filter((b) => b.status === 'pending' || b.status === 'approved');
    const bookedKeys = new Set(booked.map((b) => new Date(b.startTime).toISOString().slice(0, 13)));
    purgeExpiredHolds();

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const schedule = [];
    for (let d = 0; d < 7; d++) {
      const day = new Date(today.getTime() + d * 86400000);
      const slots = [];
      for (let h = 10; h <= 22; h++) {
        const start = new Date(day); start.setHours(h, 0, 0, 0);
        const end = new Date(start.getTime() + 3600000);
        const key = start.toISOString().slice(0, 13);
        const hold = getActiveHold(publicId, start.toISOString());
        const heldByOther = hold && (!req.user || Number(hold.userId) !== Number(req.user.id));
        slots.push({
          startTime: start.toISOString(),
          endTime: end.toISOString(),
          isAvailable: !bookedKeys.has(key) && !heldByOther && start > new Date(),
          status: hold ? 'held' : null,
          heldUntil: hold?.expiresAt || null,
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

  const hourlyRate = field.pricePerHour || 0;
  const totalPrice = hourlyRate * hrs;
  const method = String(paymentMethod || 'online').toLowerCase() === 'cash' ? 'cash' : 'online';
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

app.get('/api/bookings/owner/me', auth, requireOwnerOrAdmin, async (req, res) => {
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
      return res.json(await buildOwnerDashboard(Number(req.params.ownerId)));
    }
    if (req.user.role !== 'owner') return safeError(res, 403, 'غير مصرح');
    res.json(await buildOwnerDashboard(authedOwnerId(req)));
  } catch (e) {
    console.error('owner dashboard:', e);
    return safeError(res, 500, 'فشل تحميل لوحة المالك');
  }
});

app.post('/api/bookings/approve', auth, requireOwnerOrAdmin, async (req, res) => {
  const { bookingId, referenceCode } = req.body || {};
  const b = await resolveBooking(bookingId, referenceCode);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
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
  res.json({ ok: true });
});

app.post('/api/bookings/reject', auth, requireOwnerOrAdmin, async (req, res) => {
  const { bookingId, referenceCode } = req.body || {};
  const b = await resolveBooking(bookingId, referenceCode);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
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
  res.json({ ok: true });
});

/* ================================================================== */
/* Payments — تسجيل داخلي آمن (بدون بوابة خارجية وهمية)                   */
/* ================================================================== */

app.post('/api/bookings/:bookingId/pay/initiate', auth, async (req, res) => {
  purgeExpiredPayments();
  const b = await resolveBooking(req.params.bookingId);
  if (!b) return safeError(res, 404, 'الحجز غير موجود');
  if (!sameId(b.userId, req.user.id) && req.user.role !== 'admin') {
    return safeError(res, 403, 'غير مصرح');
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

  await store.update('bookings', b.id, { paymentStatus: 'paid' });
  if (token) pendingPayments.delete(token);
  res.json({
    success: true,
    status: 'paid',
    invoiceId: `INV-${b.id}`,
    outstandingAmount: 0,
    message: 'تم تأكيد الدفع',
  });
});

app.get('/api/payments/owner/me/account', auth, requireOwnerOrAdmin, async (req, res) => {
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
  if (req.user.role === 'admin') ownerId = Number(req.params.ownerId);
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
  await store.update('notifications', n.id, { isRead: true });
  res.json({ ok: true });
});

app.post('/api/notifications/user/:userId/read-all', auth, async (req, res) => {
  if (req.user.role !== 'admin' && !sameId(req.params.userId, req.user.id)) {
    return safeError(res, 403, 'غير مصرح');
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

app.get('/api/owner/wallet/status', auth, requireOwnerOrAdmin, async (req, res) => {
  const detail = await walletDetailDto(authedOwnerId(req));
  if (!detail) return safeError(res, 404, 'غير موجود');
  res.json({
    ownerId: detail.ownerId,
    balance: detail.balance,
    status: detail.status,
    message: detail.status === 'blocked' ? 'المحفظة موقوفة' : null,
  });
});

app.get('/api/owner/wallet', auth, requireOwnerOrAdmin, async (req, res) => {
  const detail = await walletDetailDto(authedOwnerId(req));
  if (!detail) return safeError(res, 404, 'غير موجود');
  res.json(detail);
});

/* ================================================================== */
/* Admin                                                                */
/* ================================================================== */

app.get('/api/admin/stats', auth, requireAdmin, async (_req, res) => {
  const users = await store.find('users');
  const fields = await allFields({ includeInactive: true });
  const bookings = await store.find('bookings');
  const owners = users.filter((u) => u.role === 'owner');
  const approved = bookings.filter((b) => b.status === 'approved');
  const paid = bookings.filter((b) => b.paymentStatus === 'paid' || b.paymentStatus === 'pay_at_venue');
  const totalRevenueIqd = approved.reduce((s, b) => s + (Number(b.totalPrice) || 0), 0);
  res.json({
    totalUsers: users.filter((u) => u.role === 'user').length,
    totalOwners: owners.length,
    totalFields: fields.length,
    totalBookings: bookings.length,
    paidBookings: paid.length,
    totalRevenueIqd,
    platformCommissionIqd: Math.round(totalRevenueIqd * COMMISSION_RATE),
  });
});

app.get('/api/admin/financials', auth, requireAdmin, async (_req, res) => {
  const bookings = await store.find('bookings');
  const approved = bookings.filter((b) => b.status === 'approved');
  const paid = bookings.filter((b) => b.paymentStatus === 'paid' || b.paymentStatus === 'pay_at_venue');
  const totalRevenueIqd = approved.reduce((s, b) => s + (Number(b.totalPrice) || 0), 0);
  res.json({
    paidBookings: paid.length,
    totalRevenueIqd,
    platformCommissionIqd: Math.round(totalRevenueIqd * COMMISSION_RATE),
  });
});

app.get('/api/admin/owners', auth, requireAdmin, async (_req, res) => {
  const users = await store.find('users');
  const fields = await allFields({ includeInactive: true });
  const owners = users.filter((u) => u.role === 'owner').map((o) => ({
    id: Number(o.id),
    name: o.name,
    email: o.email,
    phone: o.phone || '',
    fieldCount: fields.filter((f) => sameId(f.ownerId, o.id)).length,
  }));
  res.json(owners);
});

app.get('/api/admin/bookings/pending', auth, requireAdmin, async (_req, res) => {
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

app.get('/api/admin/fields', auth, requireAdmin, async (_req, res) => {
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

app.patch('/api/admin/fields/:id/toggle', auth, requireAdmin, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f || f.id == null) return safeError(res, 404, 'الملعب غير موجود');
  const isActive = f.isActive === false;
  await store.update('fields', f.id, { isActive });
  res.json({ isActive });
});

app.post('/api/admin/wallets/top-up', auth, requireAdmin, async (req, res) => {
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
  res.json(detail);
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
  await store.update('users', user.id, { role: 'admin' });
  console.log(`تمت ترقية ${email} إلى أدمن عبر bootstrap`);
  res.json({ ok: true, message: 'تمت الترقية إلى أدمن' });
});

/* ================================================================== */
/* 404 / errors                                                         */
/* ================================================================== */

app.use('/api', (_req, res) => res.status(404).json({ message: 'المسار غير موجود' }));

app.use((_req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html'), (err) => {
  if (err) res.status(404).json({ message: 'غير موجود' });
}));

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
  const existing = await findUserByEmail(ADMIN_EMAIL);
  if (existing) {
    if (existing.role !== 'admin') {
      await store.update('users', existing.id, { role: 'admin' });
      console.log(`تمت ترقية ${ADMIN_EMAIL} إلى أدمن`);
    }
    return;
  }
  const hashed = await bcrypt.hash(ADMIN_PASSWORD, 10);
  await store.insert('users', {
    name: ADMIN_NAME, email: ADMIN_EMAIL, password: hashed, phone: '',
    province: 'نينوى', image: null, role: 'admin', loyaltyPoints: 0,
    walletBalance: 0, walletStatus: 'active',
  });
  console.log(`تم إنشاء حساب أدمن: ${ADMIN_EMAIL}`);
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

  server.listen(PORT, () => {
    console.log(`الخادم يعمل على المنفذ ${PORT} (HTTP + Socket.io)`);
  });
}

start().catch((err) => {
  console.error('فشل بدء الخادم:', err);
  process.exit(1);
});
