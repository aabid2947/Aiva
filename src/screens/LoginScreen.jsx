import React, { useState, useContext } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
// Assuming AuthContext.js is in src/context/
import { AuthContext } from '../context/AuthContext';
// Assuming ThemeContext.js is in src/context/ and provides 'theme' and 'toggleTheme'
// If your ThemeContext doesn't provide themeStyles, you'll need to define the color logic there or here.
// For self-containment in this example, I'll define theme-specific colors within getThemedStyles.
import { ThemeContext } from '../context/ThemeContext'; // Import your ThemeContext

// LoginPage Component
export default function LoginPage({ navigation }) {
  const { login, isLoading: authLoading } = useContext(AuthContext);
  const { theme } = useContext(ThemeContext); // Get the current theme from ThemeContext

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isAuthenticating, setIsAuthenticating] = useState(false);

  /**
   * Handles the login button press.
   * Simulates an asynchronous authentication process.
   */
  const handleLogin = async () => {
    if (!email.trim() || !password.trim()) {
      Alert.alert('Login Error', 'Please enter both email and password.');
      return;
    }

    setIsAuthenticating(true);

    try {
      await new Promise(resolve => setTimeout(resolve, 2000));

      if (email === 'user@example.com' && password === 'password123') {
        const fakeToken = 'mock_jwt_token_abc123def456';
        await login(fakeToken);
        Alert.alert('Login Success', 'You have been logged in!');
      } else {
        Alert.alert('Login Failed', 'Invalid email or password.');
      }
    } catch (error) {
      console.error('Login error:', error);
      Alert.alert('Login Error', 'An unexpected error occurred. Please try again.');
    } finally {
      setIsAuthenticating(false);
    }
  };

  const handleForgotPassword = () => {
    Alert.alert('Forgot Password', 'Navigate to forgot password screen.');
    // navigation.navigate('ForgotPassword');
  };

  const handleSignUp = () => {
    console.log(theme)
    navigation.navigate('Signup');
    // navigation.navigate('SignUp');
  };

  const handleSocialLogin = (platform) => {
    Alert.alert('Social Login', `Logging in with ${platform}... (Not implemented)`);
  };

  // Define themed styles based on the current theme
  const themedStyles = getThemedStyles(theme);

  if (authLoading) {
    return (
      <View style={themedStyles.loadingContainer}>
        <ActivityIndicator size="large" color={theme === 'light' ? '#3498DB' : '#87CEEB'} />
        <Text style={themedStyles.loadingText}>Loading app...</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={themedStyles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={themedStyles.scrollViewContent}>
        {/* Logo Section */}
        <View style={themedStyles.logoContainer}>
          <View style={themedStyles.logoIcon}>
            {/* Simple SVG-like icon for the music app logo */}
            <Text style={[themedStyles.logoIconText, { color: theme === 'light' ? '#2C3E50' : '#E0F2F7' }]}>
              &#9835; {/* Music note unicode character */}
            </Text>
          </View>
          <Text style={themedStyles.appName}>Aiva</Text>
        </View>

        <Text style={themedStyles.accessAccountText}>Login with Email</Text>

        {/* Email Input */}
        <TextInput
          style={themedStyles.input}
          placeholder="E-mail"
          placeholderTextColor={theme === 'light' ? '#A9B8C8' : '#999'}
          keyboardType="email-address"
          autoCapitalize="none"
          value={email}
          onChangeText={setEmail}
          editable={!isAuthenticating}
        />

        {/* Password Input */}
        <TextInput
          style={themedStyles.input}
          placeholder="Password"
          placeholderTextColor={theme === 'light' ? '#A9B8C8' : '#999'}
          secureTextEntry
          value={password}
          onChangeText={setPassword}
          editable={!isAuthenticating}
        />

        {/* Forgot Password Link */}
        <TouchableOpacity
          onPress={handleForgotPassword}
          style={themedStyles.forgotPasswordButton}
          disabled={isAuthenticating}
        >
          <Text style={themedStyles.forgotPasswordText}>Forgot Password</Text>
        </TouchableOpacity>

        {/* Login Button */}
        <TouchableOpacity
          style={[themedStyles.primaryButton, isAuthenticating && themedStyles.primaryButtonDisabled]}
          onPress={handleLogin}
          disabled={isAuthenticating}
        >
          {isAuthenticating ? (
            <ActivityIndicator color={theme === 'light' ? '#fff' : '#2C3E50'} />
          ) : (
            <Text style={themedStyles.primaryButtonText}>Login</Text>
          )}
        </TouchableOpacity>

        {/* Sign Up Button */}
        <TouchableOpacity
          style={[themedStyles.secondaryButton, isAuthenticating && themedStyles.secondaryButtonDisabled]}
          onPress={handleSignUp}
          disabled={isAuthenticating}
        >
          <Text style={themedStyles.secondaryButtonText}>Don't have an Account? Sign Up</Text>
        </TouchableOpacity>

        {/* OR Separator */}
        <View style={themedStyles.orSeparatorContainer}>
          <View style={themedStyles.orLine} />
          <Text style={themedStyles.orText}>OR</Text>
          <View style={themedStyles.orLine} />
        </View>

        {/* Social Login Buttons */}
        <TouchableOpacity
          style={themedStyles.socialButton}
          onPress={() => handleSocialLogin('Gmail')}
          disabled={isAuthenticating}
        >
          <Text style={themedStyles.socialIcon}>G</Text>
          <Text style={themedStyles.socialButtonText}>Login with Google</Text>
        </TouchableOpacity>

        {/* <TouchableOpacity
          style={themedStyles.socialButton}
          onPress={() => handleSocialLogin('Apple ID')}
          disabled={isAuthenticating}
        >
          <Text style={themedStyles.socialIcon}></Text>
          <Text style={themedStyles.socialButtonText}>Login with Apple Id</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={themedStyles.socialButton}
          onPress={() => handleSocialLogin('Facebook')}
          disabled={isAuthenticating}
        >
          <Text style={themedStyles.socialIcon}>f</Text>
          <Text style={themedStyles.socialButtonText}>Login with Facebook</Text>
        </TouchableOpacity> */}

      </ScrollView>
    </KeyboardAvoidingView>
  );
}

// Function to define themed styles
const getThemedStyles = (theme) => StyleSheet.create({
  // --- Color Palette ---
  colors: {
    light: {
      backgroundGradientStart: '#E0F2F7', // Light Blue
      backgroundGradientEnd: '#FFFFFF',   // White
      textPrimary: '#2C3E50', // Dark Navy Blue
      textSecondary: '#34495E', // Slightly lighter dark blue
      inputBackground: '#FFFFFF',
      inputBorder: '#BDC3C7', // Light gray
      buttonPrimary: '#3498DB', // Vibrant Blue
      buttonPrimaryText: '#FFFFFF',
      buttonSecondaryBackground: '#FFFFFF',
      buttonSecondaryBorder: '#3498DB',
      buttonSecondaryText: '#3498DB',
      linkText: '#3498DB', // Blue for links
      socialButtonBackground: '#F0F0F0', // Light gray for social buttons
      socialButtonText: '#2C3E50',
      orLine: '#BDC3C7',
      orText: '#7F8C8D',
    },
    dark: {
      backgroundGradientStart: '#1A1A2E', // Dark Blue/Purple
      backgroundGradientEnd: '#0F0F1A',   // Very Dark Blue
      textPrimary: '#E0F2F7', // Light Blue/White
      textSecondary: '#B0C4DE', // Light Slate Gray
      inputBackground: '#2C3E50', // Dark Navy Blue
      inputBorder: '#5D6D7E', // Medium gray
      buttonPrimary: '#87CEEB', // Sky Blue
      buttonPrimaryText: '#2C3E50',
      buttonSecondaryBackground: 'transparent', // Transparent background
      buttonSecondaryBorder: '#87CEEB',
      buttonSecondaryText: '#87CEEB',
      linkText: '#87CEEB', // Sky Blue for links
      socialButtonBackground: '#2C3E50', // Dark Navy Blue for social buttons
      socialButtonText: '#E0F2F7',
      orLine: '#5D6D7E',
      orText: '#B0C4DE',
    },
  },

  // --- General Styles ---
  container: {
    flex: 1,
    // Using a simple background color here. For a gradient, you'd use a library like react-native-linear-gradient
    backgroundColor: theme === 'light' ? '#F0F8FF' : '#0F0F1A',
  },
  scrollViewContent: {
    flexGrow: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 25,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme === 'light' ? '#F0F8FF' : '#0F0F1A',
  },
  loadingText: {
    marginTop: 15,
    fontSize: 17,
    color: theme === 'light' ? '#34495E' : '#B0C4DE',
    fontFamily: 'Inter',
  },

  // --- Logo Section ---
  logoContainer: {
    alignItems: 'center',
    marginBottom: 50,
  },
  logoIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: theme === 'light' ? '#E0F2F7' : '#34495E', // Light blue or darker blue background for icon
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 5,
    elevation: 5,
  },
  logoIconText: {
    fontSize: 40,
    fontWeight: 'bold',
  },
  appName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: theme === 'light' ? '#2C3E50' : '#E0F2F7',
    fontFamily: 'Inter',
  },

  accessAccountText: {
    fontSize: 20,
    fontWeight: '600',
    color: theme === 'light' ? '#34495E' : '#B0C4DE',
    marginBottom: 25,
    alignSelf: 'flex-start', // Align to left as per image
    fontFamily: 'Inter',
  },

  // --- Input Fields ---
  input: {
    width: '100%',
    height: 55,
    backgroundColor: theme === 'light' ? '#FFFFFF' : '#2C3E50',
    borderRadius: 12,
    paddingHorizontal: 18,
    marginBottom: 20,
    fontSize: 17,
    borderWidth: 1,
    borderColor: theme === 'light' ? '#BDC3C7' : '#5D6D7E',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: theme === 'light' ? 0.1 : 0.4, // More prominent shadow in dark theme
    shadowRadius: 6,
    elevation: 4,
    fontFamily: 'Inter',
    color: theme === 'light' ? '#34495E' : '#E0F2F7',
  },

  // --- Forgot Password Link ---
  forgotPasswordButton: {
    alignSelf: 'flex-end',
    marginBottom: 25,
    paddingHorizontal: 5,
  },
  forgotPasswordText: {
    color: theme === 'light' ? '#3498DB' : '#87CEEB', // Themed link color
    fontSize: 15,
    fontWeight: '600',
    fontFamily: 'Inter',
  },

  // --- Buttons ---
  primaryButton: {
    width: '100%',
    height: 55,
    backgroundColor: theme === 'light' ? '#3498DB' : '#87CEEB', // Themed primary button color
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: theme === 'light' ? 0.25 : 0.5, // More prominent shadow in dark theme
    shadowRadius: 8,
    elevation: 6,
  },
  primaryButtonDisabled: {
    backgroundColor: theme === 'light' ? '#A9D0EF' : '#5D6D7E', // Lighter shade when disabled
    shadowOpacity: 0.1,
    elevation: 2,
  },
  primaryButtonText: {
    color: theme === 'light' ? '#fff' : '#2C3E50', // Themed text color
    fontSize: 19,
    fontWeight: '700',
    fontFamily: 'Inter',
  },
  secondaryButton: {
    width: '100%',
    height: 55,
    backgroundColor: theme === 'light' ? '#FFFFFF' : 'transparent', // White or transparent
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 15,
    borderWidth: 2, // Border for secondary button
    borderColor: theme === 'light' ? '#3498DB' : '#87CEEB', // Themed border color
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: theme === 'light' ? 0.15 : 0.3,
    shadowRadius: 6,
    elevation: 4,
  },
  secondaryButtonDisabled: {
    borderColor: theme === 'light' ? '#A9D0EF' : '#5D6D7E',
    shadowOpacity: 0.05,
    elevation: 1,
  },
  secondaryButtonText: {
    color: theme === 'light' ? '#3498DB' : '#87CEEB', // Themed text color
    fontSize: 17,
    fontWeight: '600',
    fontFamily: 'Inter',
  },

  // --- OR Separator ---
  orSeparatorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    marginVertical: 30, // Space above and below
  },
  orLine: {
    flex: 1,
    height: 1,
    backgroundColor: theme === 'light' ? '#BDC3C7' : '#5D6D7E', // Themed line color
  },
  orText: {
    marginHorizontal: 15,
    fontSize: 16,
    color: theme === 'light' ? '#7F8C8D' : '#B0C4DE', // Themed text color
    fontFamily: 'Inter',
  },

  // --- Social Login Buttons ---
  socialButton: {
    flexDirection: 'row',
    width: '100%',
    height: 55,
    backgroundColor: theme === 'light' ? '#F0F0F0' : '#2C3E50', // Themed background
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 15,
    borderWidth: 1,
    borderColor: theme === 'light' ? '#E0E0E0' : '#5D6D7E',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: theme === 'light' ? 0.08 : 0.3,
    shadowRadius: 4,
    elevation: 3,
  },
  socialIcon: {
    fontSize: 24, // Adjust size as needed
    marginRight: 15,
    color: theme === 'light' ? '#2C3E50' : '#E0F2F7', // Themed icon color
  },
  socialButtonText: {
    fontSize: 17,
    fontWeight: '500',
    color: theme === 'light' ? '#2C3E50' : '#E0F2F7', // Themed text color
    fontFamily: 'Inter',
  },
});
