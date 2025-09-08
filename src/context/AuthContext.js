// src/context/AuthContext.js
import React, { createContext, useState, useContext, useEffect, useMemo, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { auth as firebaseAuth } from '../config/firebaseClient'; // Import Firebase auth instance
import { GoogleSignin } from '@react-native-google-signin/google-signin'; // Import GoogleSignin directly
import { signOut as googleSignOut } from '../config/AuthService';

// Define the Auth Context
export const AuthContext = createContext({
  userToken: null, // Stores user token or null if not logged in
  isLoading: true, // Indicates if the app is currently checking auth status
  signIn: async (token) => { }, // Function to log in
  signOut: async () => { }, // Function to log out
});

// Auth Provider Component
export const AuthProvider = ({ children }) => {
  const [userToken, setUserToken] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load user token from AsyncStorage on app start
  useEffect(() => {
    const loadUserToken = async () => {
      console.log('AuthContext: useEffect - Attempting to load user token from storage.');
      try {
        const token = await AsyncStorage.getItem('userToken');
        if (token) {
          // Verify with Firebase if this token corresponds to an active session
          // This step is optional but good for robustness. For now, we trust the stored token.
          // If Firebase auth state is also checked (e.g., in App.jsx), that can handle discrepancies.
          setUserToken(token);
          console.log('AuthContext: useEffect - Token loaded from storage:', token);
        } else {
          console.log('AuthContext: useEffect - No token found in storage.');
        }
      } catch (e) {
        console.error('AuthContext: Failed to load user token from storage:', e);
      } finally {
        setIsLoading(false);
        console.log('AuthContext: useEffect - Finished loading, isLoading set to false.');
      }
    };
    loadUserToken();
  }, []);

  // Function to handle user sign-in
  const signIn = useCallback(async (token) => {
    try {
      if (!token) {
        console.error('AuthContext: signIn - Called with null or undefined token. Aborting.');
        return;
      }
      await AsyncStorage.setItem('userToken', token);
      setUserToken(token);
      console.log('AuthContext: signIn - Token successfully set in AsyncStorage and state.');
    } catch (e) {
      console.error('AuthContext: Failed to save user token during signIn:', e);
    }
  }, []);

  // Function to handle user sign-out
  const signOut = useCallback(async () => {
    console.log('AuthContext: signOut - Attempting to sign out.');
    try {
      // 1. Clear Google Sign-In session completely
      try {


        await googleSignOut();


        // Additional cleanup - clear any cached user info
        try {
          await GoogleSignin.clearCachedAccessToken('');
        } catch (clearError) {
          console.log('AuthContext: signOut - No cached token to clear or already cleared.');
        }

      } catch (googleError) {
        console.error('AuthContext: signOut - Google sign out failed:', googleError);
        // Continue with other sign out steps even if Google sign out fails
      }

      // 2. Sign out from Firebase
      await firebaseAuth.signOut();
      console.log('AuthContext: signOut - Successfully signed out from Firebase.');

      // 3. Remove token from AsyncStorage
      await AsyncStorage.removeItem('userToken');
      console.log('AuthContext: signOut - Token removed from AsyncStorage.');

      // 4. Set userToken in context to null
      setUserToken(null);
      console.log('AuthContext: signOut - userToken set to null in context.');
    } catch (e) {
      console.error('AuthContext: Failed during signOut process:', e);
      // Even if Firebase signout fails, attempt to clear local state
      try {
        await AsyncStorage.removeItem('userToken');
        setUserToken(null);
      } catch (clearError) {
        console.error('AuthContext: Failed to clear local token after signOut error:', clearError);
      }
    }
  }, []);

  const contextValue = useMemo(() => ({
    userToken,
    isLoading,
    signIn,
    signOut,
  }), [userToken, isLoading, signIn, signOut]);

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  return useContext(AuthContext);
};
