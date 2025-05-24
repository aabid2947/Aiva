import 'react-native-gesture-handler'; // Important for React Navigation
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { AuthProvider } from './src/context/AuthContext';
// Import your screen components
import HomeScreen from './src/screens/HomeScreen';
import LoginScreen from './src/screens/LoginScreen';
import SignupScreen from './src/screens/SignupScreen';
import { ThemeProvider } from './src/context/ThemeContext';
const Stack = createStackNavigator();

const App = () => {
  return (
    <AuthProvider>
<ThemeProvider>
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login">
        {/*
          initialRouteName determines which screen is shown first when the app launches.
          You might want 'Login' or 'Signup' initially, and 'Home' after authentication.
        */}
        <Stack.Screen
          name="Login"
          component={LoginScreen}
          options={{ headerShown: false }} // Hides the header bar for Login
        />
        <Stack.Screen
          name="Signup"
          component={SignupScreen}
          options={{ headerShown: false }} // Hides the header bar for Signup
        />
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          // You might want to hide the back button to Login/Signup from Home
          // options={{ headerLeft: null, title: 'Dashboard' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
    </ThemeProvider>

        </AuthProvider>
  );
};

export default App;