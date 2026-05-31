import 'package:dio/dio.dart';

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

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> hasToken() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }
}
