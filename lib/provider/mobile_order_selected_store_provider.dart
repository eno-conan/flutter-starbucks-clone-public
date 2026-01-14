// お気に入り店舗のモデルクラス
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/store_mobile_order.dart';

// 選択された店舗を管理するNotifier
class SelectedStoreNotifier extends Notifier<StoreMobileOrder?> {
  @override
  StoreMobileOrder? build() {
    return null;
  }

  // 店舗を選択するメソッド
  set store(StoreMobileOrder? value) {
    state = value;
  }

  StoreMobileOrder? get store => state;

  // 選択をクリアするメソッド
  void clear() {
    state = null;
  }

  // 店舗情報が空かどうかを判定する
  bool isEmpty() {
    return state == null;
  }
}

// 選択された店舗を管理するProvider
final selectedStoreProvider = NotifierProvider<SelectedStoreNotifier, StoreMobileOrder?>(
  SelectedStoreNotifier.new,
);

// 店舗情報がnullかどうかを判定する拡張機能
extension SelectedStoreReaderExtension on ProviderContainer {
  // 店舗情報を読み取る
  StoreMobileOrder? readSelectedStore() {
    return read(selectedStoreProvider);
  }

  // 店舗情報が空かどうかを判定する
  bool isSelectedStoreEmpty() {
    return read(selectedStoreProvider) == null;
  }
}
