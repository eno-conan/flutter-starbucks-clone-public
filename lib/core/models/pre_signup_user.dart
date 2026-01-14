class PreSignupUser {
  PreSignupUser({
    required this.id,
    required this.token,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PreSignupUser.fromJson(Map<String, dynamic> json) {
    return PreSignupUser(
      id: json['id'] as String,
      token: json['token'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
  final String id;
  final String token;
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
