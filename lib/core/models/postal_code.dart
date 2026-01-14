class PostalCode {
  PostalCode({required this.postalCode, required this.addresses});

  factory PostalCode.fromJson(Map<String, dynamic> json) {
    return PostalCode(
      postalCode: json['postalCode'] as String,
      addresses: (json['addresses'] as List<dynamic>)
          .map((addressJson) => Address.fromJson(addressJson as Map<String, dynamic>))
          .toList(),
    );
  }
  final String postalCode;
  final List<Address> addresses;

  Map<String, dynamic> toJson() {
    return {
      'postalCode': postalCode,
      'addresses': addresses.map((address) => address.toJson()).toList(),
    };
  }
}

class Address {
  Address({required this.prefectureCode, required this.ja});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      prefectureCode: json['prefectureCode'] as String,
      ja: JapaneseAddress.fromJson(json['ja'] as Map<String, dynamic>),
    );
  }
  final String prefectureCode;
  final JapaneseAddress ja;

  Map<String, dynamic> toJson() {
    return {'prefectureCode': prefectureCode, 'ja': ja.toJson()};
  }
}

class JapaneseAddress {
  JapaneseAddress({
    required this.prefecture,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.address4,
  });

  factory JapaneseAddress.fromJson(Map<String, dynamic> json) {
    return JapaneseAddress(
      prefecture: json['prefecture'] as String,
      address1: json['address1'] as String,
      address2: json['address2'] as String,
      address3: json['address3'] as String,
      address4: json['address4'] as String,
    );
  }
  final String prefecture;
  final String address1;
  final String address2;
  final String address3;
  final String address4;

  Map<String, dynamic> toJson() {
    return {
      'prefecture': prefecture,
      'address1': address1,
      'address2': address2,
      'address3': address3,
      'address4': address4,
    };
  }
}
