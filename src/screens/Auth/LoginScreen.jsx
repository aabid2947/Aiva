// src/screens/Auth/LoginScreen.js
import React, { useState } from 'react';
import { View, Text, StyleSheet, ActivityIndicator, Alert, TouchableOpacity } from 'react-native';
import firebase from '@react-native-firebase/app';
import '@react-native-firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin'; // Corrected import path
import { googleSignInConfig } from '../../config/firebaseClient'; // Your Google Sign-In client config
import { loginUserBackendVerification } from '../../api/auth'; // Your backend API call for token verification
import AuthButton from '../../components/AuthButton';
import AuthInput from '../../components/AuthInput';
import SocialSignInButton from '../../components/SocialSignInButton';
import { useNavigation } from '@react-navigation/native';

// Initialize Google Sign-In for Firebase (Do this once in your App.js or similar entry point, or here if this is the only place used)
GoogleSignin.configure(googleSignInConfig);

const LoginScreen = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const navigation = useNavigation();

  const handleEmailLogin = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Please enter both email and password.');
      return;
    }

    setLoading(true);
    try {
      // 1. Authenticate with Firebase CLIENT SDK
      const userCredential = await firebase.auth().signInWithEmailAndPassword(email, password);
      const user = userCredential.user;
      const idToken = await user.getIdToken(); // Get the ID token from Firebase

      // 2. Send ID token to your backend for verification and any custom logic
      const backendResponse = await loginUserBackendVerification(idToken);
      console.log('Backend verification successful:', backendResponse);

      // App.js's onAuthStateChanged listener will handle navigation after successful login
      Alert.alert('Success', 'Logged in successfully!');
    } catch (error) {
      console.error('Email Login Error:', error);
      let errorMessage = 'Login failed. Please check your credentials.';
      if (error.code) {
        switch (error.code) {
          case 'auth/invalid-email':
            errorMessage = 'Invalid email format.';
            break;
          case 'auth/user-not-found':
          case 'auth/wrong-password':
            errorMessage = 'Invalid email or password.';
            break;
          case 'auth/network-request-failed':
            errorMessage = 'Network error. Please check your internet connection.';
            break;
          default:
            errorMessage = error.message || 'An unknown error occurred.';
            break;
        }
      }
      Alert.alert('Login Failed', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setLoading(true);
    try {
      // 1. Get the user's ID token from Google
      await GoogleSignin.hasPlayServices();
      const { idToken } = await GoogleSignin.signIn();

      // 2. Create a Firebase credential with the Google ID token
      const googleCredential = firebase.auth.GoogleAuthProvider.credential(idToken);

      // 3. Sign in to Firebase with the credential
      const userCredential = await firebase.auth().signInWithCredential(googleCredential);
      const user = userCredential.user;
      const firebaseIdToken = await user.getIdToken();

      // 4. Send Firebase ID token to your backend for verification
      const backendResponse = await loginUserBackendVerification(firebaseIdToken);
      console.log('Google Login (Backend Verified):', backendResponse);

      Alert.alert('Success', 'Logged in with Google successfully!');
    } catch (error) {
      console.error('Google Login Error:', error);
      let errorMessage = 'Google login failed. Please try again.';
      if (error.code === 'auth/account-exists-with-different-credential') {
        errorMessage = 'An account with this email already exists using a different sign-in method.';
      } else if (error.code === GoogleSignin.hasPlayServices.name // Play services not available
        ) { // Fixed the condition here
          errorMessage = 'Google Play Services not available or outdated.';
        } else if (error.code === 'auth/network-request-failed') {
          errorMessage = 'Network error during Google login.';
        } else if (error.code === 'auth/operation-not-allowed') {
          errorMessage = 'Google sign-in is not enabled in Firebase. Enable it in your Firebase console.';
        } else if (error.code === 'auth/cancelled-by-user') {
          // User cancelled the login flow
          errorMessage = 'Google sign-in cancelled.';
        }
      Alert.alert('Google Login Failed', errorMessage);
    } finally {
      setLoading(false);
    }
  };


  return (
    <View style={styles.container}>
      <Text style={styles.logo}>MUSICAPP</Text> {/* Your App Logo/Name */}
      <Text style={styles.subtitle}>Access your account</Text> {/* Translated */}

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

      <TouchableOpacity style={styles.forgotPasswordButton}>
        <Text style={styles.forgotPasswordText}>Forgot password?</Text> {/* Translated */}
      </TouchableOpacity>

      <AuthButton title="Login" onPress={handleEmailLogin} disabled={loading} /> {/* Translated */}

      <TouchableOpacity
        style={styles.signupButton}
        onPress={() => navigation.navigate('Signup')}
      >
        <Text style={styles.signupText}>Don't have an account? Create one now</Text> {/* Translated */}
      </TouchableOpacity>

      <Text style={styles.orText}>OR</Text> {/* Translated */}

      {/* Social Sign-in Buttons */}
      <SocialSignInButton
        provider="google"
        onPress={handleGoogleLogin}
      />
      {/* Implement Apple/Facebook similarly if needed */}
      <SocialSignInButton
        provider="apple"
        onPress={() => Alert.alert('Coming Soon', 'Apple Login')}
      />
      <SocialSignInButton
        provider="facebook"
        onPress={() => Alert.alert('Coming Soon', 'Facebook Login')}
      />

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
  forgotPasswordButton: {
    alignSelf: 'flex-end',
    marginBottom: 20,
  },
  forgotPasswordText: {
    color: '#007bff',
    fontSize: 14,
  },
  signupButton: {
    marginTop: 15,
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#007bff',
    width: '100%',
    alignItems: 'center',
  },
  signupText: {
    color: '#007bff',
    fontSize: 16,
    fontWeight: '600',
  },
  orText: {
    marginVertical: 20,
    color: '#888',
    fontSize: 16,
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default LoginScreen;