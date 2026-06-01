import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice I/O for the chat: device speech-to-text (mic → text) and text-to-speech
/// (speak AIVA's reply). Uses on-device recognizers, so no API/key is needed.
///
/// One instance is owned by the chat screen: the composer drives the mic, and the
/// screen speaks the assistant reply for voice-initiated messages.
class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initTried = false;
  bool _available = false;

  /// Set by the caller before each listen session so it gets fresh callbacks.
  void Function(String status)? onStatus;
  void Function(String error)? onError;

  bool get isListening => _stt.isListening;

  Future<bool> _ensureInit() async {
    if (_initTried) return _available;
    _initTried = true;
    try {
      _available = await _stt.initialize(
        onStatus: (s) => onStatus?.call(s),
        onError: (e) => onError?.call(e.errorMsg),
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  /// Start listening. `onResult` fires with the running transcription and whether
  /// it's the final result. Returns false if the mic/recognizer isn't available.
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await _tts.stop(); // don't talk over the user
    if (!await _ensureInit()) return false;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  /// Speak AIVA's reply aloud.
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Android "normal" rate
    await _tts.setPitch(1.0);
    await _tts.speak(clean);
  }

  Future<void> stopSpeaking() => _tts.stop();

  void dispose() {
    _stt.cancel();
    _tts.stop();
  }
}
