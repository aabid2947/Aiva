// src/navigation/AppNavigator.js
import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import HomeScreen from '../screens/App/HomeScreen'; // Your chat UI

const AppStack = createStackNavigator();

const AppNavigator = () => {
  return (
    <AppStack.Navigator screenOptions={{ headerShown: false }}>
      <AppStack.Screen name="Home" component={HomeScreen} />
      {/* Add other authenticated screens here */}
    </AppStack.Navigator>
  );
};

export default AppNavigator;