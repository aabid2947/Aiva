import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Talks to the backend /auth endpoints and manages the stored token.
class AuthService {
  AuthService({ApiClient? api, TokenStorage? tokenStorage})
      : _api = api ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Dio get _dio => _api.dio;

  Future<void> signup({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      },
    );
    await _tokenStorage.saveToken(res.data!['access_token'] as String);
  }

  Future<void> login({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await _tokenStorage.saveToken(res.data!['access_token'] as String);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
    );
  }

  Future<User> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return User.fromJson(res.data!);
  }

  /// Detect the device's IANA timezone (e.g. "Asia/Kolkata") and report it to the
  /// backend so reminders + appointment times are interpreted in the user's local zone.
  Future<void> reportTimezone() async {
    String tz;
    try {
      tz = await FlutterTimezone.getLocalTimezone(); // IANA name, e.g. "Asia/Kolkata"
    } catch (_) {
      return; // can't detect → backend keeps its UTC default
    }
    if (tz.isEmpty) return;
    try {
      await _dio.put<dynamic>('/auth/timezone', data: {'timezone': tz});
    } catch (_) {
      // best effort; retried on the next login
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> hasToken() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }
}
