import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '../..');
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8');
const errors = [];

function requireMatch(file, pattern, message) {
  if (!pattern.test(read(file))) errors.push(`${file}: ${message}`);
}

requireMatch('render.yaml', /healthCheckPath:\s*\/api\/ready/, 'deployment health check must use storage-aware /api/ready');
requireMatch('render.yaml', /key:\s*NODE_ENV\s*\r?\n\s*value:\s*production/, 'NODE_ENV must be production');
requireMatch(
  'render.yaml',
  /key:\s*ELECTRONIC_PAYMENTS_ENABLED\s*\r?\n\s*value:\s*['"]?false['"]?/,
  'cash-only launch requires ELECTRONIC_PAYMENTS_ENABLED=false',
);
requireMatch('render.yaml', /key:\s*MONGODB_URI\s*\r?\n\s*sync:\s*false/, 'MONGODB_URI must be supplied outside Git');
requireMatch('render.yaml', /key:\s*JWT_SECRET\s*\r?\n\s*(?:sync:\s*false|generateValue:\s*true)/, 'JWT_SECRET must not be committed');
requireMatch('web-admin/.env.production', /^VITE_ELECTRONIC_PAYMENTS_ENABLED=false$/m, 'admin must be cash-only');
requireMatch('mobile/config/env.prod.json.example', /"API_BASE_URL":\s*"https:\/\//, 'mobile production API must use HTTPS');
requireMatch('server.js', /process\.env\.ELECTRONIC_PAYMENTS_ENABLED\s*\|\|\s*['"]false['"]/, 'backend must default payments off');

for (const file of ['render.yaml', '.env.example', 'web/.env.production', 'web-admin/.env.production']) {
  const content = read(file);
  if (/mongodb(?:\+srv)?:\/\/[^:\s]+:[^@\s]+@/i.test(content) && !/USER:PASSWORD/.test(content)) {
    errors.push(`${file}: appears to contain MongoDB credentials`);
  }
  if (/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(content)) {
    errors.push(`${file}: contains a private key`);
  }
}

if (errors.length) {
  console.error(`Release configuration validation failed:\n- ${errors.join('\n- ')}`);
  process.exit(1);
}

console.log('Release configuration validation: PASS (cash-only, HTTPS, external secrets).');
