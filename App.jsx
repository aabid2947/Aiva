// App.jsx
import React, { useEffect } from 'react';
import { Platform, Linking, Alert } from 'react-native';
import { checkNotificationPermissions, requestUserPermission } from './src/services/notificationService.js';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { AuthProvider, useAuth } from './src/context/AuthContext.js'; // Adjust path if needed
import LoginSignupScreen from './src/screens/Auth/LoginSignupScreen.jsx'; // Adjust path if needed
import HomeScreen from './src/screens/App/HomeScreen.jsx'; // Adjust path if needed
import SplashScreen from './src/screens/App/SplashScreen.jsx'; // Create a simple SplashScreen component
// import PaymentScreen from './src/screens/App/PaymentScreen.jsx';
import { onAuthStateChanged } from './src/config/firebaseClient.js'; // Use wrapper function

const Stack = createNativeStackNavigator();

// This component will decide which stack of screens to show
const openNotificationSettings = () => {
  if (Platform.OS === 'ios') {
    Linking.openURL('app-settings:');
  } else {
    Linking.openSettings();
  }
};

const RootNavigator = () => {
  const { userToken, isLoading, signIn, signOut } = useAuth();

  // Optional: Listen to Firebase's onAuthStateChanged to keep AuthContext in sync
  // This is particularly useful if the token might expire or be revoked externally,
  // or if you want to auto-sign-in if Firebase still has an active session
  // that AuthContext might have missed on initial load (e.g., if AsyncStorage was cleared).

  // Check notification permission on app load
  useEffect(() => {
    (async () => {
      try {
        const { isAuthorized, authStatus } = await checkNotificationPermissions();
        if (!isAuthorized) {
          // Always show alert and open settings if not authorized
          Alert.alert(
            'Notifications are disabled',
            'To receive important updates, please enable notifications for this app in your device settings.',
            [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Open Settings', onPress: openNotificationSettings }
            ]
          );
        }
      } catch (e) {
        console.error('Error checking notification permission:', e);
      }
    })();
  }, []);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(async (firebaseUser) => {
      if (firebaseUser) {
        console.log('App.jsx: Firebase Auth State Changed: User is logged in.', firebaseUser.uid);
        if (!userToken) { // If our context doesn't have a token but Firebase does
          try {
            const idToken = await firebaseUser.getIdToken();
            console.log('App.jsx: Firebase user found, but no context token. Signing in context with new Firebase token.');
            await signIn(idToken); // Sync AuthContext
          } catch (error) {
            console.error('App.jsx: Error getting idToken on auth state change:', error);
            // Potentially sign out if token retrieval fails
            await signOut();
          }
        }
      } else {
        console.log('App.jsx: Firebase Auth State Changed: User is logged out.');
        if (userToken) { // If context has a token but Firebase doesn't
          console.log('App.jsx: Firebase user not found, but context token exists. Signing out context.');
          await signOut(); // Sync AuthContext - the signOut function now handles duplicate calls
        }
      }
    });
    return () => unsubscribe(); // Cleanup on unmount
  }, [userToken, signIn, signOut]);


  if (isLoading) {
    return <SplashScreen />; // Or any other loading indicator component
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {userToken == null ? (
          // No token found, user isn't signed in according to AuthContext
          <Stack.Screen name="LoginSignup" component={LoginSignupScreen} />
        ) : (
          // User is signed in according to AuthContext
          <Stack.Screen name="Home" component={HomeScreen} />
          // You can add other authenticated screens here within this "authenticated" stack
          // For example:
          // <Stack.Screen name="Profile" component={ProfileScreen} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

const App = () => {
  return (
    <AuthProvider>
      <RootNavigator />
    </AuthProvider>
  );
};

export default App;
