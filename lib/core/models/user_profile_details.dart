class UserProfileDetails {
  UserProfileDetails({
    required this.userId,
    required this.birthday,
    required this.sex,
    required this.teleNum,
    required this.postalCode,
    required this.prefectureId,
    this.address1,
    this.address2,
  });

  final String userId;
  final String birthday;
  final int sex;
  final String teleNum;
  final String postalCode;
  final int prefectureId;
  final String? address1;
  final String? address2;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'birthday': birthday,
      'sex': sex,
      'tele_num': teleNum,
      'postal_code': postalCode,
      'prefecture_id': prefectureId,
      'address1': address1,
      'address2': address2,
    };
    return data;
  }
}
