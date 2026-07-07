/**
 * إشعارات المتصفح — تظهر عند موافقة المالك على الحجز.
 */
export function requestNotificationPermission() {
  if (!('Notification' in window)) return Promise.resolve(false);
  if (Notification.permission === 'granted') return Promise.resolve(true);
  if (Notification.permission === 'denied') return Promise.resolve(false);
  return Notification.requestPermission().then((p) => p === 'granted');
}

export function showBrowserNotification({ title, body, tag }) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  try {
    new Notification(title, { body, tag, icon: '/favicon.ico' });
  } catch (_) {
    /* ignore */
  }
}
