import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/push_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide auth state. Drives the route guard in main.dart.
class AuthState extends ChangeNotifier {
  AuthState({AuthService? authService, PushService? pushService})
      : _auth = authService ?? AuthService(),
        _push = pushService ?? PushService() {
    // Any token-bearing 401 (expired/revoked session) forces us back to login.
    ApiClient.onUnauthorized = handleUnauthorized;
  }

  final AuthService _auth;
  final PushService _push;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  /// Called at startup: if a token exists, validate it via /auth/me.
  Future<void> bootstrap() async {
    if (await _auth.hasToken()) {
      try {
        _user = await _auth.me();
        _status = AuthStatus.authenticated;
        _afterLogin();
      } catch (_) {
        await _auth.logout();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _run(() => _auth.login(email: email, password: password));

  Future<bool> signup(String email, String password, String? fullName) =>
      _run(() => _auth.signup(email: email, password: password, fullName: fullName));

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.forgotPassword(email);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _error = _messageFrom(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _push.unregister();
    await _auth.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by [ApiClient] when a token-bearing request gets a 401 (expired or
  /// revoked session). Clears the session and returns to the login screen.
  /// Idempotent: re-entrant 401s from other in-flight requests are ignored, and
  /// it stays out of the way of [bootstrap]'s own startup validation (which runs
  /// while status is still `unknown`).
  void handleUnauthorized() {
    if (_status != AuthStatus.authenticated) return;
    _status = AuthStatus.unauthenticated;
    _user = null;
    _error = 'Your session expired. Please sign in again.';
    notifyListeners();
    // Local token clear only — skip the network push-unregister, which would
    // 401 too; the token is being dropped anyway.
    unawaited(_auth.logout());
  }

  /// Fire-and-forget once the user is authenticated: register for push and
  /// report the device timezone so server-side times are user-local.
  void _afterLogin() {
    unawaited(_push.initAndRegister());
    unawaited(_auth.reportTimezone());
  }

  Future<bool> _run(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      _user = await _auth.me();
      _status = AuthStatus.authenticated;
      _afterLogin();
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _error = _messageFrom(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    if (value) _error = null;
    notifyListeners();
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach the server. Is the backend running?';
    }
    return 'Request failed (${e.response?.statusCode ?? 'network'}).';
  }
}
