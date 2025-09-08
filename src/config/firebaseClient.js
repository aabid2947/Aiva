// src/config/firebaseClient.js
import {
  GOOGLE_WEB_CLIENT_ID // For Google Sign-In
} from '@env';
import firebase from '@react-native-firebase/app';
// Rename the imported functions to avoid a name conflict
import authModule from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';
import messagingModule from '@react-native-firebase/messaging';

// Export the initialized auth instance using the original 'auth' name
export const auth = authModule();

// Export the onAuthStateChanged function for convenience
export const onAuthStateChanged = (callback) => auth.onAuthStateChanged(callback);

// Export the initialized Firestore instance
export const db = firestore();

// Export the initialized Cloud Messaging instance using the original 'messaging' name
export const messaging = messagingModule();

// Export the firebase app instance
export default firebase;
export const googleSignInConfig = {
  // Replace with your Web Client ID from Google Cloud Console
  webClientId: GOOGLE_WEB_CLIENT_ID,
  offlineAccess: true, // Keep this to get a serverAuthCode if needed
};
