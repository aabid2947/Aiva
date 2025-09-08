import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  Platform,
  Alert,
  PermissionsAndroid,
  NativeModules,
} from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign';
import MaterialIcons from 'react-native-vector-icons/MaterialIcons';
import Voice from '@react-native-voice/voice';
import DocumentPicker from 'react-native-document-picker';
import VoiceErrorDialog from '../components/VoiceErrorDialog';
import CustomAlertDialog from './CustomAlert.jsx';
import {
  interactWithAiva,
  apiUploadFileToAiva
} from '../api/aivaApiService.js';

const InputTray = ({
  activeChatId,
  user,
  setMessages,
  processAndDisplayAivaResponse,
  isAuthenticatingOAuth,
  oauthAlertPending,
  setIsSendingMessage,
  isSendingMessage,
}) => {
  const [inputText, setInputText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [isPickingFile, setIsPickingFile] = useState(false);
  const [finalTranscript, setFinalTranscript] = useState('');
  const [voiceError, setVoiceError] = useState(null);
  const [alertMessage, setAlertMessage] = useState('');
  const [alertVisible, setAlertVisible] = useState(false);
  const [voiceInitialized, setVoiceInitialized] = useState(true);

  useEffect(() => {
  // Simple, direct event handler setup
  const onSpeechStart = () => {
    console.log('Speech started');
    setIsRecording(true);
  };
  
  const onSpeechEnd = () => {
    console.log('Speech ended');
    setIsRecording(false);
  };
  
  const onSpeechError = (err) => {
    console.error('Speech recognition error:', err);
    setVoiceError(err.error || 'unknown');
    setIsRecording(false);
  };
  
  const onSpeechPartialResults = (event) => {
    if (event.value && event.value.length > 0) {
      setInputText(event.value[0]);
    }
  };
  
  const onSpeechResults = (event) => {
    if (event.value && event.value.length > 0) {
      const finalResult = event.value[0];
      setInputText(finalResult);
      setFinalTranscript(finalResult);
    }
  };

  // Direct assignment - no async initialization needed
  Voice.onSpeechStart = onSpeechStart;
  Voice.onSpeechEnd = onSpeechEnd;
  Voice.onSpeechError = onSpeechError;
  Voice.onSpeechPartialResults = onSpeechPartialResults;
  Voice.onSpeechResults = onSpeechResults;

  return () => {
    Voice.destroy().then(Voice.removeAllListeners);
  };
}, []);

// Simplified startListening without availability check
const startListening = async () => {
  let hasPermission = true;
  
  if (Platform.OS === 'android') {
    const permission = await PermissionsAndroid.request(
      PermissionsAndroid.PERMISSIONS.RECORD_AUDIO
    );
    hasPermission = permission === PermissionsAndroid.RESULTS.GRANTED;
  }

  if (!hasPermission) {
    setAlertMessage('Microphone permission needed');
    setAlertVisible(true);
    return;
  }

  try {
    setInputText('');
    setFinalTranscript('');
    await Voice.start('en-US'); // Direct start without availability check
  } catch (e) {
    console.error('Failed to start listening:', e);
    setVoiceError(e.code || e.message || 'unknown');
    setIsRecording(false);
  }
};
  const handleSendMessage = useCallback(async (messageText) => {
    const textToSend = (typeof messageText === 'string' ? messageText : inputText).trim();
    if (textToSend === '' || isSendingMessage || !activeChatId) return;

    const newUserMessage = {
      id: Math.random().toString(36).substring(2, 11),
      text: textToSend,
      sender: 'user',
      timestamp: new Date().toISOString(),
    };
    setMessages((prevMessages) => [...prevMessages, newUserMessage]);
    setInputText('');
    setIsSendingMessage(true);

    try {
      const result = await interactWithAiva(activeChatId, textToSend);
      processAndDisplayAivaResponse(result);
    } catch (error) {
      console.error('Failed to send message to Aiva:', error);
      setAlertMessage(`Failed to send message: ${error.message}`);
      setAlertVisible(true);
      const errorMessage = {
        id: Math.random().toString(36).substring(2, 11),
        text: `Aiva System: Failed to send your message. ${error.message}`,
        sender: 'ai',
        timestamp: new Date().toISOString(),
      };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    } finally {
      setIsSendingMessage(false);
    }
  }, [inputText, isSendingMessage, activeChatId, setMessages, processAndDisplayAivaResponse, setIsSendingMessage]);

  useEffect(() => {
    if (finalTranscript.trim() !== '') {
      handleSendMessage(finalTranscript);
      setFinalTranscript('');
    }
  }, [finalTranscript, handleSendMessage]);

  // Simplified startListening function - remove isAvailable check
  // const startListening = async () => {
  //   try {
  //     console.log('Attempting to start voice recognition...');
      
  //     // Check if voice is initialized
  //     if (!voiceInitialized) {
  //       setAlertMessage('Voice recognition is still initializing. Please try again in a moment.');
  //       setAlertVisible(true);
  //       return;
  //     }

  //     let hasPermission = true;
      
  //     if (Platform.OS === 'android') {
  //       const permission = await PermissionsAndroid.request(
  //         PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
  //         {
  //           title: 'Microphone Permission',
  //           message: 'This app needs access to your microphone for voice-to-text functionality.',
  //           buttonNeutral: 'Ask Me Later',
  //           buttonNegative: 'Cancel',
  //           buttonPositive: 'OK',
  //         }
  //       );
  //       hasPermission = permission === PermissionsAndroid.RESULTS.GRANTED;
  //       console.log('Microphone permission:', hasPermission);
  //     }

  //     if (!hasPermission) {
  //       setAlertMessage('Microphone permission is needed for voice-to-text.');
  //       setAlertVisible(true);
  //       return;
  //     }

  //     console.log('Starting voice recognition...');
  //     setInputText('');
  //     setFinalTranscript('');
  //     setVoiceError(null);
      
  //     // Try to start voice recognition directly
  //     await Voice.start('en-US');
  //     console.log('Voice.start() called successfully');
      
  //   } catch (e) {
  //     console.error('Failed to start listening:', e);
  //     setVoiceError(e.code || e.message || 'unknown');
  //     setIsRecording(false);
      
  //     // Show user-friendly error message
  //     if (e.message && e.message.includes('not available')) {
  //       setAlertMessage('Speech recognition is not available on this device or not properly configured.');
  //     } else {
  //       setAlertMessage('Failed to start voice recognition. Please try again.');
  //     }
  //     setAlertVisible(true);
  //   }
  // };

  const stopListening = async () => {
    try {
      console.log('Stopping voice recognition...');
      await Voice.stop();
      console.log('Voice.stop() called successfully');
    } catch (e) {
      console.error('Failed to stop listening:', e);
      setIsRecording(false); // Force stop recording state
    }
  };

  const handleMicButtonPress = () => {
    console.log('🎤 Mic button pressed! Current state:', {
      isRecording,
      voiceInitialized,
      isAuthenticatingOAuth,
      oauthAlertPending,
      isSendingMessage
    });

    // Check if button should be disabled
    if (isAuthenticatingOAuth || oauthAlertPending || isSendingMessage) {
      console.log('❌ Mic button disabled due to other operations');
      return;
    }

    if (!voiceInitialized) {
      console.log('❌ Voice not initialized yet');
      setAlertMessage('Voice recognition is still initializing. Please try again in a moment.');
      setAlertVisible(true);
      return;
    }

    if (isRecording) {
      console.log('🛑 Stopping recording...');
      stopListening();
    } else {
      console.log('▶️ Starting recording...');
      startListening();
    }
  };

  const handleChooseFile = useCallback(async () => {
    if (!activeChatId) {
      setAlertMessage('No Active Chat , Please select or create a chat before uploading a file.');
      setAlertVisible(true);
      return;
    }
    if (isSendingMessage || isRecording || isAuthenticatingOAuth || isPickingFile) {
      setAlertMessage('Action in Progress , Please wait for the current action to complete.');
      setAlertVisible(true);
      return;
    }
    try {
      setIsPickingFile(true);
      const result = await DocumentPicker.pick({
        type: [DocumentPicker.types.allFiles],
        allowMultiSelection: false,
      });
      
      const file = result[0];
      if (!file || !file.uri) {
        console.error('CRITICAL ERROR: The file object is invalid or missing URI.', file);
        setAlertMessage('Failed to get valid file details from the system.');
        setAlertVisible(true);
        setIsPickingFile(false);
        return;
      }

      // Check file size before upload
      const maxFileSize = 50 * 1024 * 1024; // 50MB limit
      if (file.size && file.size > maxFileSize) {
        const fileSizeMB = (file.size / (1024 * 1024)).toFixed(2);
        setAlertMessage(`File "${file.name}" is too large (${fileSizeMB}MB). Maximum allowed size is 10MB.`);
        setAlertVisible(true);
        setIsPickingFile(false);
        return;
      }

      console.log(`Selected file: ${file.name}, Size: ${file.size ? (file.size / (1024 * 1024)).toFixed(2) + 'MB' : 'Unknown'}, Type: ${file.type}`);
      
      setIsSendingMessage(true);
      const tempUserMessage = {
        id: Math.random().toString(36).substring(2, 11),
        text: `Uploading file: ${file.name}...`,
        sender: 'user',
        timestamp: new Date().toISOString(),
        isTemporary: true,
      };
      setMessages((prevMessages) => [...prevMessages, tempUserMessage]);
      const result2 = await apiUploadFileToAiva(activeChatId, file);
      setMessages(prevMessages => prevMessages.filter(msg => !msg.isTemporary));
      processAndDisplayAivaResponse(result2);
    } catch (err) {
      if (DocumentPicker.isCancel(err)) {
        console.log('User cancelled file picker');
      } else {
        console.error('File picker error in catch block:', err);
        
        // Better error message for file upload issues
        let errorMessage = err.message;
        if (err.message.includes('timeout')) {
          errorMessage = 'Upload timeout - file might be too large or network too slow. Try a smaller file or better network connection.';
        } else if (err.message.includes('413') || err.message.includes('Request Entity Too Large')) {
          errorMessage = 'File too large for server. Maximum file size is 10MB.';
        } else if (err.message.includes('Network')) {
          errorMessage = 'Network error during upload. Please check your connection and try again.';
        }
        
        setAlertMessage(errorMessage);
        setAlertVisible(true);
        setMessages(prevMessages => prevMessages.filter(msg => !msg.isTemporary));
      }
    } finally {
      setIsSendingMessage(false);
      setIsPickingFile(false);
    }
  }, [activeChatId, isSendingMessage, isRecording, isAuthenticatingOAuth, isPickingFile, setMessages, processAndDisplayAivaResponse]);

  return (
    <View style={styles.inputContainer}>
      <TouchableOpacity
        style={styles.attachButton}
        onPress={handleChooseFile}
        disabled={isSendingMessage || isAuthenticatingOAuth || isRecording || isPickingFile}
      >
        <AntDesign name="paperclip" size={24} color={
          (isSendingMessage || isAuthenticatingOAuth || isRecording || isPickingFile)
            ? "#cccccc"
            : "black"
        } />
      </TouchableOpacity>

      <TextInput
        style={styles.textInput}
        placeholder={isRecording ? "Listening..." : "Message Aiva..."}
        placeholderTextColor="#888"
        multiline
        value={inputText}
        onChangeText={setInputText}
        editable={!isSendingMessage && !isAuthenticatingOAuth && !isRecording}
        onSubmitEditing={() => handleSendMessage()}
        blurOnSubmit={false}
      />

      <TouchableOpacity
        style={[styles.micButton, {
          backgroundColor: isRecording ? '#ffebee' : 'transparent',
          opacity: voiceInitialized ? 1 : 0.5
        }]}
        onPress={handleMicButtonPress}
        disabled={isAuthenticatingOAuth || oauthAlertPending || isSendingMessage || !voiceInitialized}
      >
        <MaterialIcons 
          name="mic" 
          size={26} 
          color={isRecording ? "#e74c3c" : (voiceInitialized ? "black" : "#cccccc")} 
        />
      </TouchableOpacity>

      {isSendingMessage ? (
        <ActivityIndicator size="small" color="#007BFF" style={styles.sendButtonActivity} />
      ) : (
        (inputText.trim() !== '' && !isRecording) && (
          <TouchableOpacity
            style={styles.sendButton}
            onPress={() => handleSendMessage()}
            disabled={isAuthenticatingOAuth || oauthAlertPending}
          >
            <AntDesign name="arrowup" size={24} color="black" />
          </TouchableOpacity>
        )
      )}
      
      <VoiceErrorDialog
        isVisible={!!voiceError}
        errorCode={voiceError}
        onClose={() => setVoiceError(null)}
      />
      
      <CustomAlertDialog
        isVisible={alertVisible}
        title="Info"
        message={alertMessage}
        cancelText="Dismiss"
        confirmText="OK"
        onCancel={() => setAlertVisible(false)}
        onConfirm={() => setAlertVisible(false)}
      />
    </View>
  );
};

// Styles remain the same
const styles = StyleSheet.create({
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: Platform.OS === 'ios' ? 12 : 8,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    backgroundColor: 'rgba(255, 243, 217, 0.95)',
    minHeight: 60,
  },
  textInput: {
    flex: 1,
    minHeight: 40,
    maxHeight: 120,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 20,
    paddingHorizontal: 15,
    paddingTop: Platform.OS === 'ios' ? 10 : 8,
    paddingBottom: Platform.OS === 'ios' ? 10 : 8,
    marginRight: 8,
    fontSize: 16,
    color: '#333',
  },
  sendButton: { padding: 8, justifyContent: 'center', alignItems: 'center' },
  micButton: { padding: 8, justifyContent: 'center', alignItems: 'center' },
  attachButton: {
    padding: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 5,
  },
  sendButtonActivity: { paddingHorizontal: 12, paddingVertical: 8, marginLeft: 8 },
});

export default InputTray;