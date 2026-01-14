class UserNickname {
  UserNickname({this.userId, required this.nickName});

  factory UserNickname.fromJson(Map<String, dynamic> json) {
    return UserNickname(nickName: json['nick_name'] as String);
  }
  final String? userId;
  final String nickName;

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'nick_name': nickName};
  }
}
