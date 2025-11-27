importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

const firebaseConfig = {
    apiKey: "AIzaSyAdUfoq0JA5OI7LSJWRXPsdYTVCsp-KNKo",
    authDomain: "tech-service-app-e9ade.firebaseapp.com",
    projectId: "tech-service-app-e9ade",
    storageBucket: "tech-service-app-e9ade.firebasestorage.app",
    messagingSenderId: "557548135367",
    appId: "1:557548135367:web:641d2d1e48a036d99fafe2",
    measurementId: "G-PX5XNPLQKD"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
