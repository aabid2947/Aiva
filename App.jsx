import 'react-native-gesture-handler'; // Required for @react-navigation/stack
import React, { useEffect, useState } from 'react';
import { ActivityIndicator, View, StyleSheet, StatusBar } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import AuthNavigator from './src/navigation/AuthNavigator'; // For unauthenticated users
import AppNavigator from './src/navigation/AppNavigator';   // For authenticated users
import firebase from '@react-native-firebase/app';
import '@react-native-firebase/auth';
import { firebaseConfig } from './src/config/firebaseClient'; // Your client-side Firebase config
import { retrieveData, storeData, removeData } from './src/utils/asyncStorage'; // For storing tokens/user data
// No need to import './src/config/firebaseClient'; again as it's already used for firebaseConfig and firebase import.
import SplashScreen from './src/screens/App/SplashScreen'; // Your splash screen component
import { AuthProvider } from './src/context/AuthContext'; // Import AuthProvider

// Initialize Firebase Client SDK (only if it hasn't been initialized)
if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
  console.log('Firebase Client SDK initialized.');
} else {
  firebase.app(); // if already initialized, use that one
  console.log('Firebase Client SDK already initialized.');
}

const App = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isAppLoading, setIsAppLoading] = useState(true); // Manages initial app loading (Firebase check)
  const [showSplash, setShowSplash] = useState(true); // Manages splash screen visibility

  useEffect(() => {
    // Timer to hide the splash screen after 2.5 seconds
    const splashTimer = setTimeout(() => {
      setShowSplash(false);
    }, 2500); // Same duration as in SplashScreen.jsx

    // Firebase Auth listener: this is the primary way to manage auth state in client-side
    // It automatically updates when user signs in, signs out, or token refreshes.
    const authSubscriber = firebase.auth().onAuthStateChanged(async user => {
      if (user) {
        console.log('Firebase Auth State Changed: User is logged in.', user.uid);
        setIsAuthenticated(true);
        // Ensure the ID token is stored in AsyncStorage if needed by AuthContext
        const idToken = await user.getIdToken();
        await storeData('userToken', idToken);
      } else {
        console.log('Firebase Auth State Changed: User is logged out.');
        setIsAuthenticated(false);
        await removeData('userToken'); // Clear token on logout
      }
      setIsAppLoading(false); // Authentication status is now known, and main app can load
    });

    // Clean up timers and subscriptions on unmount
    return () => {
      clearTimeout(splashTimer);
      authSubscriber();
    };
  }, []);

  if (showSplash || isAppLoading) {
    // Show splash screen while it's active OR while Firebase auth state is being determined
    // This ensures no flickering if auth check is quick
    return <SplashScreen />;
  }

  // Once splash is hidden and auth state is determined, render the appropriate navigator
  return (
    <AuthProvider>
      <NavigationContainer>
        <StatusBar barStyle="dark-content" backgroundColor="#fff" />
        {isAuthenticated ? <AppNavigator /> : <AuthNavigator />}
      </NavigationContainer>
    </AuthProvider>
  );
};

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
  },
});

export default App;