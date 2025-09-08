// src/components/ConfirmationModal.jsx
import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';

const ConfirmationModal = ({ isVisible, title, message, onCancel, onConfirm, confirmButtonText = 'Confirm', cancelButtonText = 'Cancel' }) => {
  if (!isVisible) return null;

  return (
    <Modal visible={isVisible} transparent={true} animationType="fade" onRequestClose={onCancel}>
      <View style={styles.modalOverlay}>
        <View style={styles.modalContainer}>
          <Text style={styles.modalTitle}>{title}</Text>
          <Text style={styles.modalMessage}>{message}</Text>
          <View style={styles.modalButtonContainer}>
            <TouchableOpacity style={[styles.modalButton, styles.cancelButton]} onPress={onCancel}>
              <Text style={styles.modalButtonText}>{cancelButtonText}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.modalButton, styles.confirmButton]} onPress={onConfirm}>
              <Text style={[styles.modalButtonText, styles.confirmButtonText]}>{confirmButtonText}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContainer: {
    width: '85%',
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2, },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
  },
  modalTitle: { fontSize: 20, fontWeight: 'bold', marginBottom: 10, color: '#333' },
  modalMessage: { fontSize: 16, textAlign: 'center', marginBottom: 25, color: '#555', lineHeight: 24 },
  modalButtonContainer: { flexDirection: 'row', width: '100%', justifyContent: 'space-around', },
  modalButton: { borderRadius: 10, paddingVertical: 12, paddingHorizontal: 25, minWidth: 100, justifyContent: 'center', alignItems: 'center', },
  cancelButton: { backgroundColor: '#f0f0f0', borderWidth: 1, borderColor: '#ddd', },
  confirmButton: { backgroundColor: '#e74c3c', },
  modalButtonText: { fontSize: 16, fontWeight: '600', color: '#333', },
  confirmButtonText: { color: 'white', },
});

export default ConfirmationModal;