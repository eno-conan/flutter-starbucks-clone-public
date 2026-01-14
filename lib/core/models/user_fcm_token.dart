class UserFcmToken {
  UserFcmToken({this.id, this.fcmToken, required this.isNotify});

  /// JSONからUserFcmTokenオブジェクトを生成
  factory UserFcmToken.fromJson(Map<String, dynamic> json) {
    return UserFcmToken(id: '', fcmToken: '', isNotify: json['is_notify'] as int);
  }
  final String? id;
  final String? fcmToken;
  final int isNotify;

  /// UserFcmTokenオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {'id': id, 'fcmToken': fcmToken, 'isNotify': isNotify};
  }

  /// コピーを作成して一部のプロパティを更新する
  UserFcmToken copyWith({String? id, String? fcmToken, int? isNotify}) {
    return UserFcmToken(
      id: id ?? this.id,
      fcmToken: fcmToken ?? this.fcmToken,
      isNotify: isNotify ?? this.isNotify,
    );
  }
}
