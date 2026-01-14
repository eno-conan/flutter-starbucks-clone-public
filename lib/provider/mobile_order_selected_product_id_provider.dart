import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 選択された商品の情報を保持するクラス
class SelectedProduct {
  const SelectedProduct({required this.id, required this.imageUrl});

  final String id;
  final String imageUrl;

  // デフォルト値
  static const empty = SelectedProduct(id: '0', imageUrl: '');

  // copyWith メソッド
  SelectedProduct copyWith({String? id, String? imageUrl}) {
    return SelectedProduct(id: id ?? this.id, imageUrl: imageUrl ?? this.imageUrl);
  }
}

/// 選択された商品を管理するNotifier
class SelectedProductNotifier extends Notifier<SelectedProduct> {
  @override
  SelectedProduct build() {
    return SelectedProduct.empty;
  }

  // 商品を選択するメソッド
  void selectProduct(String id, String imageUrl) {
    state = SelectedProduct(id: id, imageUrl: imageUrl);
  }

  // 選択をクリアするメソッド
  void clear() {
    state = SelectedProduct.empty;
  }

  // * 基本的には、stateを直接更新するのではなく、copyWithメソッドを使って新しいインスタンスを作成する
  // 個別に更新するメソッド
  // void updateId(String id) {
  // state = state.copyWith(id: id);
  // }

  // void updateImageUrl(String imageUrl) {
  // state = state.copyWith(imageUrl: imageUrl);
  // }
}

final selectedProductProvider = NotifierProvider<SelectedProductNotifier, SelectedProduct>(
  SelectedProductNotifier.new,
);
