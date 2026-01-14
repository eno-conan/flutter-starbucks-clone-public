enum OrderType {
  /// お持ち帰り
  toGo,

  /// 店内飲食
  insideStore,

  /// ドライブスルー
  driveThru,
}

/// 注文タイプの拡張メソッド
extension OrderTypeExtension on OrderType {
  /// 店内飲食なら1、お持ち帰りなら2の文字列を返す
  int get typeValue {
    switch (this) {
      case OrderType.insideStore:
        return 1;
      case OrderType.toGo:
        return 2;
      case OrderType.driveThru:
        return 3;
    }
  }
}

/// OrderTypeに関する追加のヘルパー機能
class OrderTypeHelper {
  /// 値から対応するOrderTypeを返す静的メソッド
  static OrderType fromValue(int value) {
    switch (value) {
      case 1:
        return OrderType.insideStore;
      case 2:
        return OrderType.toGo;
      case 3:
        return OrderType.driveThru;
      default:
        return OrderType.toGo; // デフォルト値
    }
  }
}
