class PocRealtimeModel {
  const PocRealtimeModel({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;

  factory PocRealtimeModel.fromJson(Map<String, dynamic> json) {
    return PocRealtimeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayUserId => userId.substring(0, 8);

  String get formattedTime =>
      '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}:${createdAt.second.toString().padLeft(2, '0')}';
}