// AuthService.js
// --- UPDATED TO USE THE CORRECT GOOGLE SIGN-IN LIBRARY ---
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import Keychain from 'react-native-keychain';
import { apiStoreUserGoogleOAuthTokens } from '../api/aivaApiService';
// --- IMPORTANT ---
// Replace this with the actual base URL of your backend server
const API_URL = process.env.BASE_API_URL;
import {
  GOOGLE_WEB_CLIENT_ID // For Google Sign-In
} from '@env';
const SESSION_KEY = 'AIVA_APP_SESSION_KEY';

/**
 * Configures the Google Sign-In library.
 * This should be called once when your app starts.
 */
export const configureGoogleSignIn = () => {
   console.log('Running configureGoogleSignIn()');
  GoogleSignin.configure({
    // This MUST be the Client ID for your "Web application" from Google Cloud.
    // This allows the app to request a code that the backend can use.

    webClientId: GOOGLE_WEB_CLIENT_ID,

    // Request offline access to get a serverAuthCode for your backend.
    offlineAccess: true,
    forceCodeForRefreshToken: true,
    // Add the required Gmail scopes.
    scopes: [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/gmail.modify'
    ]
  });
};

/**
 * Initiates the Google Sign-In flow, gets a serverAuthCode,
 * and sends it to the backend to be exchanged for tokens.
 */

export const signIn = async () => {
  try {
    await GoogleSignin.hasPlayServices();
    const res = await GoogleSignin.signIn();
    console.log('🔍 GoogleSignin.signIn() result:', res);
    const serverAuthCode = res.data?.serverAuthCode;
    if (!serverAuthCode) {
      console.error('⚠️ no serverAuthCode in:', res);
      throw new Error('AuthService: Google Sign-In did not return a serverAuthCode.');
    }

    console.log('AuthService: sending code to backend…');
    //  ➤ CALL your API helper with the code
    const backendResponse = await apiStoreUserGoogleOAuthTokens({ code: serverAuthCode });

    // If your backend returns its own sessionToken + user data:
    // const { sessionToken, user } = backendResponse;
    // if (!sessionToken) {
    //   throw new Error('AuthService: Backend did not return a session token.');
    // }

    // // Securely store your app’s session token:
    // await Keychain.setGenericPassword('user_session', sessionToken, { service: SESSION_KEY });
      console.log('AuthService: backend responded:', backendResponse);

    return { success: true };
  } catch (error) {
    if (error.code === statusCodes.SIGN_IN_CANCELLED) {
      console.log('User cancelled the login flow');
      
    } else if (error.code === statusCodes.IN_PROGRESS) {
      console.log('Sign in is in progress already');
    } else if (error.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
      console.log('Play services not available or outdated');
    } else {
      console.error('AuthService: A critical error occurred during sign-in:', error);
    }
    throw error;
  }
};

/**
 * Retrieves the locally stored session token for the user.
 */
export const getStoredSession = async () => {
  try {
    const credentials = await Keychain.getGenericPassword({ service: SESSION_KEY });
    if (credentials) {
      return { sessionToken: credentials.password };
    }
    return null;
  } catch (error) {
    console.error('AuthService: Failed to get stored session:', error);
    return null;
  }
};

/**
 * Signs the user out by clearing the local session and revoking Google access.
 */
export const signOut = async () => {
  try {
    // Revoke the Google token on the device
    await GoogleSignin.revokeAccess();
    // Sign out from the Google Sign-In session
    await GoogleSignin.signOut();

    // Clear the stored session token from Keychain.
    await Keychain.resetGenericPassword({ service: SESSION_KEY });
    console.log('AuthService: User signed out and local session cleared.');

  } catch (error) {
    console.error('AuthService: Failed to sign out:', error);
    await Keychain.resetGenericPassword({ service: SESSION_KEY });
    throw error;
  }
};
