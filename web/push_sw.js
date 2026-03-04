// Service Worker dédié aux notifications push (VAPID)
// Reçoit les événements push du serveur et affiche les notifications navigateur.

self.addEventListener('push', function (event) {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: 'Notification', body: event.data.text() };
    }
  }

  const title = data.title || 'Coentrepreneurs';
  const options = {
    body: data.body || '',
    icon: data.icon || '/icons/android_xxxhdpi_192x192.png',
    badge: data.badge || '/icons/web_favicon_64x64.png',
    data: { url: data.url || '/' },
    requireInteraction: false,
    tag: data.tag || 'coentrepreneurs-notif',
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const targetUrl =
    event.notification.data && event.notification.data.url
      ? event.notification.data.url
      : '/';

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(function (clientList) {
        // Focus l'onglet existant si l'app est déjà ouverte
        for (const client of clientList) {
          if (
            client.url.includes(self.location.origin) &&
            'focus' in client
          ) {
            client.focus();
            if ('navigate' in client) client.navigate(targetUrl);
            return;
          }
        }
        // Sinon ouvre un nouvel onglet
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      })
  );
});

self.addEventListener('activate', function (event) {
  event.waitUntil(clients.claim());
});
