// src/components/GoogleSignInDialog.jsx
import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';

const GoogleSignInDialog = ({
  isVisible,
  onCancel,
  onConfirm,
  title = 'Connect Google Account',
  message = 'To monitor your emails, Aiva needs permission to access your Gmail account.'
}) => {
  if (!isVisible) return null;

  return (
    <Modal
      visible={isVisible}
      transparent
      animationType="fade"
      onRequestClose={onCancel}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.message}>{message}</Text>

          <View style={styles.buttonRow}>
            <TouchableOpacity style={[styles.button, styles.cancel]} onPress={onCancel}>
              <Text style={styles.cancelText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.button, styles.confirm]} onPress={onConfirm}>
              <Text style={styles.confirmText}>Sign In with Google</Text>
            </TouchableOpacity>
          </View>
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
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
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
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
  },
  button: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 5,
  },
  cancel: {
    backgroundColor: '#f0f0f0',
    borderWidth: 1,
    borderColor: '#ddd',

  },
  confirm: {
    backgroundColor: '#007AFF',
  },
  cancelText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '600',
  },
  confirmText: {
    fontSize: 14,
    color: '#fff',
    fontWeight: '600',
  },
});

export default GoogleSignInDialog;
