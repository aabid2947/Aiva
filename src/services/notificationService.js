// src/services/notificationService.js
import { Alert, Platform } from 'react-native';
import messaging from '@react-native-firebase/messaging';
import { getApp } from '@react-native-firebase/app';
import { db, auth as firebaseAuth } from '../config/firebaseClient';

/**
 * Saves the user's FCM device token to Firestore.
 */
const saveTokenToFirestore = async (token) => {
  try {
    const currentUser = firebaseAuth.currentUser;
    if (currentUser) {
      console.log('Attempting to save FCM token for user:', currentUser.uid);
      console.log('User email:', currentUser.email);
      console.log('User verified:', currentUser.emailVerified);
      
      const userDocRef = db.collection('users').doc(currentUser.uid);
      await userDocRef.set({ fcmToken: token }, { merge: true });
      console.log('✅ [SUCCESS] FCM token saved to Firestore.');
    } else {
      console.warn('⚠️ [WARNING] Cannot save FCM token. No user is currently signed in.');
    }
  } catch (error) {
    console.error('❌ [ERROR] Error saving FCM token to Firestore:', error);
    
    // Check if it's a permission error
    if (error.code === 'firestore/permission-denied') {
      console.error('🔒 [PERMISSION ERROR] Firestore security rules are blocking FCM token write.');
      console.error('📝 [SOLUTION] Update your Firestore security rules to allow authenticated users to write to their user document.');
      console.error('🔧 [RULE EXAMPLE] match /users/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }');
    }
  }
};

/**
 * Requests permission for notifications from the user.
 * For background notifications to work, we need explicit permission.
 */
const requestUserPermission = async () => {
  console.log('➡️ [STEP 1] Requesting notification permission...');
  
  try {
    const app = getApp();
    const messagingInstance = messaging(app);
    
    // Request permission with all necessary options for background notifications
    const authStatus = await messagingInstance.requestPermission({
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      provisional: false, // Set to false to get explicit permission
      sound: true,
      criticalAlert: false,
    });
    
    console.log('ℹ️ [INFO] Authorization status from OS:', authStatus);
    
    // Log the actual status values for debugging
    console.log('ℹ️ [DEBUG] Status values:', {
      AUTHORIZED: messaging.AuthorizationStatus.AUTHORIZED,
      DENIED: messaging.AuthorizationStatus.DENIED,
      NOT_DETERMINED: messaging.AuthorizationStatus.NOT_DETERMINED,
      PROVISIONAL: messaging.AuthorizationStatus.PROVISIONAL,
      received: authStatus
    });

    // Check if we have proper authorization
    const enabled = authStatus === messaging.AuthorizationStatus.AUTHORIZED;
    
    if (!enabled) {
      console.log('❌ [FAILURE] Notifications not properly authorized for background delivery');
      Alert.alert(
        'Notifications Required',
        'To receive important updates when the app is closed, please:\n\n1. Go to Settings\n2. Find this app\n3. Enable Notifications\n4. Allow "Background App Refresh" (iOS)\n5. Restart the app',
        [{ text: 'OK', style: 'default' }]
      );
    }
    
    return authStatus;
  } catch (error) {
    console.error('❌ [ERROR] Error requesting notification permission:', error);
    return messaging.AuthorizationStatus.DENIED;
  }
};

/**
 * Gets the device's FCM token and saves it to Firestore.
 * This verifies that notifications can be delivered.
 */
const getAndSaveToken = async () => {
  console.log('➡️ [STEP 2] Attempting to get FCM token (REAL permission test)...');
  try {
    const app = getApp();
    const messagingInstance = messaging(app);
    
    // This is the actual test - if notifications are disabled, this will fail or return null
    const token = await messagingInstance.getToken();
    
    if (token) {
      console.log('✅ [SUCCESS] FCM Token received - notifications are ACTUALLY enabled!');
      console.log('ℹ️ [INFO] Token:', token.substring(0, 20) + '...');
      await saveTokenToFirestore(token);
      return token;
    } else {
      console.log('❌ [FAILURE] FCM Token is null - notifications are ACTUALLY disabled!');
      
      Alert.alert(
        'Notifications Disabled',
        'Notifications are currently disabled. For background notifications to work:\n\n1. Go to Settings\n2. Find this app\n3. Enable Notifications\n4. Allow "Background App Refresh" (iOS)\n5. Restart the app',
        [{ text: 'OK', style: 'default' }]
      );
      
      return null;
    }
  } catch (error) {
    console.error('❌ [ERROR] Error getting FCM token - notifications are ACTUALLY disabled!');
    console.error('❌ [ERROR] Error details:', error);
    
    Alert.alert(
      'Notifications Setup Failed',
      'Unable to set up notifications. Please check:\n\n1. Notification permissions in Settings\n2. Background App Refresh (iOS)\n3. Battery optimization settings (Android)\n4. Restart the app after enabling',
      [{ text: 'OK', style: 'default' }]
    );
    
    return null;
  }
};

/**
 * Sets up background message handler for when app is in background/quit state.
 * This must be called at the top level, outside of any component.
 */
export const setupBackgroundMessageHandler = () => {
  messaging().setBackgroundMessageHandler(async (remoteMessage) => {
    console.log('📱 [BACKGROUND] Background FCM Message received:', remoteMessage);
    // Background messages are handled by the system automatically
    // You can perform background processing here if needed
    
    // Optional: Save message to local storage for when app reopens
    // await saveMessageLocally(remoteMessage);
  });
};

/**
 * Initializes the notification service.
 * Uses token retrieval as the reliable way to check if notifications are enabled.
 */
export const initializeNotifications = async () => {
  console.log('🔄 [INIT] Starting notification initialization...');
  
  // Step 1: Request permission (important for background notifications)
  const permissionStatus = await requestUserPermission();
  console.log('ℹ️ [INFO] Permission API returned:', permissionStatus);
  
  // Step 2: The REAL test - try to get FCM token
  const token = await getAndSaveToken();
  
  if (token) {
    console.log('✅ [SUCCESS] Notifications are working! Setting up listeners...');
    
    // Set up token refresh listener
    const app = getApp();
    const messagingInstance = messaging(app);
    
    messagingInstance.onTokenRefresh(async (newToken) => {
      console.log('ℹ️ [INFO] FCM token was refreshed. Saving new token...');
      await saveTokenToFirestore(newToken);
    });
    
    // Set up background message handler
    setupBackgroundMessageHandler();
    
    return true;
  } else {
    console.log('❌ [FAILURE] Notifications are NOT working. Token retrieval failed.');
    console.log('💡 [HINT] User needs to enable notifications in device settings.');
    return false;
  }
};

/**
 * Sets up foreground message listener (when app is open and visible)
 */
export const setupForegroundListener = () => {
  const app = getApp();
  const messagingInstance = messaging(app);
  
  const unsubscribe = messagingInstance.onMessage(async (remoteMessage) => {
    console.log('📱 [FOREGROUND] Foreground FCM Message:', remoteMessage);
    
    // Only show alert if app is in foreground
    // Background/quit notifications are handled by the system
    Alert.alert(
      remoteMessage.notification?.title || 'New Message',
      remoteMessage.notification?.body,
      [{ text: 'OK', style: 'default' }]
    );
  });
  
  return unsubscribe;
};

/**
 * Sets up notification opened listener (when user taps on notification)
 */
export const setupNotificationOpenedListener = (onOpen) => {
  const app = getApp();
  const messagingInstance = messaging(app);
  
  // App opened from background state via notification
  messagingInstance.onNotificationOpenedApp(remoteMessage => {
    if (remoteMessage) {
      console.log('📱 [OPENED] Notification caused app to open from background state:', remoteMessage);
      onOpen(remoteMessage);
    }
  });

  // App opened from quit state via notification
  messagingInstance.getInitialNotification().then(remoteMessage => {
    if (remoteMessage) {
      console.log('📱 [OPENED] Notification caused app to open from quit state:', remoteMessage);
      onOpen(remoteMessage);
    }
  });
};

/**
 * Helper function to check current notification permissions
 */
export const checkNotificationPermissions = async () => {
  try {
    const app = getApp();
    const messagingInstance = messaging(app);
    
    // Only check current permission status, don't request
    const authStatus = await messagingInstance.hasPermission();
    
    console.log('ℹ️ [PERMISSION CHECK] Current permission status:', {
      authStatus,
      isAuthorized: authStatus === messaging.AuthorizationStatus.AUTHORIZED
    });
    
    return {
      authStatus,
      isAuthorized: authStatus === messaging.AuthorizationStatus.AUTHORIZED
    };
  } catch (error) {
    console.error('❌ [ERROR] Error checking notification permissions:', error);
    return {
      authStatus: messaging.AuthorizationStatus.DENIED,
      isAuthorized: false
    };
  }
};