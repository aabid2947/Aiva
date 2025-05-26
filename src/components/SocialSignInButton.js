// src/components/SocialSignInButton.js
import React from 'react';
import { TouchableOpacity, Text, Image, StyleSheet } from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign'; // Or your specific icon library

const SocialSignInButton = ({ provider, onPress }) => {
  let iconComponent;
  let buttonText;
  let buttonStyle = {};

  switch (provider) {
    case 'google':
      iconComponent = <AntDesign name="google" size={24} color="#4285F4" />;
      buttonText = 'Sign in with Google'; // Changed for consistency with your English translation
      break;
    case 'apple':
      iconComponent = <AntDesign name="apple1" size={24} color="#000" />;
      buttonText = 'Sign in with Apple ID'; // Changed for consistency
      break;
    case 'facebook':
      iconComponent = <AntDesign name="facebook-square" size={24} color="#3b5998" />;
      buttonText = 'Sign in with Facebook'; // Changed for consistency
      break;
    default:
      iconComponent = <AntDesign name="star" size={24} color="#000" />;
      buttonText = 'Sign in with ' + provider;
  }

  return (
    <TouchableOpacity style={[styles.button, buttonStyle]} onPress={onPress}>
      {iconComponent}
      <Text style={styles.buttonText}>{buttonText}</Text> {/* <-- FIXED: Wrapped buttonText in <Text> */}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    width: '100%',
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    backgroundColor: '#f5f5f5',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 10,
    color: '#333',
  },
  // Add specific styles if you want different backgrounds/borders for each social button
});

export default SocialSignInButton;