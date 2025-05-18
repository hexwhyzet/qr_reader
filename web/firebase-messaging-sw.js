// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDXaYw5EPKOOdaIwT4bA5JTvRx4_P46S8U",
  authDomain: "sostra-7183e.firebaseapp.com",
  databaseURL: "sostra-7183e",
  projectId: "sostra-7183e",
  storageBucket: "sostra-7183e.firebasestorage.app",
  messagingSenderId: "9179049901",
  appId: "1:9179049901:web:e74d08926b9e07a0fd3b24",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});
