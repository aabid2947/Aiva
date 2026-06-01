import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/mail_service.dart';

/// Tracks whether Gmail is connected so the chat screen can surface a
/// "Connect Gmail" call-to-action directly (instead of burying it in a menu),
/// and launches the OAuth consent flow in the external browser.
class MailConnectState extends ChangeNotifier {
  MailConnectState({MailService? service}) : _service = service ?? MailService();

  final MailService _service;

  bool _connected = false;
  bool _loading = true;
  bool _checked = false;

  bool get connected => _connected;
  bool get loading => _loading;

  /// True once we've checked and Gmail is NOT connected → show the banner.
  bool get needsConnect => _checked && !_connected;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final status = await _service.status();
      _connected = status.connected;
    } on DioException catch (_) {
      // Keep prior state; the banner just won't change.
    }
    _loading = false;
    _checked = true;
    notifyListeners();
  }

  /// Open the Gmail OAuth consent page in the external browser.
  /// Returns false if the URL couldn't be fetched or the browser didn't open.
  Future<bool> connect() async {
    try {
      final url = await _service.connectUrl();
      return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on DioException catch (_) {
      return false;
    }
  }

  /// Called when the OAuth deep link reports success (aiva://mail-connected).
  void markConnected() {
    _connected = true;
    _checked = true;
    _loading = false;
    notifyListeners();
  }
}
