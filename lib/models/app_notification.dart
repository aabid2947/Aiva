/// A single item in the in-app notification feed (backend `notifications` table).
/// `data` mirrors the FCM payload and drives tap routing (see notification_routing.dart).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: (json['type'] as String?) ?? 'info',
        title: (json['title'] as String?) ?? 'Notification',
        body: json['body'] as String?,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        read: json['read'] as bool? ?? false,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;
}
