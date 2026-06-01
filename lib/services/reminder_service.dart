import 'package:dio/dio.dart';

import '../models/reminder.dart';
import 'api_client.dart';

/// Reads the user's reminders (backend `reminders`). Creation happens in chat;
/// the worker pushes an FCM at the due time.
class ReminderService {
  ReminderService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<List<Reminder>> list() async {
    final res = await _dio.get<List<dynamic>>('/reminders');
    return (res.data ?? <dynamic>[])
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(String id) async {
    await _dio.delete<dynamic>('/reminders/$id');
  }

  /// Edit a pending reminder. `dueAt` is sent as UTC (the backend rejects past times).
  Future<Reminder> update(String id, {String? content, DateTime? dueAt}) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (dueAt != null) body['due_at'] = dueAt.toUtc().toIso8601String();
    final res = await _dio.put<Map<String, dynamic>>('/reminders/$id', data: body);
    return Reminder.fromJson(res.data!);
  }
}
