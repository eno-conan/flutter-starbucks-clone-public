import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###');

// Extension Typeの定義
extension type Price(int value) {
  String get formatted => '¥${_formatter.format(value)}';

  Price operator +(Price other) => Price(value + other.value);

  Price withTax(TaxRate taxRate) => Price((value * (1 + taxRate.rate)).round());

  Price calculateTax(TaxRate taxRate) => Price((value * taxRate.rate).round());
}

extension type TaxRate(int value) {
  double get rate => value / 100.0;
  String get formatted => '$value%';
}

extension type ItemCount(int value) {
  String get formatted => '$value点';
}

class TotalAmount {
  const TotalAmount({
    required this.itemCount,
    required this.amountExcludingTax,
    required this.taxRatePercentage,
    required this.consumptionTax,
    required this.amountIncludingTax,
  });

  /// 注文された商品の数
  final ItemCount itemCount;

  /// 税抜き合計金額
  final Price amountExcludingTax;

  /// 適用される消費税率 (8% または 10%)
  final TaxRate taxRatePercentage;

  /// 消費税額
  final Price consumptionTax;

  /// 税込み合計金額
  final Price amountIncludingTax;

  /// 合計金額をフォーマットされた文字列で取得
  String get formattedItemCount => itemCount.formatted;

  /// 合計金額をフォーマットされた文字列で取得
  String get formattedTotalAmount => amountIncludingTax.formatted;

  /// 税抜き金額をフォーマットされた文字列で取得
  String get formattedAmountExcludingTax => amountExcludingTax.formatted;

  /// 消費税額をフォーマットされた文字列で取得
  String get formattedConsumptionTax => consumptionTax.formatted;

  /// 税率を文字列形式で取得 (例: "10%")
  String get taxRateString => taxRatePercentage.formatted;

  @override
  String toString() {
    return 'TotalAmount(itemCount: ${itemCount.value}, amountExcludingTax: ${amountExcludingTax.value}, '
        'taxRatePercentage: ${taxRatePercentage.value}, consumptionTax: ${consumptionTax.value}, '
        'amountIncludingTax: ${amountIncludingTax.value})';
  }
}
