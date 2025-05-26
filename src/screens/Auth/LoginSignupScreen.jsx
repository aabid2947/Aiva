import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ImageBackground,
  StyleSheet,
  SafeAreaView,
  Image,
  Dimensions,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ActivityIndicator,
  ScrollView, // Import ScrollView
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

import { useAuth } from '../../context/AuthContext';
import {
  signupUserBackend,
  loginUserBackendVerification,
} from '../../api/auth';

import { auth as firebaseAuth, googleSignInConfig } from '../../config/firebaseClient';
import { GoogleSignin } from '@react-native-google-signin/google-signin';

GoogleSignin.configure({
  webClientId: googleSignInConfig.webClientId,
  offlineAccess: googleSignInConfig.offlineAccess,
});

const { width } = Dimensions.get('window');

// --- Reusable Components ---

const CustomTextInput = ({ iconName, placeholder, value, onChangeText, secureTextEntry, keyboardType, onToggleSecure, editable }) => {
  return (
    <View style={styles.inputContainer}>
      <Icon name={iconName} size={20} color="#888" style={styles.inputIcon} />
      <TextInput
        style={styles.inputField}
        placeholder={placeholder}
        value={value}
        onChangeText={onChangeText}
        secureTextEntry={secureTextEntry}
        keyboardType={keyboardType}
        placeholderTextColor="#888"
        autoCapitalize="none"
        editable={editable}
      />
      {secureTextEntry !== undefined && (
        <TouchableOpacity onPress={onToggleSecure} style={styles.eyeIcon} disabled={!editable}>
          <Icon name={secureTextEntry ? "eye-off-outline" : "eye-outline"} size={20} color="#888" />
        </TouchableOpacity>
      )}
    </View>
  );
};

const SocialButton = ({ iconName, text, onPress, buttonStyle, textStyle, disabled }) => (
  <TouchableOpacity style={[styles.socialButton, buttonStyle]} onPress={onPress} disabled={disabled}>
    <Icon name={iconName} size={22} color="#333" style={styles.socialButtonIcon} />
    <Text style={[styles.socialButtonText, textStyle]}>{text}</Text>
  </TouchableOpacity>
);

// --- Main Screen Component ---

const LoginSignupScreen = ({ navigation }) => {
  const { signIn } = useAuth();
  const [mode, setMode] = useState('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isPasswordSecure, setIsPasswordSecure] = useState(true);
  const [isConfirmPasswordSecure, setIsConfirmPasswordSecure] = useState(true);
  const [loading, setLoading] = useState(false);

  const handleSignIn = async () => {
    setLoading(true);
    try {
      const userCredential = await firebaseAuth.signInWithEmailAndPassword(email, password);
      const idToken = await userCredential.user.getIdToken();

      const backendResponse = await loginUserBackendVerification(idToken);
      console.log('Backend Login Verification Success:', backendResponse);

      await signIn(idToken);
    } catch (error) {
      console.error('Sign In Error:', error.code, error.message);
      let errorMessage = 'Failed to sign in. Please try again.';
      if (error.code === 'auth/invalid-email') {
        errorMessage = 'That email address is invalid!';
      } else if (error.code === 'auth/wrong-password' || error.code === 'auth/user-not-found') {
        errorMessage = 'Invalid email or password.';
      } else if (error.code === 'auth/network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      // Alert.alert('Sign In Error', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async () => {
    setLoading(true);
    if (password !== confirmPassword) {
      Alert.alert("Sign Up Error", "Passwords do not match!");
      setLoading(false);
      return;
    }

    try {
      const userCredential = await firebaseAuth.createUserWithEmailAndPassword(email, password);
      const user = userCredential.user;
      const idToken = await user.getIdToken();

      const backendResponse = await signupUserBackend(email, password, null);
      console.log('Backend Sign Up Success:', backendResponse);

      await signIn(idToken);
    } catch (error) {
      console.error('Sign Up Error:', error.code, error.message);
      let errorMessage = 'Failed to create account. Please try again.';
      if (error.code === 'auth/email-already-in-use') {
        errorMessage = 'That email address is already in use!';
      } else if (error.code === 'auth/weak-password') {
        errorMessage = 'Password should be at least 6 characters.';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'That email address is invalid!';
      } else if (error.code === 'auth/network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      Alert.alert('Sign Up Error', errorMessage); // Changed to Alert.alert for user visibility
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setLoading(true);
    try {
      await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
      const { idToken } = await GoogleSignin.signIn();
      const googleCredential = firebaseAuth.GoogleAuthProvider.credential(idToken);
      const userCredential = await firebaseAuth.signInWithCredential(googleCredential);
      const firebaseIdToken = await userCredential.user.getIdToken();

      const backendResponse = await loginUserBackendVerification(firebaseIdToken);
      console.log('Backend Google Sign-In Verification Success:', backendResponse);

      await signIn(firebaseIdToken);

      Alert.alert('Success', 'Signed in with Google!');
    } catch (error) {
      console.error('Google Sign-In Error:', error.code, error.message);
      let errorMessage = 'Failed to sign in with Google. Please try again.';
      if (error.code === 'E_SIGN_IN_CANCELLED') {
        errorMessage = 'Google Sign-In was cancelled.';
      } else if (error.code === 'auth/network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      Alert.alert('Google Sign-In Error', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleAppleSignIn = () => {
    Alert.alert('Apple Sign-In', 'Apple Sign-In integration coming soon!');
  };

  return (
    <SafeAreaView style={styles.container}>
      <ImageBackground
        source={require('../../../assets/bg.jpg')}
        style={styles.container}
        resizeMode="cover"
      >
        <View style={styles.overlay} />

        {/* HEADER: This will stay fixed at the top */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Image source={require('../../../assets/AivaNobg.png')} style={styles.aivaLogo} resizeMode="contain" />
            <View>
              <Image source={require('../../../assets/AivaText.png')} style={styles.aivaTextLogo} resizeMode="contain" />
            </View>
          </View>
          <View></View>
        </View>

        {/* KEYBOARD AVOIDING CONTENT: This section will adapt to the keyboard */}
        <KeyboardAvoidingView
          style={styles.keyboardAvoidingView} // Takes up remaining space below header
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
        >
          {/* SCROLLVIEW: Allows content to scroll when keyboard is active */}
          <ScrollView
            contentContainerStyle={styles.scrollViewContentContainer}
            keyboardShouldPersistTaps="handled" // Important for keeping inputs focused
          >
            {/* Form Content: Actual elements of your login/signup form */}
            <View style={styles.formContent}>
              {/* Toggle Buttons (Sign In / Sign Up) */}
              <View style={styles.toggleButtonGroup}>
                <TouchableOpacity
                  style={[styles.toggleButton, mode === 'signin' && styles.activeToggleButton]}
                  onPress={() => setMode('signin')}
                  disabled={loading}
                >
                  <Text style={[styles.toggleButtonText, mode === 'signin' && styles.activeToggleButtonText]}>
                    Sign In
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.toggleButton, mode === 'signup' && styles.activeToggleButton]}
                  onPress={() => setMode('signup')}
                  disabled={loading}
                >
                  <Text style={[styles.toggleButtonText, mode === 'signup' && styles.activeToggleButtonText]}>
                    Sign Up
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Welcome / Create Account Text */}
              <Text style={styles.headerTitle}>
                {mode === 'signin' ? 'Welcome Back!' : 'Create Your Account'}
              </Text>
              <Text style={styles.headerSubtitle}>
                {mode === 'signin' ? 'Sign in to continue' : 'Enter your details to get started'}
              </Text>

              {/* Input Fields */}
              <CustomTextInput
                iconName="email-outline"
                placeholder="Email"
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                editable={!loading}
              />
              <CustomTextInput
                iconName="lock-outline"
                placeholder="Password"
                value={password}
                onChangeText={setPassword}
                secureTextEntry={isPasswordSecure}
                onToggleSecure={() => setIsPasswordSecure(!isPasswordSecure)}
                editable={!loading}
              />

              {mode === 'signup' && (
                <CustomTextInput
                  iconName="lock-outline"
                  placeholder="Confirm Password"
                  value={confirmPassword}
                  onChangeText={setConfirmPassword}
                  secureTextEntry={isConfirmPasswordSecure}
                  onToggleSecure={() => setIsConfirmPasswordSecure(!isConfirmPasswordSecure)}
                  editable={!loading}
                />
              )}

              {/* Forgot Password Link (for Sign In mode) */}
              {mode === 'signin' && (
                <TouchableOpacity
                  style={styles.forgotPasswordButton}
                  onPress={() => console.log('Forgot Password')}
                  disabled={loading}
                >
                  <Text style={styles.forgotPasswordText}>Forgot Password?</Text>
                </TouchableOpacity>
              )}

              {/* Primary Action Button */}
              <TouchableOpacity
                style={styles.primaryButton}
                onPress={mode === 'signin' ? handleSignIn : handleSignUp}
                disabled={loading}
              >
                {loading ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={styles.primaryButtonText}>
                    {mode === 'signin' ? 'Sign In' : 'Create Account'}
                  </Text>
                )}
              </TouchableOpacity>

              {/* OR Separator */}
              <View style={styles.orContainer}>
                <View style={styles.line} />
                <Text style={styles.orText}>OR</Text>
                <View style={styles.line} />
              </View>

              {/* Social Sign-in Buttons */}
              <SocialButton
                iconName="google"
                text="Continue with Google"
                onPress={handleGoogleSignIn}
                buttonStyle={styles.googleButton}
                textStyle={styles.googleButtonText}
                disabled={loading}
              />
              {Platform.OS === 'ios' && (
                <SocialButton
                  iconName="apple"
                  text="Continue with Apple"
                  onPress={handleAppleSignIn}
                  buttonStyle={styles.appleButton}
                  textStyle={styles.appleButtonText}
                  disabled={loading}
                />
              )}
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </ImageBackground>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff3d9',
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 243, 217, 0.85)',
    zIndex: 0,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
    zIndex: 1, // Ensures the header stays on top
  },
  headerLeft: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  aivaLogo: {
    width: 50,
    height: 50,
    tintColor: '#007BFF',
  },
  aivaTextLogo: {
    width: 100,
    height: 60,
    objectFit: 'cover',
  },
  // New style for KeyboardAvoidingView to take remaining space
  keyboardAvoidingView: {
    flex: 1, // Occupy all remaining vertical space below the header
    width: '100%',
  },
  // Style for the content *inside* the ScrollView
  scrollViewContentContainer: {
    flexGrow: 1, // Allows content to expand to fill available height, good for centering
    justifyContent: 'center', // Centers content vertically within the scrollable area
    paddingHorizontal: 25, // Apply horizontal padding here
    paddingVertical: 30, // Apply vertical padding here
  },
  // This view now specifically holds the form elements
  formContent: {
    width: '100%', // Ensure it takes full width of the scroll view
    alignItems: 'center', // Keep content centered horizontally within this view
  },
  // ... rest of your existing styles (toggleButtonGroup, inputContainer, primaryButton, etc.)
  toggleButtonGroup: {
    flexDirection: 'row',
    backgroundColor: 'rgb(250, 250, 250)',
    borderRadius: 36,
    padding: 5,
    marginBottom: 25,
  },
  toggleButton: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 25,
    alignItems: 'center',
    marginHorizontal: 2,
  },
  activeToggleButton: {
    backgroundColor: '#fff3d9',
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  toggleButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#888',
  },
  activeToggleButtonText: {
    color: '#000',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
    textAlign: 'center',
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 30,
    textAlign: 'center',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: 'rgb(41, 36, 36)',
    borderRadius: 24,
    paddingHorizontal: 15,
    marginVertical: 10,
    width: '100%',
    height: 65,
  },
  inputIcon: {
    marginRight: 10,
  },
  inputField: {
    flex: 1,
    height: '100%',
    color: '#333',
    fontSize: 16,
  },
  eyeIcon: {
    paddingLeft: 10,
  },
  forgotPasswordButton: {
    alignSelf: 'flex-end',
    marginTop: 5,
    marginBottom: 20,
  },
  forgotPasswordText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  primaryButton: {
    backgroundColor: '#007BFF',
    paddingVertical: 16,
    borderRadius: 24,
    alignItems: 'center',
    width: '70%',
    marginTop: 10,
    marginBottom: 20,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  orContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    marginVertical: 20,
  },
  line: {
    flex: 1,
    height: 1,
    backgroundColor: '#D0D0D0',
  },
  orText: {
    marginHorizontal: 10,
    fontSize: 14,
    color: '#888',
    fontWeight: '500',
  },
  socialButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    borderRadius: 12,
    width: '100%',
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#D0D0D0',
    backgroundColor: '#FFF',
  },
  socialButtonIcon: {
    marginRight: 10,
  },
  socialButtonText: {
    fontSize: 16,
    color: '#333',
    fontWeight: '600',
  },
  googleButton: {},
  googleButtonText: {},
  appleButton: {},
  appleButtonText: {},
});

export default LoginSignupScreen;