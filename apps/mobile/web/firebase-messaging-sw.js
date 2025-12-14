// firebase-messaging-sw.js
// Crea este archivo en: web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Configuración de Firebase - usar la misma configuración que en firebase_options.dart
firebase.initializeApp({
  apiKey: 'AIzaSyBZd3_krKkXx-S33Sg3XZ78i5UQBOGQCTA',
  authDomain: 'frogio-201f9.firebaseapp.com',
  projectId: 'frogio-201f9',
  storageBucket: 'frogio-201f9.firebasestorage.app',
  messagingSenderId: '729189223627',
  appId: '1:729189223627:web:187faa2b27d5439c2e9f4e',
  measurementId: 'G-YV6JDQ3DP7',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'FROGIO';
  const notificationOptions = {
    body: payload.notification?.body || 'Nueva notificación',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'frogio-notification',
    data: payload.data,
    actions: [
      {
        action: 'open',
        title: 'Abrir'
      },
      {
        action: 'close',
        title: 'Cerrar'
      }
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  if (event.action === 'close') {
    return;
  }

  // Open the app when notification is clicked
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then(function(clientList) {
      // Check if app is already open
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.includes('localhost') || client.url.includes('frogio')) {
          return client.focus();
        }
      }
      
      // If app is not open, open it
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});