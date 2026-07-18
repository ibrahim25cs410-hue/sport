export function invitationErrorKey(error) {
  const code = String(error?.data?.code || error?.data?.error || '').toUpperCase();
  const message = String(error?.message || '').toLowerCase();
  if (error?.status === 410 || code.includes('EXPIRED') || message.includes('expired')) return 'expired';
  if (error?.status === 409 || code.includes('USED') || code.includes('ACCEPTED') || message.includes('already used')) return 'used';
  if ([400, 404, 422].includes(error?.status) || code.includes('INVALID')) return 'invalid';
  return 'server';
}
