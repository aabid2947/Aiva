class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    this.intent,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        chatId: json['chat_id'] as String,
        role: json['role'] as String,
        content: json['content'] as String? ?? '',
        intent: json['intent'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  /// An optimistic, not-yet-persisted message shown immediately in the UI.
  factory Message.local({required String role, required String content}) =>
      Message(id: 'local', chatId: 'local', role: role, content: content);

  final String id;
  final String chatId;
  final String role;
  final String content;
  final String? intent;
  final DateTime? createdAt;

  bool get isUser => role == 'user';
}
