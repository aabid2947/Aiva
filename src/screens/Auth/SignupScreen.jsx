// src/screens/Auth/SignupScreen.js
import React, { useState } from 'react';
import { View, Text, StyleSheet, ActivityIndicator, Alert, TouchableOpacity } from 'react-native';
import { signupUserBackend } from '../../api/auth'; // API call to your backend
import AuthButton from '../../components/AuthButton';
import AuthInput from '../../components/AuthInput';
import { useNavigation } from '@react-navigation/native';

const SignupScreen = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const navigation = useNavigation();

  const handleSignup = async () => {
    if (!email || !password || !confirmPassword) {
      Alert.alert('Error', 'All fields are required.');
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert('Error', 'Passwords do not match.');
      return;
    }
    if (password.length < 6) { // Firebase default minimum password length for client-side
        Alert.alert('Error', 'Password must be at least 6 characters long.');
        return;
    }

    setLoading(true);
    try {
      // Direct signup via your backend API
      const response = await signupUserBackend(email, password); // displayName can be added here
      console.log('Signup successful:', response);
      Alert.alert('Success', 'Account created successfully! You can now log in.');
      navigation.navigate('Login'); // Navigate to login after successful signup
    } catch (error) {
      console.error('Signup Error:', error);
      let errorMessage = 'Signup failed. Please try again.';
      // Your backend's errorHandler should return specific messages
      if (error.message) {
        errorMessage = error.message;
      }
      Alert.alert('Signup Failed', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.logo}>MUSICAPP</Text> {/* Your App Logo/Name */}
      <Text style={styles.subtitle}>Create your account</Text> {/* Translated */}

      <AuthInput
        placeholder="Email" // Translated
        keyboardType="email-address"
        value={email}
        onChangeText={setEmail}
      />
      <AuthInput
        placeholder="Password" // Translated
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />
      <AuthInput
        placeholder="Confirm Password" // Translated
        secureTextEntry
        value={confirmPassword}
        onChangeText={setConfirmPassword}
      />

      <AuthButton title="Create Account" onPress={handleSignup} disabled={loading} /> {/* Translated */}

      <TouchableOpacity
        style={styles.loginButton}
        onPress={() => navigation.navigate('Login')}
      >
        <Text style={styles.loginText}>Already have an account? Login</Text> {/* Translated */}
      </TouchableOpacity>

      {loading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#007bff" />
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#fff',
  },
  logo: {
    fontSize: 32,
    fontWeight: 'bold',
    marginBottom: 30,
    color: '#333',
  },
  subtitle: {
    fontSize: 18,
    marginBottom: 20,
    color: '#555',
  },
  loginButton: {
    marginTop: 15,
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#007bff',
    width: '100%',
    alignItems: 'center',
  },
  loginText: {
    color: '#007bff',
    fontSize: 16,
    fontWeight: '600',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default SignupScreen;