import React, { createContext, useState, useContext, useEffect, useMemo, useCallback } from 'react';
import { Appearance, useColorScheme } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage'; // For persisting theme

// Define your theme colors
export const light = {
  colors: {
    primary: '#007AFF', // Example primary button/accent color
    background: '#F0F2F5', // Light background
    card: '#FFFFFF', // Card/container background
    text: '#333333', // Dark text
    border: '#E0E0E0', // Light borders
    notification: '#FF3B30',
    inputBackground: '#F8F8F8',
    inputText: '#333333',
    buttonPrimary: '#007AFF',
    buttonSecondary: '#6c757d',
    buttonText: '#FFFFFF',
    link: '#007AFF',
  },
  statusBarStyle: 'dark-content', // Status bar text color
};

export const dark = {
  colors: {
    primary: '#BB86FC', // Example primary button/accent color (more vibrant for dark mode)
    background: '#121212', // Dark background
    card: '#1E1E1E', // Dark card/container background
    text: '#FFFFFF', // Light text
    border: '#333333', // Dark borders
    notification: '#CF6679',
    inputBackground: '#2C2C2C',
    inputText: '#FFFFFF',
    buttonPrimary: '#BB86FC',
    buttonSecondary: '#4A4A4A',
    buttonText: '#FFFFFF',
    link: '#BB86FC',
  },
  statusBarStyle: 'light-content', // Status bar text color
};

// Create the Theme Context
export const ThemeContext = createContext({
  theme: light, // Default theme
  toggleTheme: () => {}, // Function to toggle theme
  isDarkTheme: false, // Indicates if the current theme is dark
});

// Theme Provider Component
export const ThemeProvider = ({ children }) => {
  // Get the system's preferred color scheme
  const systemColorScheme = useColorScheme(); // 'light' or 'dark'

  // State to hold the current theme preference ('light', 'dark', or 'system')
  const [theme, setTheme] = useState('light'); // null initially, to load from storage

  // Determine the effective theme based on preference and system setting
  const isDarkTheme = useMemo(() => {
    if (theme === 'dark') {
      return true;
    }
    if (theme === 'light') {
      console.log(9899)
      return false;
    }
    // If theme is 'system' or null (initial load), use system preference
    return systemColorScheme === 'dark';
  }, [theme, systemColorScheme]);

  const currentTheme = useMemo(() => (isDarkTheme ? dark : light), [isDarkTheme]);

  // Load theme preference from AsyncStorage on mount
  useEffect(() => {
    const loadTheme = async () => {
      try {
        const storedTheme = await AsyncStorage.getItem('theme');
        if (storedTheme) {
          setTheme(storedTheme);
        } else {
          // If no preference is stored, default to 'system'
          setTheme('system');
        }
      } catch (e) {
        console.error('Failed to load theme preference from storage', e);
        setTheme('system'); // Fallback to system
      }
    };
    loadTheme();
  }, []);

  // Handle system theme changes (if preference is 'system')
  useEffect(() => {
    const subscription = Appearance.addChangeListener(({ colorScheme }) => {
      if (theme === 'system') {
        // Force re-evaluation of currentTheme
        setTheme('system'); // Setting to 'system' again triggers re-memoization
      }
    });
    return () => subscription.remove();
  }, [theme]);

  // Function to toggle theme (and save preference)
  const toggleTheme = useCallback(async () => {
    const newPreference = isDarkTheme ? 'light' : 'dark'; // Toggle to opposite of current effective theme
    try {
      await AsyncStorage.setItem('theme', newPreference);
      setTheme(newPreference);
    } catch (e) {
      console.error('Failed to save theme preference to storage', e);
    }
  }, [isDarkTheme]);

  // Provide the theme and toggle function to children
  const contextValue = useMemo(() => ({
    theme: currentTheme,
    toggleTheme,
    isDarkTheme,
  }), [currentTheme, toggleTheme, isDarkTheme]);

  // Render children only after theme preference has been loaded
  if (theme === null) {
    return null; // Or a loading spinner
  }

  return (
    <ThemeContext.Provider value={contextValue}>
      {children}
    </ThemeContext.Provider>
  );
};

// Custom hook to use the theme context
export const useTheme = () => useContext(ThemeContext);