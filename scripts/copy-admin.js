const fs = require('fs');
const path = require('path');

function rmrf(p) {
  fs.rmSync(p, { recursive: true, force: true });
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name);
    const to = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(from, to);
    else fs.copyFileSync(from, to);
  }
}

const src = path.join(__dirname, '..', 'web-admin', 'dist');
const dest = path.join(__dirname, '..', 'public', 'panel');

if (!fs.existsSync(src)) {
  console.error('web-admin/dist not found — run web-admin build first');
  process.exit(1);
}

rmrf(dest);
copyDir(src, dest);
console.log(`Admin panel copied to ${dest}`);
