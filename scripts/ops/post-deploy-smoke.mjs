const origin = (process.argv[2] || process.env.PRODUCTION_ORIGIN || '').replace(/\/+$/, '');
const expectCashOnly = process.env.EXPECT_CASH_ONLY !== 'false';
const expectMongo = process.env.EXPECT_MONGODB !== 'false';
const expectCustomerWeb = process.env.EXPECT_CUSTOMER_WEB !== 'false';
const attempts = Number(process.env.SMOKE_ATTEMPTS || 18);
const delayMs = Number(process.env.SMOKE_DELAY_MS || 10000);

if (!/^https:\/\/[^/]+$/i.test(origin)) {
  console.error('Usage: node scripts/ops/post-deploy-smoke.mjs https://service.example');
  process.exit(2);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function get(pathname) {
  const response = await fetch(`${origin}${pathname}`, {
    headers: { accept: 'application/json', 'user-agent': 'riyada-deploy-smoke/1.0' },
    signal: AbortSignal.timeout(15000),
  });
  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = text;
  }
  if (!response.ok) throw new Error(`${pathname} returned HTTP ${response.status}`);
  return body;
}

let health;
for (let attempt = 1; attempt <= attempts; attempt += 1) {
  try {
    health = await get('/api/health');
    if (health?.status === 'ok') break;
    throw new Error(`unexpected health payload: ${JSON.stringify(health)}`);
  } catch (error) {
    if (attempt === attempts) throw error;
    console.log(`Health attempt ${attempt}/${attempts} failed; retrying after ${delayMs}ms.`);
    await sleep(delayMs);
  }
}

if (health.env !== 'production') throw new Error(`Expected production env, received ${health.env}`);
if (expectMongo && health.storage !== 'mongodb') {
  throw new Error(`Expected MongoDB storage, received ${health.storage}`);
}
if (expectCashOnly && (health.electronicPaymentsEnabled !== false || health.paymentMode !== 'cash_only')) {
  throw new Error('Production is not reporting cash-only payment mode');
}

const ready = await get('/api/ready');
if (ready?.ready !== true || (expectMongo && ready.storage !== 'mongodb')) {
  throw new Error(`Production storage is not ready: ${JSON.stringify(ready)}`);
}

const fields = await get('/api/fields');
if (!Array.isArray(fields) && !Array.isArray(fields?.items)) {
  throw new Error('/api/fields did not return a collection');
}

const isHtmlDocument = (body) => (
  typeof body === 'string' && /<!doctype\s+html/i.test(body)
);

const panel = await get('/panel/');
if (!isHtmlDocument(panel)) {
  throw new Error('/panel/ did not return the admin application');
}
if (expectCustomerWeb) {
  const customerWeb = await get('/app/');
  if (!isHtmlDocument(customerWeb)) {
    throw new Error('/app/ did not return the customer application');
  }
}

console.log(`Post-deploy smoke: PASS (${origin}, ${health.storage}, ${health.paymentMode}).`);
