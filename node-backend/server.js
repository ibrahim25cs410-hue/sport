/**
 * Riyada — باك إند حجز الملاعب (يطابق عقد تطبيق Flutter في mobile/).
 *
 * التخزين:
 *   - التطوير: في الذاكرة (إذا لم يُضبط MONGODB_URI).
 *   - الإنتاج: MongoDB Atlas عبر Mongoose (إلزامي — NODE_ENV=production).
 *
 * البنية: models/ + db/ + config.js + server.js
 */

const path = require('path');
const http = require('http');
const express = require('express');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const { config, validateConfig } = require('./config');
const { initStore, getStore, closeStore } = require('./db');
const authRoutes = require('./routes/authRoutes');
const stadiumRoutes = require('./routes/stadiumRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const { initSocketHandler } = require('./socketHandler');
const { auth, optionalAuth } = require('./middleware/auth');
const { publicField } = require('./utils/dto');
const { serverError } = require('./utils/errors');

const PORT = config.port;
const IS_PROD = config.isProd;
const STARTED_AT = Date.now();

validateConfig();

const app = express();
app.set('trust proxy', 1); // خلف بروكسي Render (لعناوين IP و https الصحيحة)

// أمان: ترويسات واقية (نُعطّل CSP لأننا نقدّم واجهة HTML/JS مضمّنة)
app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));
app.use(compression()); // ضغط الاستجابات
app.use(cors());
app.use(express.json({ limit: '8mb' })); // صور base64
app.use(morgan(IS_PROD ? 'combined' : 'dev')); // تسجيل الطلبات

// حدّ عام للطلبات: 300 طلب/دقيقة لكل IP
app.use('/api', rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'طلبات كثيرة جداً، حاول لاحقاً' },
}));

app.use(express.static(path.join(__dirname, 'public')));

/* ================================================================== */
/* مساعدات الاستعلام (تعمل مع الذاكرة و MongoDB)                       */
/* ================================================================== */

const store = () => getStore();
const isMongo = () => store().kind === 'mongodb';

async function fieldsByOwner(ownerId) {
  const q = { ownerId: Number(ownerId), isActive: { $ne: false } };
  if (!isMongo()) {
    return store().find('fields', (f) => f.ownerId === Number(ownerId) && f.isActive !== false);
  }
  return store().find('fields', q);
}

async function bookingsByUser(userId) {
  return isMongo()
    ? store().find('bookings', { userId: Number(userId) })
    : store().find('bookings', (b) => b.userId === Number(userId));
}

async function bookingsByField(fieldId) {
  return isMongo()
    ? store().find('bookings', { fieldId: Number(fieldId) })
    : store().find('bookings', (b) => b.fieldId === Number(fieldId));
}

async function notificationsByUser(userId) {
  return isMongo()
    ? store().find('notifications', { userId: Number(userId) })
    : store().find('notifications', (n) => n.userId === Number(userId));
}

async function allFields() {
  if (isMongo()) return store().find('fields', { isActive: { $ne: false } });
  return store().find('fields', (f) => f.isActive !== false);
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

app.get('/api/health', (_req, res) => res.json({
  status: 'ok',
  storage: store().kind,
  uptimeSeconds: Math.floor((Date.now() - STARTED_AT) / 1000),
  timestamp: new Date().toISOString(),
}));

app.use('/api', authRoutes);
app.use('/api', stadiumRoutes);
app.use('/api', bookingRoutes);

/* ================================================================== */
/* المسارات — Fields                                                   */
/* ================================================================== */

app.get('/api/fields', optionalAuth, async (req, res) => {
  const list = (await allFields()).map(publicField);
  res.json(paged(list, req.query.page, req.query.limit));
});

app.get('/api/fields/:id', auth, async (req, res) => {
  const f = await store().findById('fields', req.params.id);
  if (!f || f.isActive === false) return res.status(404).json({ message: 'الملعب غير موجود' });
  res.json(publicField(f));
});

app.put('/api/fields/:id', auth, async (req, res) => {
  const f = await store().findById('fields', req.params.id);
  if (!f || f.isActive === false) return res.status(404).json({ message: 'الملعب غير موجود' });
  if (Number(f.ownerId) !== Number(req.user.id)) return res.status(403).json({ message: 'غير مصرح' });
  const { name, address, phone, pricePerHour, image } = req.body || {};
  const patch = {};
  if (name != null) patch.name = name;
  if (address != null) patch.address = address;
  if (phone != null) patch.phone = phone;
  if (pricePerHour != null) patch.pricePerHour = Number(pricePerHour);
  if (image != null) patch.image = image;
  res.json(publicField(await store().update('fields', req.params.id, patch)));
});

// حذف منطقي (soft delete) — يخفي الملعب دون مسح الحجوزات السابقة
app.delete('/api/fields/:id', auth, async (req, res) => {
  const f = await store().findById('fields', req.params.id);
  if (!f || f.isActive === false) return res.status(404).json({ message: 'الملعب غير موجود' });
  if (Number(f.ownerId) !== Number(req.user.id)) return res.status(403).json({ message: 'غير مصرح' });
  await store().softDeleteField(req.params.id);
  res.json({ message: 'تم حذف الملعب', id: Number(req.params.id) });
});

// جدول المواعيد: 7 أيام × ساعات 10:00–23:00 مع علامة التوفر
app.get('/api/fields/:id/schedule', auth, async (req, res) => {
  const f = await store().findById('fields', req.params.id);
  if (!f || f.isActive === false) return res.status(404).json({ message: 'الملعب غير موجود' });
  const booked = (await bookingsByField(f.id)).filter((b) => b.status === 'pending' || b.status === 'approved');
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
  res.json({ id: f.id, name: f.name, pricePerHour: f.pricePerHour, schedule });
});

// التقييمات (مبسّطة)
app.get('/api/fields/:id/review-eligibility', auth, async (req, res) => {
  const f = await store().findById('fields', req.params.id);
  res.json({ canReview: false, hasBooked: false, userRating: null, averageRating: f?.averageRating || 0, reviewCount: f?.reviewCount || 0 });
});
app.get('/api/fields/:id/reviews', auth, (_req, res) => res.json([]));
app.post('/api/fields/:id/reviews', auth, (_req, res) => res.json({ ok: true }));

/* ================================================================== */
/* المسارات — Slots (حجز تنافسي مبسّط)                                 */
/* ================================================================== */

app.post('/api/slots/select', auth, async (req, res) => {
  try {
    const { fieldId, startTime, hours } = req.body || {};
    if (!fieldId || !startTime) {
      return res.status(400).json({ message: 'fieldId and startTime are required' });
    }
    const { selectSlot } = require('./utils/slotHolds');
    const result = selectSlot({
      fieldId,
      userId: req.user.id,
      startTime,
      hours: Number(hours) || 1,
    });
    if (result.conflict) {
      return res.status(409).json({ code: 'ConflictError', messageKey: result.messageKey });
    }
    return res.json({ expiresAt: result.expiresAt });
  } catch (e) {
    return serverError(res, e);
  }
});
app.post('/api/slots/release', auth, async (req, res) => {
  try {
    const { fieldId, startTime, hours } = req.body || {};
    if (!fieldId || !startTime) {
      return res.status(400).json({ message: 'fieldId and startTime are required' });
    }
    const { releaseSlot } = require('./utils/slotHolds');
    releaseSlot({
      fieldId,
      userId: req.user.id,
      startTime,
      hours: Number(hours) || 1,
    });
    return res.json({ ok: true });
  } catch (e) {
    return serverError(res, e);
  }
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
  await store().update('notifications', req.params.id, { isRead: true });
  res.json({ ok: true });
});
app.post('/api/notifications/user/:userId/read-all', auth, async (req, res) => {
  await store().markAllNotificationsRead(req.params.userId);
  res.json({ ok: true });
});

/* ================================================================== */
/* المسارات — أخرى (stubs تمنع أعطال الشاشات الثانوية)                 */
/* ================================================================== */

app.post('/api/users/update-token', auth, (_req, res) => res.json({ ok: true }));

app.get('/api/owner/wallet/status', auth, (req, res) => {
  res.json({ ownerId: req.user.id, balance: 0, status: 'active', message: null });
});
app.get('/api/owner/wallet', auth, (req, res) => {
  res.json({ walletId: 1, ownerId: req.user.id, balance: 0, status: 'active', lastUpdated: new Date().toISOString(), transactions: [] });
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
  await initStore();
  console.log(`التخزين: ${store().kind}`);

  const server = http.createServer(app);
  const io = new Server(server, {
    cors: { origin: true, credentials: true },
  });
  initSocketHandler(io);

  server.listen(PORT, () => console.log(`الخادم يعمل على المنفذ ${PORT} (HTTP + WebSocket)`));

  const shutdown = async (signal) => {
    console.log(`استلام ${signal}: إيقاف آمن للخادم...`);
    io.close();
    server.close(async () => {
      await closeStore().catch((e) => console.error('خطأ إغلاق DB:', e));
      console.log('أُغلق الخادم.');
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000).unref();
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('unhandledRejection', (reason) => console.error('رفض غير معالَج:', reason));
}

start().catch((err) => { console.error('فشل بدء الخادم:', err); process.exit(1); });
