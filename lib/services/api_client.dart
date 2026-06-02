import 'package:dio/dio.dart';

import '../core/config.dart';
import 'token_storage.dart';

/// Wraps a Dio instance and attaches the JWT to every request via an interceptor.
class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _tokenStorage.readToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) {
              // A 401 on a request that DID carry our token means the session
              // expired or was revoked (the JWT lives ~60 min and there's no
              // refresh). Failed logins send no token, so they never trip this.
              final sentToken =
                  error.requestOptions.headers.containsKey('Authorization');
              if (error.response?.statusCode == 401 && sentToken) {
                onUnauthorized?.call();
              }
              handler.next(error);
            },
          ),
        );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  /// Invoked once when any token-bearing request fails with 401 (an expired or
  /// revoked session). [AuthState] registers this to clear the session and drop
  /// to the login screen. Static so every per-service ApiClient shares one hook.
  static void Function()? onUnauthorized;
}
