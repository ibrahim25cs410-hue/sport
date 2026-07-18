const crypto = require('crypto');

function tokenHash(token) {
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}

function createInvitationToken() {
  const token = crypto.randomBytes(32).toString('base64url');
  return { token, hash: tokenHash(token) };
}

function invitationUrl(token) {
  const base = String(process.env.ADMIN_INVITE_BASE_URL || '').replace(/\/+$/, '');
  return base ? `${base}/accept-invitation?token=${encodeURIComponent(token)}` : null;
}

async function deliverInvitation({ email, name, token, expiresAt }) {
  const apiKey = process.env.RESEND_API_KEY;
  const from = process.env.EMAIL_FROM || process.env.RESEND_FROM_EMAIL;
  const url = invitationUrl(token);
  if (!apiKey || !from || !url) {
    return { status: 'not_configured', required: ['RESEND_API_KEY', 'EMAIL_FROM', 'ADMIN_INVITE_BASE_URL'] };
  }
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from,
      to: [email],
      subject: 'دعوة للانضمام إلى إدارة رياضة',
      html: `<p>مرحباً ${escapeHtml(name)},</p><p><a href="${escapeHtml(url)}">قبول الدعوة وتعيين كلمة المرور</a></p><p>تنتهي الدعوة في ${escapeHtml(expiresAt)}.</p>`,
      text: `مرحباً ${name}\nاقبل الدعوة وعيّن كلمة المرور: ${url}\nتنتهي الدعوة في ${expiresAt}`,
    }),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(`Resend delivery failed (${response.status}): ${payload.message || 'unknown error'}`);
  return { status: 'sent', provider: 'resend', messageId: payload.id || null };
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[char]));
}

module.exports = { createInvitationToken, deliverInvitation, invitationUrl, tokenHash };
