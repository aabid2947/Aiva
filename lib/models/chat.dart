class Chat {
  const Chat({required this.id, this.title, this.createdAt, this.updatedAt});

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'] as String,
        title: json['title'] as String?,
        createdAt: _date(json['created_at']),
        updatedAt: _date(json['updated_at']),
      );

  final String id;
  final String? title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayTitle =>
      (title == null || title!.trim().isEmpty) ? 'New chat' : title!.trim();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
