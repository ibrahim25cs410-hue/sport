/**
 * اختبار استمرارية البيانات بعد إعادة تشغيل السيرفر.
 * يتطلب: MONGODB_URI و JWT_SECRET في البيئة.
 */

const { spawn } = require('child_process');
const path = require('path');

const PORT = 3995;
const BASE = `http://127.0.0.1:${PORT}/api`;
const MONGODB_URI = process.env.MONGODB_URI;
const JWT_SECRET = process.env.JWT_SECRET || 'test-persistence-secret';

if (!MONGODB_URI) {
  console.error('❌ عيّن MONGODB_URI أولاً (MongoDB Atlas connection string)');
  process.exit(1);
}

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function req(method, p, { body, token } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${BASE}${p}`, {
    method, headers, body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, data: await res.json() };
}

function startServer() {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
      env: { ...process.env, PORT: String(PORT), MONGODB_URI, JWT_SECRET, NODE_ENV: 'production' },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let buf = '';
    child.stdout.on('data', (d) => {
      buf += d.toString();
      if (buf.includes('الخادم يعمل')) resolve(child);
    });
    child.stderr.on('data', (d) => process.stderr.write(d));
    child.on('error', reject);
    setTimeout(() => reject(new Error('Server start timeout')), 30000);
  });
}

async function main() {
  const email = `persist_${Date.now()}@riyada.test`;

  console.log('=== تشغيل السيرفر (المرة 1) ===');
  let child = await startServer();

  const reg = await req('POST', '/register-user', {
    body: { name: 'اختبار دائم', email, password: 'test1234' },
  });
  if (reg.status !== 201) throw new Error('Register failed: ' + JSON.stringify(reg.data));
  const userId = reg.data.user.id;
  console.log(`✓ أُنشئ مستخدم id=${userId}`);

  child.kill();
  await sleep(2000);
  console.log('✓ أُوقف السيرفر');

  console.log('\n=== تشغيل السيرفر (المرة 2 — بعد إعادة التشغيل) ===');
  child = await startServer();

  const login = await req('POST', '/login', { body: { email, password: 'test1234' } });
  if (login.status !== 200 || login.data.user.id !== userId) {
    throw new Error('البيانات ضاعت بعد إعادة التشغيل!');
  }
  console.log(`✓ البيانات محفوظة — id=${login.data.user.id}`);

  child.kill();
  console.log('\n✅ اختبار الاستمرارية نجح.');
}

main().catch((e) => { console.error('❌ فشل:', e.message); process.exit(1); });
