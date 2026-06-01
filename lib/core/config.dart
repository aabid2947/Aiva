class AppConfig {
  AppConfig._();

  /// Base URL of the AIVA backend.
  ///
  /// Defaults to the deployed Vercel backend. Override for local dev, e.g.
  /// the Android emulator reaches the host's localhost via 10.0.2.2:
  /// `flutter run --dart-define=AIVA_API_BASE_URL=http://10.0.2.2:8000`
  static const String apiBaseUrl = String.fromEnvironment(
    'AIVA_API_BASE_URL',
    defaultValue: 'https://aiva-backend-woad.vercel.app',
  );

  /// Base URL of the VoiceStream proxy-caller server (the in-app WebRTC call
  /// for appointment booking). This is a SEPARATE service from the API.
  /// Override with `--dart-define=AIVA_VOICESTREAM_BASE_URL=...`.
  static const String voiceStreamBaseUrl = String.fromEnvironment(
    'AIVA_VOICESTREAM_BASE_URL',
    defaultValue: 'https://callbot.duckdns.org',
  );
}
