import React from 'react';
import { View, Text, Button, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native'; // Import useNavigation hook

const HomeScreen = () => {
  const navigation = useNavigation(); // Get the navigation object

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to the Home Screen!</Text>
      <Text style={styles.subtitle}>You are successfully logged in (or just here).</Text>

      <View style={styles.buttonContainer}>
        <Button
          title="Go to Login"
          onPress={() => navigation.navigate('Login')} // Navigate to Login screen
          color="#007AFF"
        />
      </View>
      <View style={styles.buttonContainer}>
        <Button
          title="Go to Signup"
          onPress={() => navigation.navigate('Signup')} // Navigate to Signup screen
          color="#007AFF"
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f0f4f7',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 10,
    color: '#333',
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 30,
    textAlign: 'center',
  },
  buttonContainer: {
    width: '80%',
    marginVertical: 10,
  },
});

export default HomeScreen;