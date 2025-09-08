// LoginSignupScreen.jsx
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
  ScrollView,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import authModule from '@react-native-firebase/auth';
import { signOut as googleSignOut } from '../../config/AuthService';

import { useAuth } from '../../context/AuthContext';
import {
  signupUserBackend,
  loginUserBackendVerification,
} from '../../api/auth';
import CustomAlertDialog from '../../components/CustomAlert.jsx';
// Correctly import auth instance and the new googleSignInConfig
import { auth  as firebaseAuth } from '../../config/firebaseClient';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import {
  GOOGLE_WEB_CLIENT_ID // For Google Sign-In
} from '@env';
// Configure Google Sign-In once at the top level

// --- Reusable Components (UI is unchanged) ---
const CustomTextInput = ({ iconName, placeholder, value, onChangeText, secureTextEntry, onToggleSecure, editable }) => {
  return (
    <View style={styles.inputContainer}>
      <Icon name={iconName} size={20} color="#888" style={styles.inputIcon} />
      <TextInput
        style={styles.inputField}
        placeholder={placeholder}
        value={value}
        onChangeText={onChangeText}
        secureTextEntry={secureTextEntry}
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
  <TouchableOpacity style={[styles.socialButton, buttonStyle, disabled && styles.disabledButton]} onPress={onPress} disabled={disabled}>
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
  const [alertVisible, setAlertVisible] = useState(false);
  const [alertMessage, setAlertMessage] = useState('');

  const handleSignIn = async () => {
    setLoading(true);
    try {
      const userCredential = await firebaseAuth.signInWithEmailAndPassword(email, password);
      const idToken = await userCredential.user.getIdToken();

      // const backendResponse = await loginUserBackendVerification(idToken);
      // console.log('Backend Login Verification Success:', backendResponse);

      await signIn(idToken);
    } catch (error) {
      console.error('Sign In Error:', error.code, error.message);
      let errorMessage = 'Failed to sign in. Please check your credentials.';
      if (error.code === 'auth/invalid-credential' || error.code === 'auth/user-not-found') {
        errorMessage = 'Invalid email or password.';
      }
      setAlertVisible(true)
      setAlertMessage(`Sign In Error, ${errorMessage}`)

    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async () => {
    setLoading(true);
    if (password !== confirmPassword) {
      setAlertVisible(true)
      setAlertMessage(`Sign Up Error, Passwords do not match!`)
      setLoading(false);
      return;
    }

    try {
      const userCredential = await firebaseAuth.createUserWithEmailAndPassword(email, password);
      const idToken = await userCredential.user.getIdToken();

      // const backendResponse = await signupUserBackend(email, password, null);
      // console.log('Backend Sign Up Success:', backendResponse);

      await signIn(idToken);
    } catch (error) {
      console.error('Sign Up Error:', error.code, error.message);
      let errorMessage = 'Failed to create account.';
      if (error.code === 'auth/email-already-in-use') {
        errorMessage = 'That email address is already in use!';
      } else if (error.code === 'auth/weak-password') {
        errorMessage = 'Password should be at least 6 characters.';
      }
      setAlertVisible(true)
      setAlertMessage(`Sign Up Error, ${errorMessage}`)

    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setLoading(true);
    // await googleSignOut();
    try {
      GoogleSignin.configure({
        webClientId: GOOGLE_WEB_CLIENT_ID,
         forceCodeForRefreshToken: true,
      });

      await GoogleSignin.hasPlayServices();
      const userInfo= await GoogleSignin.signIn();
      await GoogleSignin.hasPlayServices({showPlayServicesUpdateDialog: true});

      const googleCredential = authModule.GoogleAuthProvider.credential(userInfo.data.idToken); //
      const userCredential = await firebaseAuth.signInWithCredential(googleCredential); //
      
      const firebaseIdToken = await userCredential.user.getIdToken(); // Get Firebase ID Token from the federated user
      const firebaseUid = userCredential.user.uid; // Get Firebase UID

      // Call backend for verification (optional, based on your backend flow)
      const backendResponse = await loginUserBackendVerification(firebaseIdToken); //
      console.log('Backend Google Sign-In Verification Success:', backendResponse); //

      // Set auth token in Voiceflow
     
      await signIn(firebaseIdToken); // Update app's auth context
      // 3. Create Firebase credential
      
    } catch (error) {
      console.error('Google Sign-In Error:', error.code, error.message);
      if (error.code !== 'SIGN_IN_CANCELLED') {
        setAlertVisible(true)
        setAlertMessage(`Google Sign-In Error, An error occurred during sign-in`)
      }
    } finally {
      setLoading(false);
    }
  };

  const handleAppleSignIn = () => {
    setAlertVisible(true)
    setAlertMessage(`Apple Sign-In', 'Apple Sign-In integration coming soon`)
  };

  return (
    <SafeAreaView style={styles.container}>
      <ImageBackground
        style={styles.container}
        resizeMode="cover"
      >
        <View style={styles.overlay} />
        <View style={styles.header}>
          {/* Header content is commented out as in your file */}
          <View></View>
        </View>

        <KeyboardAvoidingView
          style={styles.keyboardAvoidingView}
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
        >
          <ScrollView
            contentContainerStyle={styles.scrollViewContentContainer}
            keyboardShouldPersistTaps="handled"
          >
            <View style={styles.formContent}>
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

              <Text style={styles.headerTitle}>
                {mode === 'signin' ? 'Welcome Back!' : 'Create Your Account'}
              </Text>
              <Text style={styles.headerSubtitle}>
                {mode === 'signin' ? 'Sign in to continue' : 'Enter your details to get started'}
              </Text>

              <CustomTextInput
                iconName="email-outline"
                placeholder="Email"
                value={email}
                onChangeText={setEmail}
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

              {mode === 'signin' && (
                <TouchableOpacity
                  style={styles.forgotPasswordButton}
                  onPress={() => console.log('Forgot Password')}
                  disabled={loading}
                >
                  <Text style={styles.forgotPasswordText}>Forgot Password?</Text>
                </TouchableOpacity>
              )}

              <TouchableOpacity
                style={[styles.primaryButton, loading && styles.disabledButton]}
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

              <View style={styles.orContainer}>
                <View style={styles.line} />
                <Text style={styles.orText}>OR</Text>
                <View style={styles.line} />
              </View>

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
            <CustomAlertDialog
              isVisible={alertVisible}
              title="Error"
              message={alertMessage}
              cancelText="Dismiss"
              confirmText="Retry"
              onCancel={() => setAlertVisible(false)}
              onConfirm={() => {
                setAlertVisible(false);
                retryFetch(); // Or whatever your retry logic is
              }}
            />
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
    zIndex: 1,
  },
  keyboardAvoidingView: {
    flex: 1,
    width: '100%',
  },
  scrollViewContentContainer: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: 25,
    paddingVertical: 30,
  },
  formContent: {
    width: '100%',
    alignItems: 'center',
  },
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
  disabledButton: {
    opacity: 0.5,
  }
});

export default LoginSignupScreen;