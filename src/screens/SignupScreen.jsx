import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert, // Used for demonstration, consider custom modals for production
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
// import { AuthContext } from './src/context/AuthContext'; // Uncomment and import if you have a register function in your AuthContext

// SignUpPage Component
export default function SignUpPage({ navigation }) {
  // If using AuthContext for registration:
  // const { register, isLoading: authContextLoading } = useContext(AuthContext);

  // State for input fields
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  // State for loading indicator during registration attempt
  const [isRegistering, setIsRegistering] = useState(false);

  /**
   * Handles the sign-up button press.
   * Performs client-side validation and simulates an asynchronous registration process.
   */
  const handleSignUp = async () => {
    // Basic client-side validation
    if (!email.trim() || !password.trim() || !confirmPassword.trim()) {
      Alert.alert('Sign Up Error', 'All fields are required.');
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert('Sign Up Error', 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      Alert.alert('Sign Up Error', 'Password must be at least 6 characters long.');
      return;
    }

    setIsRegistering(true); // Show loading indicator

    try {
      // Simulate an API call for user registration
      // In a real app, you would send email/password to your backend
      // and handle the registration response.
      await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate network delay

      // Simulate successful registration
      if (email.includes('@') && email.includes('.')) { // Simple email format check
        // If using AuthContext:
        // await register(email, password); // Call a register function from your AuthContext
        Alert.alert('Sign Up Success', 'Account created successfully! You can now log in.');
        // Navigate back to login or directly to home if auto-logged in
        navigation.navigate('Login'); // Assuming 'Login' is the name of your login screen route
      } else {
        Alert.alert('Sign Up Failed', 'Please enter a valid email address.');
      }
    } catch (error) {
      console.error('Sign up error:', error);
      Alert.alert('Sign Up Error', 'An unexpected error occurred during registration. Please try again.');
    } finally {
      setIsRegistering(false); // Hide loading indicator
    }
  };

  /**
   * Handles navigation back to the login page.
   */
  const handleGoToLogin = () => {
    navigation.navigate('Login'); // Assuming 'Login' is the name of your login screen route
  };

  // You might want a global loading indicator from AuthContext if it's checking initial status
  // if (authContextLoading) {
  //   return (
  //     <View style={styles.loadingContainer}>
  //       <ActivityIndicator size="large" color="#007AFF" />
  //       <Text style={styles.loadingText}>Loading app...</Text>
  //     </View>
  //   );
  // }

  return (
    
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollViewContent}>
        <View style={styles.headerContainer}>
          <Text style={styles.title}>Create Account</Text>
          <Text style={styles.subtitle}>Join us today!</Text>
        </View>

        {/* Email Input */}
        <TextInput
          style={styles.input}
          placeholder="Email"
          placeholderTextColor="#999"
          keyboardType="email-address"
          autoCapitalize="none"
          value={email}
          onChangeText={setEmail}
          editable={!isRegistering}
        />

        {/* Password Input */}
        <TextInput
          style={styles.input}
          placeholder="Password"
          placeholderTextColor="#999"
          secureTextEntry
          value={password}
          onChangeText={setPassword}
          editable={!isRegistering}
        />

        {/* Confirm Password Input */}
        <TextInput
          style={styles.input}
          placeholder="Confirm Password"
          placeholderTextColor="#999"
          secureTextEntry
          value={confirmPassword}
          onChangeText={setConfirmPassword}
          editable={!isRegistering}
        />

        {/* Sign Up Button */}
        <TouchableOpacity
          style={[styles.signUpButton, isRegistering && styles.signUpButtonDisabled]}
          onPress={handleSignUp}
          disabled={isRegistering}
        >
          {isRegistering ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.signUpButtonText}>Sign Up</Text>
          )}
        </TouchableOpacity>

        {/* Go to Login Link */}
        <View style={styles.loginContainer}>
          <Text style={styles.loginText}>Already have an account? </Text>
          <TouchableOpacity onPress={handleGoToLogin} disabled={isRegistering}>
            <Text style={styles.loginLink}>Log In</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

// StyleSheet for component styling
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#E0F7FA', // Light blue background
  },
  scrollViewContent: {
    flexGrow: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#E0F7FA',
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#555',
  },
  headerContainer: {
    marginBottom: 40,
    alignItems: 'center',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#00796B', // Dark teal
    marginBottom: 10,
    fontFamily: 'Inter',
  },
  subtitle: {
    fontSize: 18,
    color: '#009688', // Medium teal
    fontFamily: 'Inter',
  },
  input: {
    width: '100%',
    height: 50,
    backgroundColor: '#fff',
    borderRadius: 10,
    paddingHorizontal: 15,
    marginBottom: 15,
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#80CBC4', // Light teal border
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2, // Android shadow
    fontFamily: 'Inter',
  },
  signUpButton: {
    width: '100%',
    height: 50,
    backgroundColor: '#00BCD4', // Cyan button
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 5,
    elevation: 5, // Android shadow
  },
  signUpButtonDisabled: {
    backgroundColor: '#80DEEA', // Lighter cyan when disabled
  },
  signUpButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
    fontFamily: 'Inter',
  },
  loginContainer: {
    flexDirection: 'row',
    marginTop: 30,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loginText: {
    fontSize: 16,
    color: '#555',
    fontFamily: 'Inter',
  },
  loginLink: {
    color: '#007AFF',
    fontSize: 16,
    fontWeight: 'bold',
    fontFamily: 'Inter',
  },
});
