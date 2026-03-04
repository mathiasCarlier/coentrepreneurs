// Utilitaires JavaScript pour les notifications push (VAPID).
// Exposé sous window._pushUtils, appelé depuis Flutter via dart:js_interop.

window._pushUtils = {
  _swUrl: '/push_sw.js',
  _swScope: '/push-sw-scope/',

  /**
   * Demande la permission, enregistre le SW, s'abonne au push.
   * Retourne une chaîne JSON : { endpoint, keys: { p256dh, auth } }
   * ou { error: '...' } en cas d'échec.
   */
  subscribe: async function (vapidPublicKey) {
    try {
      if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        return JSON.stringify({ error: 'not_supported' });
      }

      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        return JSON.stringify({ error: 'permission_denied' });
      }

      // Enregistrer le service worker dédié au push
      const registration = await navigator.serviceWorker.register(
        window._pushUtils._swUrl,
        { scope: window._pushUtils._swScope }
      );

      // Attendre que le SW soit actif
      await new Promise(function (resolve) {
        if (registration.active) {
          resolve();
        } else {
          const sw = registration.installing || registration.waiting;
          sw.addEventListener('statechange', function (e) {
            if (e.target.state === 'activated') resolve();
          });
        }
      });

      // Vérifier si déjà abonné
      let subscription = await registration.pushManager.getSubscription();
      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: window._pushUtils._urlB64ToUint8Array(vapidPublicKey),
        });
      }

      return JSON.stringify(subscription.toJSON());
    } catch (e) {
      return JSON.stringify({ error: e.toString() });
    }
  },

  /**
   * Se désabonne du push et désactive le service worker.
   */
  unsubscribe: async function () {
    try {
      const regs = await navigator.serviceWorker.getRegistrations();
      for (const reg of regs) {
        if (reg.scope.includes(window._pushUtils._swScope.replace(/\/$/, ''))) {
          const sub = await reg.pushManager.getSubscription();
          if (sub) await sub.unsubscribe();
          await reg.unregister();
        }
      }
      return 'ok';
    } catch (e) {
      return 'error:' + e.toString();
    }
  },

  /**
   * Convertit une clé VAPID (base64url) en Uint8Array pour PushManager.subscribe().
   */
  _urlB64ToUint8Array: function (base64String) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  },
};
