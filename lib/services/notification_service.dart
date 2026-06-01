import 'package:dio/dio.dart';

import '../models/app_notification.dart';
import 'api_client.dart';

/// The notification feed plus its unread count, as returned by GET /notifications.
class NotificationFeed {
  const NotificationFeed({required this.items, required this.unread});

  final List<AppNotification> items;
  final int unread;
}

/// Reads/updates the user's in-app notification feed (backend `notifications`).
class NotificationService {
  NotificationService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<NotificationFeed> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/notifications');
    final data = res.data ?? const {};
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationFeed(items: items, unread: data['unread'] as int? ?? 0);
  }

  /// Lightweight unread-count fetch for the badge (reuses the list endpoint).
  Future<int> unreadCount() async => (await list()).unread;

  Future<void> markRead(String id) async {
    await _dio.post<dynamic>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post<dynamic>('/notifications/read-all');
  }

  Future<void> delete(String id) async {
    await _dio.delete<dynamic>('/notifications/$id');
  }
}
