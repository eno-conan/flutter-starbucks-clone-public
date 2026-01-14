import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###');

// Extension Typeの定義
extension type CardId(String value) {
  String get masked => '****${value.substring(value.length - 4)}';
  bool get isValid => value.isNotEmpty;
}

extension type Price(int value) {
  String get formatted => '¥${_formatter.format(value)}';
  Price operator +(Price other) => Price(value + other.value);

  // 比較演算子を追加
  bool operator >=(Price other) => value >= other.value;
  bool operator >(Price other) => value > other.value;
  bool operator <=(Price other) => value <= other.value;
  bool operator <(Price other) => value < other.value;
}

// リファクタリングされたCardModelクラス
class CardModel {
  CardModel({
    required this.cardId,
    required this.cardName,
    required this.imageUrl,
    required this.balance,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardId: CardId(json['card_id'] as String),
      cardName: json['card_name'] as String,
      imageUrl: json['image_url'] as String,
      balance: Price(json['balance'] as int),
    );
  }

  // カード情報未登録対応
  static CardModel? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    try {
      return CardModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  final CardId cardId;
  final String cardName;
  final String imageUrl;
  final Price balance;

  String get formattedBalance => balance.formatted;

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId.value,
      'card_name': cardName,
      'image_url': imageUrl,
      'balance': balance.value,
    };
  }
}
