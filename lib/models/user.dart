class User {
  const User({required this.id, required this.email, this.fullName});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
      );

  final String id;
  final String email;
  final String? fullName;
}
