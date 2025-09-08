// src/services/speechToTextService.js
// Use @react-native-community/voice instead of the problematic package
import Voice from '@react-native-community/voice'; // <-- CHANGED IMPORT HERE

class SpeechToTextService {
  constructor() {
    this.isInitialized = false;
    this.onSpeechStart = this.onSpeechStart.bind(this);
    this.onSpeechEnd = this.onSpeechEnd.bind(this);
    this.onSpeechError = this.onSpeechError.bind(this);
    this.onSpeechResults = this.onSpeechResults.bind(this);
    this.onSpeechPartialResults = this.onSpeechPartialResults.bind(this);

    // These event assignments are correct for @react-native-community/voice
    Voice.onSpeechStart = this.onSpeechStart;
    Voice.onSpeechEnd = this.onSpeechEnd;
    Voice.onSpeechError = this.onSpeechError;
    Voice.onSpeechResults = this.onSpeechResults;
    Voice.onSpeechPartialResults = this.onSpeechPartialResults;
  }

  async initialize() {
    if (this.isInitialized) return;

    try {
      // These methods are standard for @react-native-community/voice
      await Voice.destroy();
      await Voice.removeAllListeners();

      // Re-initialize event listeners
      Voice.onSpeechStart = this.onSpeechStart;
      Voice.onSpeechEnd = this.onSpeechEnd;
      Voice.onSpeechError = this.onSpeechError;
      Voice.onSpeechResults = this.onSpeechResults;
      Voice.onSpeechPartialResults = this.onSpeechPartialResults;

      this.isInitialized = true;
    } catch (e) {
      console.error('Voice initialization failed:', e);
    }
  }
  // Set callbacks from the component to update its state
  setCallbacks(callbacks) {
    this.callbacks = callbacks;
  }

  onSpeechStart(e) {
    this.callbacks?.onStart?.(e);
  }

  onSpeechEnd(e) {
    this.callbacks?.onEnd?.(e);
  }

  onSpeechError(e) {
    this.callbacks?.onError?.(e);
  }

  onSpeechResults(e) {
    this.callbacks?.onResults?.(e);
  }

  onSpeechPartialResults(e) {
    this.callbacks?.onPartialResults?.(e);
  }

  async startRecording(locale = 'en-US') {
    await this.initialize(); // Ensure initialized before starting
    try {
      // These methods are standard for @react-native-community/voice
      await Voice.start(locale);
    } catch (e) {
      console.error('Failed to start speech recognition:', e);
    }
  }

  async stopRecording() {
    try {
      // These methods are standard for @react-native-community/voice
      await Voice.stop();
    } catch (e) {
      console.error('Failed to stop speech recognition:', e);
    }
  }

  async cancelRecording() {
    try {
      // These methods are standard for @react-native-community/voice
      await Voice.cancel();
    } catch (e) {
      console.error('Failed to cancel speech recognition:', e);
    }
  }

  async destroy() {
    // These methods are standard for @react-native-community/voice
    Voice.destroy().then(Voice.removeAllListeners);
  }
}

// Export a singleton instance
export const speechToTextService = new SpeechToTextService();