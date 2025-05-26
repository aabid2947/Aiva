// src/components/AuthInput.js
import React from 'react';
import { TextInput, StyleSheet } from 'react-native';

const AuthInput = ({ placeholder, ...props }) => {
  return (
    <TextInput
      style={styles.input}
      placeholder={placeholder}
      placeholderTextColor="#aaa"
      autoCapitalize="none"
      {...props}
    />
  );
};

const styles = StyleSheet.create({
  input: {
    height: 50,
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 15,
    marginBottom: 15,
    width: '100%',
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
});

export default AuthInput;