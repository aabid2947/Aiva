import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/app_keys.dart';
import 'api_client.dart';

/// Firebase Cloud Messaging integration.
///
/// Degrades gracefully: if Firebase isn't configured yet (no google-services.json),
/// init fails quietly and push is simply disabled — the rest of the app still works.
/// See CLAUDE.md "Firebase / FCM setup" for the one-time configuration steps.
class PushService {
  PushService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  bool _initialized = false;
  String? _token;

  Future<void> initAndRegister() async {
    if (_initialized) {
      if (_token != null) await _registerToken(_token!);
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('AIVA: Firebase not configured — push disabled ($e)');
      return;
    }
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _token = await messaging.getToken();
      if (_token != null) await _registerToken(_token!);
      messaging.onTokenRefresh.listen((t) {
        _token = t;
        _registerToken(t);
      });
      FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (e) {
      debugPrint('AIVA: push setup failed ($e)');
    }
  }

  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.dio.delete<dynamic>('/fcm/token', queryParameters: {'token': token});
    } catch (_) {
      // best effort
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.dio.post<dynamic>('/fcm/token', data: {'token': token});
    } catch (_) {
      // backend unreachable / not authed yet — will retry on next initAndRegister()
    }
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? 'AIVA';
    final body = notification?.body ?? '';
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
    );
  }
}
