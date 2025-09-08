// src/components/SuccessDialog.jsx
import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';

/**
 * A reusable success dialog component.
 *
 * Props:
 * - isVisible: boolean
 * - title: dialog title
 * - message: dialog message
 * - onClose: function to call when OK is pressed
 * - okButtonText: text for the OK button (default: 'OK')
 */
const SuccessDialog = ({
  isVisible,
  title = 'Success',
  message,
  onClose,
  okButtonText = 'OK'
}) => {
  if (!isVisible) return null;

  return (
    <Modal
      visible={isVisible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.message}>{message}</Text>
          <TouchableOpacity style={styles.okButton} onPress={onClose}>
            <Text style={styles.okText}>{okButtonText}</Text>
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
    width: '85%',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#333',
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: '#555',
    marginBottom: 25,
    textAlign: 'center',
    lineHeight: 22,
  },
  okButton: {
    backgroundColor: '#34C759',
    paddingVertical: 12,
    paddingHorizontal: 25,
    borderRadius: 8,
    alignItems: 'center',
  },
  okText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default SuccessDialog;
