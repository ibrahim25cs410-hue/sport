/**
 * Riyada — باك إند حجز الملاعب (ملف واحد للتشغيل على Render).
 *
 * التخزين:
 *   - افتراضياً: في الذاكرة (in-memory) — سهل للتجربة، يُمسح عند إعادة التشغيل.
 *   - إذا ضبطت متغير البيئة MONGODB_URI: يستخدم MongoDB تلقائياً (يبقى محفوظاً).
 */

const path = require('path');
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const MONGODB_URI = process.env.MONGODB_URI || '';

const app = express();
app.use(cors());
app.use(express.json());

// واجهة الويب البسيطة (تُقدَّم من نفس السيرفر → تتصل بالـ API عبر مسار نسبي)
app.use(express.static(path.join(__dirname, 'public')));

/* ------------------------------------------------------------------ */
/* طبقة التخزين (store) — نفس الواجهة سواء ذاكرة أو MongoDB             */
/* ------------------------------------------------------------------ */

let store;

// --- تخزين في الذاكرة ---
function createMemoryStore() {
  const users = [];
  const fields = [];
  const bookings = [];
  const seq = { user: 0, field: 0, booking: 0 };

  return {
    kind: 'memory',
    async createUser(data) {
      const user = { id: String(++seq.user), ...data };
      users.push(user);
      return user;
    },
    async findUserByEmail(email) {
      return users.find((u) => u.email === email) || null;
    },
    async findUserById(id) {
      return users.find((u) => u.id === id) || null;
    },
    async createField(data) {
      const field = { id: String(++seq.field), ...data };
      fields.push(field);
      return field;
    },
    async listFields() {
      return fields;
    },
    async findFieldById(id) {
      return fields.find((f) => f.id === id) || null;
    },
    async createBooking(data) {
      const booking = { id: String(++seq.booking), ...data };
      bookings.push(booking);
      return booking;
    },
    async findBookingById(id) {
      return bookings.find((b) => b.id === id) || null;
    },
    async updateBookingStatus(id, status) {
      const b = bookings.find((x) => x.id === id);
      if (!b) return null;
      b.status = status;
      return b;
    },
    async bookingsByUser(userId) {
      return bookings.filter((b) => b.userId === userId);
    },
    async bookingsByOwner(ownerId) {
      return bookings.filter((b) => b.ownerId === ownerId);
    },
  };
}

// --- تخزين MongoDB (يُستخدم فقط إذا وُجد MONGODB_URI) ---
async function createMongoStore(uri) {
  const mongoose = require('mongoose');
  await mongoose.connect(uri);

  const toId = (doc) => {
    if (!doc) return null;
    const obj = doc.toObject ? doc.toObject() : doc;
    obj.id = String(obj._id);
    delete obj._id;
    delete obj.__v;
    return obj;
  };

  const User = mongoose.model('User', new mongoose.Schema({
    name: String,
    email: { type: String, unique: true },
    password: String,
    phone: String,
    role: { type: String, enum: ['user', 'owner'], default: 'user' },
  }, { timestamps: true }));

  const Field = mongoose.model('Field', new mongoose.Schema({
    name: String,
    location: String,
    pricePerHour: Number,
    description: String,
    ownerId: String,
  }, { timestamps: true }));

  const Booking = mongoose.model('Booking', new mongoose.Schema({
    fieldId: String,
    fieldName: String,
    userId: String,
    ownerId: String,
    date: String,
    time: String,
    hours: { type: Number, default: 1 },
    status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  }, { timestamps: true }));

  return {
    kind: 'mongodb',
    async createUser(data) { return toId(await User.create(data)); },
    async findUserByEmail(email) { return toId(await User.findOne({ email })); },
    async findUserById(id) { return toId(await User.findById(id)); },
    async createField(data) { return toId(await Field.create(data)); },
    async listFields() { return (await Field.find()).map(toId); },
    async findFieldById(id) { return toId(await Field.findById(id)); },
    async createBooking(data) { return toId(await Booking.create(data)); },
    async findBookingById(id) { return toId(await Booking.findById(id)); },
    async updateBookingStatus(id, status) {
      return toId(await Booking.findByIdAndUpdate(id, { status }, { new: true }));
    },
    async bookingsByUser(userId) { return (await Booking.find({ userId })).map(toId); },
    async bookingsByOwner(ownerId) { return (await Booking.find({ ownerId })).map(toId); },
  };
}

/* ------------------------------------------------------------------ */
/* أدوات المصادقة (JWT)                                                */
/* ------------------------------------------------------------------ */

function sign(user) {
  return jwt.sign({ id: user.id, role: user.role, name: user.name }, JWT_SECRET, {
    expiresIn: '7d',
  });
}

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'مطلوب تسجيل الدخول' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ message: 'جلسة غير صالحة' });
  }
}

function requireRole(role) {
  return (req, res, next) => {
    if (req.user.role !== role) {
      return res.status(403).json({ message: `هذه العملية مخصصة لـ ${role}` });
    }
    next();
  };
}

function publicUser(u) {
  return { id: u.id, name: u.name, email: u.email, phone: u.phone, role: u.role };
}

/* ------------------------------------------------------------------ */
/* المسارات (API Endpoints)                                            */
/* ------------------------------------------------------------------ */

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', storage: store.kind, message: 'Riyada backend يعمل' });
});

// تسجيل مستخدم أو صاحب ملعب
app.post('/api/register', async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body || {};
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'الاسم والبريد وكلمة المرور مطلوبة' });
    }
    const chosenRole = role === 'owner' ? 'owner' : 'user';
    if (await store.findUserByEmail(email)) {
      return res.status(409).json({ message: 'البريد مستخدم مسبقاً' });
    }
    const hashed = await bcrypt.hash(password, 10);
    const user = await store.createUser({ name, email, password: hashed, phone, role: chosenRole });
    return res.status(201).json({ token: sign(user), user: publicUser(user) });
  } catch (err) {
    return res.status(500).json({ message: 'خطأ في الخادم', error: String(err) });
  }
});

// تسجيل الدخول
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ message: 'البريد وكلمة المرور مطلوبة' });
    }
    const user = await store.findUserByEmail(email);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'بيانات الدخول غير صحيحة' });
    }
    return res.json({ token: sign(user), user: publicUser(user) });
  } catch (err) {
    return res.status(500).json({ message: 'خطأ في الخادم', error: String(err) });
  }
});

// قائمة الملاعب (متاحة للجميع)
app.get('/api/fields', async (_req, res) => {
  res.json(await store.listFields());
});

// إضافة ملعب (صاحب الملعب فقط)
app.post('/api/fields', auth, requireRole('owner'), async (req, res) => {
  const { name, location, pricePerHour, description } = req.body || {};
  if (!name || !location) {
    return res.status(400).json({ message: 'اسم الملعب والموقع مطلوبان' });
  }
  const field = await store.createField({
    name,
    location,
    pricePerHour: Number(pricePerHour) || 0,
    description: description || '',
    ownerId: req.user.id,
  });
  res.status(201).json(field);
});

// إرسال طلب حجز (المستخدم فقط) — الحالة الافتراضية pending
app.post('/api/bookings', auth, requireRole('user'), async (req, res) => {
  const { fieldId, date, time, hours } = req.body || {};
  if (!fieldId || !date || !time) {
    return res.status(400).json({ message: 'الملعب والتاريخ والوقت مطلوبة' });
  }
  const field = await store.findFieldById(fieldId);
  if (!field) return res.status(404).json({ message: 'الملعب غير موجود' });

  const booking = await store.createBooking({
    fieldId,
    fieldName: field.name,
    userId: req.user.id,
    ownerId: field.ownerId,
    date,
    time,
    hours: Number(hours) || 1,
    status: 'pending',
  });
  res.status(201).json(booking);
});

// تغيير حالة الحجز (صاحب الملعب فقط) — accepted أو rejected
app.patch('/api/bookings/:id', auth, requireRole('owner'), async (req, res) => {
  const { status } = req.body || {};
  if (!['accepted', 'rejected'].includes(status)) {
    return res.status(400).json({ message: 'الحالة يجب أن تكون accepted أو rejected' });
  }
  const booking = await store.findBookingById(req.params.id);
  if (!booking) return res.status(404).json({ message: 'الحجز غير موجود' });
  if (booking.ownerId !== req.user.id) {
    return res.status(403).json({ message: 'لا تملك صلاحية على هذا الحجز' });
  }
  res.json(await store.updateBookingStatus(req.params.id, status));
});

// حجوزات المستخدم الحالي
app.get('/api/bookings/me', auth, requireRole('user'), async (req, res) => {
  res.json(await store.bookingsByUser(req.user.id));
});

// الطلبات الواردة لصاحب الملعب الحالي
app.get('/api/bookings/incoming', auth, requireRole('owner'), async (req, res) => {
  res.json(await store.bookingsByOwner(req.user.id));
});

/* ------------------------------------------------------------------ */
/* التشغيل                                                             */
/* ------------------------------------------------------------------ */

async function start() {
  if (MONGODB_URI) {
    store = await createMongoStore(MONGODB_URI);
    console.log('التخزين: MongoDB');
  } else {
    store = createMemoryStore();
    console.log('التخزين: في الذاكرة (in-memory)');
  }
  app.listen(PORT, () => console.log(`الخادم يعمل على المنفذ ${PORT}`));
}

start().catch((err) => {
  console.error('فشل بدء الخادم:', err);
  process.exit(1);
});
