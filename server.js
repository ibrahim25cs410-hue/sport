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

const path = require('path');
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const MONGODB_URI = process.env.MONGODB_URI || '';
const COMMISSION_RATE = 0.10; // عمولة التطبيق

const app = express();
app.set('trust proxy', 1); // خلف بروكسي Render (لعناوين IP و https الصحيحة)
app.use(cors());
app.use(express.json({ limit: '8mb' })); // صور base64
app.use(express.static(path.join(__dirname, 'public')));

if (process.env.NODE_ENV === 'production' && JWT_SECRET === 'dev-secret-change-me') {
  console.warn('⚠️  تحذير: JWT_SECRET غير مضبوط! اضبط متغيّر البيئة JWT_SECRET في Render.');
}

/* ================================================================== */
/* طبقة التخزين — بدائل CRUD عامة (نفس المنطق للذاكرة و MongoDB)        */
/* ================================================================== */

let store;

function createMemoryStore() {
  const data = { users: [], fields: [], bookings: [], notifications: [] };
  const seq = { users: 0, fields: 0, bookings: 0, notifications: 0 };
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
      return clone(data[col].find(pred) || null);
    },
    async find(col, pred) {
      return clone(pred ? data[col].filter(pred) : data[col]);
    },
    async update(col, id, patch) {
      const rec = data[col].find((r) => r.id === Number(id));
      if (!rec) return null;
      Object.assign(rec, patch);
      return clone(rec);
    },
    async deleteAll(col) {
      const n = data[col].length;
      data[col] = [];
      return n;
    },
  };
}

async function createMongoStore(uri) {
  const mongoose = require('mongoose');
  await mongoose.connect(uri);
  const { Schema } = mongoose;

  const models = {
    users: mongoose.model('User', new Schema({}, { strict: false, timestamps: true })),
    fields: mongoose.model('Field', new Schema({}, { strict: false, timestamps: true })),
    bookings: mongoose.model('Booking', new Schema({}, { strict: false, timestamps: true })),
    notifications: mongoose.model('Notification', new Schema({}, { strict: false, timestamps: true })),
  };
  const Counter = mongoose.model('Counter', new Schema({ _id: String, n: Number }));

  async function nextId(col) {
    const c = await Counter.findByIdAndUpdate(col, { $inc: { n: 1 } }, { new: true, upsert: true });
    return c.n;
  }
  const out = (doc) => {
    if (!doc) return null;
    const o = doc.toObject ? doc.toObject() : doc;
    delete o._id; delete o.__v; delete o.createdAt; delete o.updatedAt;
    return o;
  };

  return {
    kind: 'mongodb',
    async insert(col, doc) {
      const id = await nextId(col);
      return out(await models[col].create({ id, ...doc }));
    },
    async findById(col, id) {
      return out(await models[col].findOne({ id: Number(id) }));
    },
    async findOne(col, query) {
      return out(await models[col].findOne(query));
    },
    async find(col, query) {
      return (await models[col].find(query || {})).map(out);
    },
    async update(col, id, patch) {
      return out(await models[col].findOneAndUpdate({ id: Number(id) }, patch, { new: true }));
    },
    async deleteAll(col) {
      const result = await models[col].deleteMany({});
      return result.deletedCount || 0;
    },
  };
}

// طبقة موحّدة: دوال تصفية للذاكرة وكائنات استعلام للـ Mongo.
const isMongo = () => store.kind === 'mongodb';

async function findUserByEmail(email) {
  const norm = String(email || '').trim().toLowerCase();
  if (!norm) return null;
  // مطابقة حرفية كاملة فقط — ibrahem@gmail.com ≠ ibrah2007@gmail.com
  return isMongo()
    ? store.findOne('users', { email: norm })
    : store.findOne('users', (u) => String(u.email || '').trim().toLowerCase() === norm);
}
async function fieldsByOwner(ownerId) {
  const all = await store.find('fields');
  return all.filter((f) => sameId(f.ownerId, ownerId));
}
async function bookingsByUser(userId) {
  const all = await store.find('bookings');
  return all.filter((b) => sameId(b.userId, userId));
}
async function bookingsByOwner(ownerId) {
  const all = await store.find('bookings');
  return all.filter((b) => sameId(b.ownerId, ownerId));
}
async function bookingsByField(fieldId) {
  const all = await store.find('bookings');
  return all.filter((b) => sameId(b.fieldId, fieldId));
}
async function notificationsByUser(userId) {
  const all = await store.find('notifications');
  return all.filter((n) => sameId(n.userId, userId));
}
async function allFields() {
  return store.find('fields');
}

/* ================================================================== */
/* أدوات المصادقة                                                      */
/* ================================================================== */

function sign(user) {
  return jwt.sign({ id: Number(user.id), role: user.role, name: user.name }, JWT_SECRET, { expiresIn: '30d' });
}
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'مطلوب تسجيل الدخول' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = { ...payload, id: Number(payload.id) };
    if (!Number.isFinite(req.user.id)) {
      return res.status(401).json({ message: 'انتهت الجلسة' });
    }
    next();
  } catch {
    return res.status(401).json({ message: 'انتهت الجلسة' });
  }
}
function optionalAuth(req, _res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (token) {
    try {
      const payload = jwt.verify(token, JWT_SECRET);
      req.user = { ...payload, id: Number(payload.id) };
    } catch { /* تجاهل */ }
  }
  next();
}

/* ================================================================== */
/* أدوات التسلسل (DTO)                                                 */
/* ================================================================== */

const publicUser = (u) => ({
  id: Number(u.id), name: u.name, email: u.email, phone: u.phone || '',
  province: u.province || 'نينوى', image: u.image || null,
  role: u.role, loyaltyPoints: u.loyaltyPoints || 0,
});

/** نفس خوارزمية Field._stableId في Flutter (seed: name|phone|address). */
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
});

/** إيجاد ملعب بالمعرّف الحقيقي أو هاش Flutter الاحتياطي. */
async function resolveField(publicId) {
  const n = Number(publicId);
  if (!Number.isFinite(n) || n <= 0) return null;
  const byId = await store.findById('fields', n);
  if (byId) return byId;
  const all = await allFields();
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

/** معرّف المالك من التوكن — يتجاهل أي id خاطئ من التطبيق. */
function authedOwnerId(req) {
  return Number(req.user.id);
}

function endTimeOf(startIso, hours) {
  return new Date(new Date(startIso).getTime() + (hours || 1) * 3600 * 1000).toISOString();
}

function userBookingDto(b, field) {
  return {
    id: b.id,
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

function ownerBookingDto(b, user) {
  return {
    id: b.id,
    referenceCode: b.referenceCode || null,
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
  return {
    items,
    page: Number(page) || 1,
    limit: Number(limit) || items.length,
    totalCount: items.length,
    hasNextPage: false,
  };
}

async function notify(userId, title, message) {
  await store.insert('notifications', {
    userId: Number(userId), title, message, isRead: false, createdAt: new Date().toISOString(),
  });
}

/* ================================================================== */
/* المسارات — Auth                                                     */
/* ================================================================== */

app.get('/api/health', (_req, res) => res.json({ status: 'ok', storage: store.kind }));

app.post('/api/register-user', async (req, res) => {
  try {
    const { name, email, password, phone, province, image } = req.body || {};
    if (!name || !email || !password) return res.status(400).json({ message: 'الاسم والبريد وكلمة المرور مطلوبة' });
    const normEmail = String(email).trim().toLowerCase();
    if (await findUserByEmail(normEmail)) return res.status(409).json({ message: 'البريد مستخدم مسبقاً' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await store.insert('users', {
      name, email: normEmail, password: hashed, phone: phone || '', province: province || 'نينوى',
      image: image || null, role: 'user', loyaltyPoints: 0,
    });
    res.status(201).json({ token: sign(user), user: publicUser(user) });
  } catch (e) { res.status(500).json({ message: 'خطأ في الخادم', error: String(e) }); }
});

app.post('/api/register-owner', async (req, res) => {
  try {
    const { name, email, password, phone, stadiumName, stadiumAddress, stadiumPhone, pricePerHour, stadiumImage } = req.body || {};
    if (!name || !email || !password || !stadiumName) return res.status(400).json({ message: 'بيانات ناقصة' });
    const normEmail = String(email).trim().toLowerCase();
    if (await findUserByEmail(normEmail)) return res.status(409).json({ message: 'البريد مستخدم مسبقاً' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await store.insert('users', {
      name, email: normEmail, password: hashed, phone: phone || '', province: 'نينوى',
      image: null, role: 'owner', loyaltyPoints: 0,
    });
    const field = await store.insert('fields', {
      name: stadiumName, address: stadiumAddress || '', phone: stadiumPhone || phone || '',
      image: stadiumImage || null, pricePerHour: Number(pricePerHour) || 0, ownerId: Number(user.id),
      averageRating: 0, reviewCount: 0, latitude: null, longitude: null,
    });
    res.status(201).json({ token: sign(user), user: publicUser(user), field: publicField(field) });
  } catch (e) { res.status(500).json({ message: 'خطأ في الخادم', error: String(e) }); }
});

app.post('/api/login', async (req, res) => {
  try {
    const { email, password, expectedRole } = req.body || {};
    if (!email || !password) return res.status(400).json({ message: 'البريد وكلمة المرور مطلوبة' });
    const normEmail = String(email).trim().toLowerCase();
    const user = await findUserByEmail(normEmail);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'بيانات الدخول غير صحيحة' });
    }
    const role = String(expectedRole || '').trim().toLowerCase();
    if (role === 'owner' && user.role !== 'owner' && user.role !== 'admin') {
      return res.status(403).json({ message: 'هذا حساب مستخدم — استخدم تسجيل دخول المستخدم' });
    }
    if (role === 'user' && user.role === 'owner') {
      return res.status(403).json({ message: 'هذا حساب صاحب ملعب — استخدم تسجيل دخول أصحاب الملاعب' });
    }
    const body = { token: sign(user), user: publicUser(user) };
    if (user.role === 'owner') {
      const owned = await fieldsByOwner(user.id);
      if (owned[0]) body.field = publicField(owned[0]);
    }
    res.json(body);
  } catch (e) { res.status(500).json({ message: 'خطأ في الخادم', error: String(e) }); }
});

app.get('/api/me', auth, async (req, res) => {
  const user = await store.findById('users', req.user.id);
  if (!user) return res.status(404).json({ message: 'غير موجود' });
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
  if (password) patch.password = await bcrypt.hash(password, 10);
  const updated = await store.update('users', req.user.id, patch);
  res.json(publicUser(updated));
});

/* ================================================================== */
/* المسارات — Fields                                                   */
/* ================================================================== */

app.get('/api/fields', optionalAuth, async (req, res) => {
  const list = (await allFields()).map(publicField);
  res.json(paged(list, req.query.page, req.query.limit));
});

/** حذف كل الملاعب (طلب صريح من الإدارة) — يحتاج تأكيد في الجسم. */
app.post('/api/admin/clear-fields', auth, async (req, res) => {
  try {
    if (req.body?.confirm !== 'DELETE_ALL_FIELDS') {
      return res.status(400).json({ message: 'أرسل confirm: DELETE_ALL_FIELDS' });
    }
    const deleted = await store.deleteAll('fields');
    // الحجوزات القديمة تبقى لكن بدون ملاعب ظاهرة
    return res.json({ ok: true, deleted });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'فشل حذف الملاعب' });
  }
});

app.get('/api/fields/:id', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f) return res.status(404).json({ message: 'الملعب غير موجود' });
  res.json(publicField(f));
});

app.put('/api/fields/:id', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  if (!f) return res.status(404).json({ message: 'الملعب غير موجود' });
  if (!sameId(f.ownerId, req.user.id)) return res.status(403).json({ message: 'غير مصرح' });
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

// جدول المواعيد: 7 أيام × ساعات 10:00–23:00 مع علامة التوفر
app.get('/api/fields/:id/schedule', auth, async (req, res) => {
  try {
    const f = await resolveField(req.params.id);
    if (!f) return res.status(404).json({ message: 'الملعب غير موجود' });
    const fieldKey = f.id != null ? f.id : publicNumericId(f);
    const booked = (await bookingsByField(fieldKey)).filter((b) => b.status === 'pending' || b.status === 'approved');
    const bookedKeys = new Set(booked.map((b) => new Date(b.startTime).toISOString().slice(0, 13)));

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
        slots.push({
          startTime: start.toISOString(),
          endTime: end.toISOString(),
          isAvailable: !bookedKeys.has(key) && start > new Date(),
          status: null,
          heldUntil: null,
        });
      }
      schedule.push({ date: day.toISOString(), slots });
    }
    res.json({
      id: publicNumericId(f),
      name: f.name,
      pricePerHour: f.pricePerHour || 0,
      schedule,
    });
  } catch (e) {
    console.error('schedule error:', e);
    return res.status(500).json({ message: 'فشل تحميل جدول المواعيد' });
  }
});

// التقييمات (مبسّطة)
app.get('/api/fields/:id/review-eligibility', auth, async (req, res) => {
  const f = await resolveField(req.params.id);
  res.json({ canReview: false, hasBooked: false, userRating: null, averageRating: f?.averageRating || 0, reviewCount: f?.reviewCount || 0 });
});
app.get('/api/fields/:id/reviews', auth, (_req, res) => res.json([]));
app.post('/api/fields/:id/reviews', auth, (_req, res) => res.json({ ok: true }));

/* ================================================================== */
/* المسارات — Slots (حجز تنافسي مبسّط)                                 */
/* ================================================================== */

app.post('/api/slots/select', auth, (_req, res) => {
  res.json({ expiresAt: new Date(Date.now() + 5 * 60 * 1000).toISOString() });
});
app.post('/api/slots/release', auth, (_req, res) => res.json({ ok: true }));

/* ================================================================== */
/* المسارات — Bookings                                                 */
/* ================================================================== */

app.post('/api/bookings', auth, async (req, res) => {
  const { fieldId, startTime, hours, paymentMethod } = req.body || {};
  if (!fieldId || !startTime) return res.status(400).json({ message: 'الملعب ووقت البدء مطلوبان' });
  const field = await resolveField(fieldId);
  if (!field) return res.status(404).json({ message: 'الملعب غير موجود' });

  const hrs = Number(hours) || 1;
  const start = new Date(startTime).toISOString();
  const resolvedFieldId = publicNumericId(field);

  // منع التعارض على نفس الساعة
  const existing = (await bookingsByField(field.id != null ? field.id : resolvedFieldId))
    .filter((b) => b.status === 'pending' || b.status === 'approved');
  const clash = existing.some((b) => new Date(b.startTime).toISOString().slice(0, 13) === start.slice(0, 13));
  if (clash) return res.status(409).json({ code: 'ConflictError', messageKey: 'slotJustBooked' });

  const hourlyRate = field.pricePerHour || 0;
  const totalPrice = hourlyRate * hrs;
  const method = String(paymentMethod || 'online').toLowerCase() === 'cash' ? 'cash' : 'online';
  // نقداً: لا دفع إلكتروني — الحجز بانتظار موافقة المالك والدفع في الملعب
  const paymentStatus = method === 'cash' ? 'pay_at_venue' : 'unpaid';
  const booking = await store.insert('bookings', {
    fieldId: field.id != null ? field.id : resolvedFieldId,
    ownerId: Number(field.ownerId) || 0,
    userId: Number(req.user.id),
    startTime: start, hours: hrs, totalPrice, status: 'pending',
    paymentStatus,
    paymentMethod: method,
    referenceCode: 'REF-' + Date.now().toString().slice(-6),
    createdAt: new Date().toISOString(),
  });
  await notify(
    field.ownerId,
    'طلب حجز جديد',
    method === 'cash'
      ? `طلب حجز نقدي على ${field.name} — بانتظار موافقتك`
      : `طلب حجز على ${field.name}`,
  );

  res.status(201).json({
    id: booking.id,
    referenceCode: booking.referenceCode,
    paymentStatus: booking.paymentStatus,
    paymentMethod: booking.paymentMethod,
    totalPrice: booking.totalPrice,
    discountAmount: 0,
    isDiscountApplied: false,
    hourlyRate,
    loyaltyPoints: 0,
  });
});

app.get('/api/bookings/user/:userId', auth, async (req, res) => {
  const list = await bookingsByUser(req.params.userId);
  const active = list.filter((b) => b.status === 'pending' || b.status === 'approved');
  const fieldsCache = {};
  const items = [];
  for (const b of active.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
    fieldsCache[b.fieldId] ??= await store.findById('fields', b.fieldId);
    items.push(userBookingDto(b, fieldsCache[b.fieldId]));
  }
  res.json(paged(items, req.query.page, req.query.limit));
});

app.get('/api/bookings/user/:userId/history', auth, async (req, res) => {
  const list = await bookingsByUser(req.params.userId);
  const fieldsCache = {};
  const items = [];
  for (const b of list.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
    fieldsCache[b.fieldId] ??= await store.findById('fields', b.fieldId);
    items.push(userBookingDto(b, fieldsCache[b.fieldId]));
  }
  res.json(paged(items, req.query.page, req.query.limit));
});

app.post('/api/bookings/cancel', auth, async (req, res) => {
  const { bookingId } = req.body || {};
  const b = await store.findById('bookings', bookingId);
  if (!b) return res.status(404).json({ message: 'الحجز غير موجود' });
  if (!sameId(b.userId, req.user.id)) return res.status(403).json({ message: 'غير مصرح' });
  await store.update('bookings', bookingId, { status: 'cancelled' });
  await notify(b.ownerId, 'إلغاء حجز', 'قام المستخدم بإلغاء حجز');
  res.json({ message: 'تم الإلغاء', tier: 'free', penaltyIqd: 0, ownerShareIqd: 0, platformShareIqd: 0 });
});

async function buildOwnerDashboard(ownerId) {
  const owned = await fieldsByOwner(ownerId);
  const field = owned[0] || null;
  const list = await bookingsByOwner(ownerId);
  const usersCache = {};
  const bookings = [];
  let totalRevenue = 0;
  let pendingCount = 0;
  for (const b of list.sort((a, c) => new Date(c.startTime) - new Date(a.startTime))) {
    try {
      usersCache[b.userId] ??= await store.findById('users', b.userId);
      bookings.push(ownerBookingDto(b, usersCache[b.userId]));
      if (b.status === 'approved') totalRevenue += Number(b.totalPrice) || 0;
      if (b.status === 'pending') pendingCount++;
    } catch (e) {
      console.error('تخطي حجز تالف في لوحة المالك:', e.message || e);
    }
  }
  const appCommission = Math.round(totalRevenue * COMMISSION_RATE);
  return {
    field: field ? publicField(field) : null,
    bookings,
    totalRevenue,
    appCommission,
    netRevenue: totalRevenue - appCommission,
    pendingCount,
  };
}

app.get('/api/bookings/owner/me', auth, async (req, res) => {
  try {
    res.json(await buildOwnerDashboard(authedOwnerId(req)));
  } catch (e) {
    console.error('owner/me dashboard:', e);
    res.status(500).json({ message: 'فشل تحميل لوحة المالك' });
  }
});

app.get('/api/bookings/owner/:ownerId', auth, async (req, res) => {
  try {
    // المالك دائماً يرى لوحته من التوكن (يتجنب mismatch معرّف التطبيق)
    if (req.user.role === 'admin') {
      return res.json(await buildOwnerDashboard(Number(req.params.ownerId)));
    }
    if (req.user.role !== 'owner') {
      return res.status(403).json({ message: 'غير مصرح' });
    }
    res.json(await buildOwnerDashboard(authedOwnerId(req)));
  } catch (e) {
    console.error('owner dashboard:', e);
    res.status(500).json({
      field: null,
      bookings: [],
      totalRevenue: 0,
      appCommission: 0,
      netRevenue: 0,
      pendingCount: 0,
      message: 'فشل تحميل لوحة المالك',
    });
  }
});

app.post('/api/bookings/approve', auth, async (req, res) => {
  const { bookingId } = req.body || {};
  const b = await store.findById('bookings', bookingId);
  if (!b) return res.status(404).json({ message: 'الحجز غير موجود' });
  if (!sameId(b.ownerId, req.user.id)) return res.status(403).json({ message: 'غير مصرح' });
  await store.update('bookings', bookingId, { status: 'approved' });
  await notify(
    b.userId,
    'تمت الموافقة على حجزك',
    b.referenceCode
      ? `تمت الموافقة على حجزك — الرقم المرجعي: ${b.referenceCode}`
      : 'تمت الموافقة على حجزك — يمكنك مراجعته من قائمة الحجوزات',
  );
  res.json({ ok: true });
});

app.post('/api/bookings/reject', auth, async (req, res) => {
  const { bookingId } = req.body || {};
  const b = await store.findById('bookings', bookingId);
  if (!b) return res.status(404).json({ message: 'الحجز غير موجود' });
  if (!sameId(b.ownerId, req.user.id)) return res.status(403).json({ message: 'غير مصرح' });
  await store.update('bookings', bookingId, { status: 'rejected' });
  await notify(b.userId, 'تم الرفض', 'عذراً، تم رفض حجزك');
  res.json({ ok: true });
});

// دفع مبسّط (اختياري)
app.post('/api/bookings/:bookingId/pay/initiate', auth, (req, res) => {
  res.json({ transactionToken: 'demo-' + req.params.bookingId, gateway: req.body?.gateway || 'card', amount: 0, checkoutUrl: null });
});
app.post('/api/bookings/pay/verify', auth, (_req, res) => {
  res.json({ success: true, status: 'paid', invoiceId: null, outstandingAmount: 0, message: 'تم' });
});

/* ================================================================== */
/* المسارات — Stats / Notifications                                    */
/* ================================================================== */

app.get('/api/stats/user/:userId', auth, async (req, res) => {
  const list = await bookingsByUser(req.params.userId);
  const notifs = await notificationsByUser(req.params.userId);
  const now = new Date();
  res.json({
    upcomingBookings: list.filter((b) => b.status === 'approved' && new Date(b.startTime) > now).length,
    pendingBookings: list.filter((b) => b.status === 'pending').length,
    unreadNotifications: notifs.filter((n) => !n.isRead).length,
    totalHoursBooked: list.filter((b) => b.status === 'approved').reduce((s, b) => s + (b.hours || 0), 0),
  });
});

app.get('/api/notifications/:userId', auth, async (req, res) => {
  const list = (await notificationsByUser(req.params.userId))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .map((n) => ({ id: n.id, title: n.title, message: n.message, isRead: n.isRead, createdAt: n.createdAt }));
  res.json(paged(list, req.query.page, req.query.limit));
});
app.post('/api/notifications/:id/read', auth, async (req, res) => {
  await store.update('notifications', req.params.id, { isRead: true });
  res.json({ ok: true });
});
app.post('/api/notifications/user/:userId/read-all', auth, async (req, res) => {
  const list = await notificationsByUser(req.params.userId);
  for (const n of list) await store.update('notifications', n.id, { isRead: true });
  res.json({ ok: true });
});

/* ================================================================== */
/* المسارات — أخرى (stubs تمنع أعطال الشاشات الثانوية)                 */
/* ================================================================== */

app.post('/api/users/update-token', auth, (_req, res) => res.json({ ok: true }));

app.get('/api/owner/wallet/status', auth, (req, res) => {
  res.json({ ownerId: authedOwnerId(req), balance: 0, status: 'active', message: null });
});
app.get('/api/owner/wallet', auth, (req, res) => {
  const ownerId = authedOwnerId(req);
  res.json({
    walletId: ownerId,
    ownerId,
    balance: 0,
    status: 'active',
    lastUpdated: new Date().toISOString(),
    transactions: [],
  });
});

// حساب عمولات المالك (stub حتى لا تنهار شاشات الدفع)
function ownerPaymentAccountDto() {
  return {
    outstandingAmount: 0,
    outstandingHours: 0,
    totalPaid: 0,
    pendingInvoices: [],
    paidInvoices: [],
    recentPayments: [],
  };
}
app.get('/api/payments/owner/me/account', auth, (req, res) => {
  if (req.user.role !== 'owner' && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'غير مصرح' });
  }
  res.json(ownerPaymentAccountDto());
});
app.get('/api/payments/owner/:ownerId/account', auth, (req, res) => {
  if (req.user.role === 'admin') return res.json(ownerPaymentAccountDto());
  if (req.user.role !== 'owner') return res.status(403).json({ message: 'غير مصرح' });
  // ثقة بالتوكن — حتى لو معرّف المسار لا يطابق كاش التطبيق
  res.json(ownerPaymentAccountDto());
});
app.post('/api/payments/initiate', auth, (req, res) => {
  res.json({
    transactionToken: 'demo-' + Date.now(),
    gateway: req.body?.gateway || 'card',
    amount: Number(req.body?.amount) || 0,
    checkoutUrl: null,
  });
});
app.post('/api/payments/verify', auth, (_req, res) => {
  res.json({
    success: true,
    status: 'paid',
    invoiceId: null,
    outstandingAmount: 0,
    message: 'تم',
  });
});

/* ================================================================== */
/* معالجة المسارات غير الموجودة والأخطاء (JSON دائماً لمسارات /api)     */
/* ================================================================== */

app.use('/api', (_req, res) => res.status(404).json({ message: 'المسار غير موجود' }));

// أي طلب آخر غير معروف → الواجهة (SPA fallback) إن وُجدت
app.use((_req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html'), (err) => {
  if (err) res.status(404).json({ message: 'غير موجود' });
}));

// معالج أخطاء عام — يضمن استجابة JSON بدل تعطّل الخادم
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('خطأ غير متوقع:', err);
  res.status(500).json({ message: 'خطأ في الخادم' });
});

/* ================================================================== */
/* التشغيل                                                             */
/* ================================================================== */

async function start() {
  if (MONGODB_URI) { store = await createMongoStore(MONGODB_URI); console.log('التخزين: MongoDB'); }
  else { store = createMemoryStore(); console.log('التخزين: في الذاكرة (in-memory)'); }

  // حذف لمرة واحدة للملاعب التجريبية الحالية عند أول تشغيل بعد هذا التحديث
  try {
    const flag = isMongo()
      ? await store.findOne('notifications', { title: '__cleared_all_fields_v1__' })
      : await store.findOne('notifications', (n) => n.title === '__cleared_all_fields_v1__');
    if (!flag) {
      const deleted = await store.deleteAll('fields');
      await store.insert('notifications', {
        userId: 0,
        title: '__cleared_all_fields_v1__',
        message: `deleted ${deleted} fields`,
        isRead: true,
      });
      console.log(`تم حذف ${deleted} ملعب من قاعدة البيانات`);
    }
  } catch (e) {
    console.error('تحذير: فشل تنظيف الملاعب:', e.message || e);
  }

  app.listen(PORT, () => console.log(`الخادم يعمل على المنفذ ${PORT}`));
}

start().catch((err) => { console.error('فشل بدء الخادم:', err); process.exit(1); });
