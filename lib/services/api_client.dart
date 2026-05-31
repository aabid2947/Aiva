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
          ),
        );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;
}
