// src/components/VoiceErrorDialog.jsx
import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';

// Only relevant voice error codes and their user-friendly instructions
const SOLUTIONS = [
  { code: 'no-speech', label: 'Speak clearly and use more words.' },
  { code: 'speech-timeout', label: 'Speech input timed out. Please start speaking sooner.' },
  { code: 'network', label: 'Network error occurred. Check your connection.' },
];

const VoiceErrorDialog = ({
  isVisible,
  errorCode,
  onClose,
}) => {
  if (!isVisible) return null;

  // Find matching solution or fallback message
  const solution = SOLUTIONS.find(s => s.code === errorCode);
  const userMessage = solution
    ? solution.label
    : 'An unexpected voice recognition error occurred. Please try again.';

  return (
    <Modal
      visible={isVisible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <Text style={styles.title}>Voice Input Error</Text>

          <Text style={styles.message}>{userMessage}</Text>

          <Text style={styles.subtitle}>Tips to Fix:</Text>
          {SOLUTIONS.map(({ code, label }) => (
            <Text key={code} style={styles.tip}>• {label}</Text>
          ))}

          <TouchableOpacity style={styles.okButton} onPress={onClose}>
            <Text style={styles.okText}>OK</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    width: '90%',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: '#333',
    marginBottom: 16,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
    textAlign: 'center',
  },
  tip: {
    fontSize: 14,
    color: '#555',
    marginBottom: 6,
    textAlign: 'left',
    marginLeft: 12,
  },
  okButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16,
  },
  okText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default VoiceErrorDialog;
