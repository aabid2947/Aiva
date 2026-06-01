/// A reminder the user set via chat (backend `reminders` table). `dueAt` is stored
/// in UTC by the backend; call `.toLocal()` when showing an absolute time.
class Reminder {
  const Reminder({
    required this.id,
    required this.content,
    required this.dueAt,
    required this.status,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        content: (json['content'] as String?) ?? '',
        dueAt: DateTime.tryParse(json['due_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        status: (json['status'] as String?) ?? 'pending',
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String content;
  final DateTime dueAt;
  final String status;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';
}
