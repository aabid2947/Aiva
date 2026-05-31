import 'package:dio/dio.dart';

import 'api_client.dart';

class MailStatus {
  const MailStatus({
    required this.connected,
    required this.enabled,
    this.importanceCriteria,
  });

  factory MailStatus.fromJson(Map<String, dynamic> json) => MailStatus(
        connected: json['connected'] as bool? ?? false,
        enabled: json['enabled'] as bool? ?? false,
        importanceCriteria: json['importance_criteria'] as String?,
      );

  final bool connected;
  final bool enabled;
  final String? importanceCriteria;
}

class MailService {
  MailService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<MailStatus> status() async {
    final res = await _dio.get<Map<String, dynamic>>('/mail/status');
    return MailStatus.fromJson(res.data!);
  }

  Future<String> connectUrl() async {
    final res = await _dio.get<Map<String, dynamic>>('/mail/connect');
    return res.data!['url'] as String;
  }

  Future<MailStatus> updateWatch({required bool enabled, String? importanceCriteria}) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/mail/watch',
      data: {'enabled': enabled, 'importance_criteria': importanceCriteria},
    );
    return MailStatus.fromJson(res.data!);
  }

  Future<void> disconnect() async {
    await _dio.delete<dynamic>('/mail/connect');
  }
}
