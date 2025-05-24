import React, { createContext, useState, useContext, useEffect, useMemo, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Define the Auth Context
export const AuthContext = createContext({
  userToken: null, // Stores user token or null if not logged in
  isLoading: true, // Indicates if the app is currently checking auth status
  signIn: async (token) => {}, // Function to log in
  signOut: async () => {}, // Function to log out
});

// Auth Provider Component
export const AuthProvider = ({ children }) => {
  const [userToken, setUserToken] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load user token from AsyncStorage on app start
  useEffect(() => {
    const loadUserToken = async () => {
      try {
        const token = await AsyncStorage.getItem('userToken');
        if (token) {
          setUserToken(token);
        }
      } catch (e) {
        console.error('Failed to load user token from storage:', e);
      } finally {
        setIsLoading(false); // Authentication check is complete
      }
    };
    loadUserToken();
  }, []);

  // Function to handle user sign-in
  const signIn = useCallback(async (token) => {
    try {
      await AsyncStorage.setItem('userToken', token);
      setUserToken(token);
    } catch (e) {
      console.error('Failed to save user token:', e);
      // Handle error, maybe show an alert to the user
    }
  }, []);

  // Function to handle user sign-out
  const signOut = useCallback(async () => {
    try {
      await AsyncStorage.removeItem('userToken');
      setUserToken(null);
    } catch (e) {
      console.error('Failed to remove user token:', e);
      // Handle error
    }
  }, []);

  // Memoize the context value to prevent unnecessary re-renders
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

// Custom hook to consume the Auth Context easily
export const useAuth = () => {
  return useContext(AuthContext);
};