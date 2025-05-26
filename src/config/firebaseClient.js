// src/config/firebaseClient.js
import {
  FIREBASE_API_KEY,
  FIREBASE_AUTH_DOMAIN,
  FIREBASE_PROJECT_ID,
  FIREBASE_STORAGE_BUCKET,
  FIREBASE_MESSAGING_SENDER_ID,
  FIREBASE_APP_ID,
  FIREBASE_MEASUREMENT_ID,
  GOOGLE_WEB_CLIENT_ID // For Google Sign-In
} from '@env'; // Import from the special @env module
import firebase from '@react-native-firebase/app'; // <--- Make sure this is imported
import '@react-native-firebase/auth'; 

export const firebaseConfig = {
  apiKey: FIREBASE_API_KEY,
  authDomain: FIREBASE_AUTH_DOMAIN,
  projectId: FIREBASE_PROJECT_ID,
  storageBucket: FIREBASE_STORAGE_BUCKET,
  messagingSenderId: FIREBASE_MESSAGING_SENDER_ID,
  appId: FIREBASE_APP_ID,
  measurementId: FIREBASE_MEASUREMENT_ID // Optional
};

if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}

// Export the auth instance for easy access
export const auth = firebase.auth();
// export const firestore = firebase.firestore(); // Export firestore if needed

// You can also export the main firebase instance if you need it directly
export default firebase;

export const googleSignInConfig = {
  webClientId: GOOGLE_WEB_CLIENT_ID,
  offlineAccess: true,
};