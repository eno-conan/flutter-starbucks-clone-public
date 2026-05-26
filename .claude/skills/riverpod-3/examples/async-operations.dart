// Riverpod 3.0 非同期処理例: APIフェッチとキャッシュ
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 商品モデル
class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

// 商品リスト状態
class ProductListState {
  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final List<Product> products;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // キャッシュが新鮮か判定（5分以内）
  bool get isCacheFresh {
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!) < Duration(minutes: 5);
  }
}

// ✅ Notifier実装（非同期処理＋キャッシュ）
class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() {
    // 初期状態、自動フェッチ
    final initialState = const ProductListState(isLoading: true);
    _fetchProducts();
    return initialState;
  }

  // プライベート: API呼び出し
  Future<void> _fetchProducts() async {
    try {
      // 実際はAPIから取得
      await Future<void>.delayed(const Duration(seconds: 2));

      final products = [
        const Product(id: '1', name: 'コーヒー', price: 400),
        const Product(id: '2', name: 'ラテ', price: 450),
        const Product(id: '3', name: 'カプチーノ', price: 480),
      ];

      state = state.copyWith(
        products: products,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '商品データの取得に失敗しました: $e',
      );
    }
  }

  // パブリック: リフレッシュ（キャッシュチェック付き）
  Future<void> refresh({bool force = false}) async {
    // キャッシュが新鮮で強制リフレッシュでなければスキップ
    if (!force && state.isCacheFresh) {
      return;
    }

    state = state.copyWith(isLoading: true);
    await _fetchProducts();
  }

  // パブリック: 商品追加（楽観的更新）
  Future<void> addProduct(Product product) async {
    // 楽観的更新（UIに即座に反映）
    final optimisticProducts = [...state.products, product];
    state = state.copyWith(products: optimisticProducts);

    try {
      // 実際はAPIでPOST
      await Future<void>.delayed(const Duration(seconds: 1));

      // 成功したら最終更新日時を更新
      state = state.copyWith(lastUpdated: DateTime.now());
    } catch (e) {
      // 失敗したらロールバック
      state = state.copyWith(
        products: state.products.where((p) => p.id != product.id).toList(),
        error: '商品の追加に失敗しました: $e',
      );
    }
  }

  // パブリック: 商品削除
  Future<void> removeProduct(String productId) async {
    // 削除対象を保存（ロールバック用）
    final deletedProduct = state.products.firstWhere((p) => p.id == productId);

    // 楽観的更新
    final optimisticProducts =
        state.products.where((p) => p.id != productId).toList();
    state = state.copyWith(products: optimisticProducts);

    try {
      // 実際はAPIでDELETE
      await Future<void>.delayed(const Duration(seconds: 1));

      state = state.copyWith(lastUpdated: DateTime.now());
    } catch (e) {
      // ロールバック
      state = state.copyWith(
        products: [...state.products, deletedProduct],
        error: '商品の削除に失敗しました: $e',
      );
    }
  }
}

// Provider定義
final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);

// Widget実装例
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 強制リフレッシュ
              ref.read(productListProvider.notifier).refresh(force: true);
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // エラー表示（スナックバー）
          if (productState.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(productState.error!)),
              );
            });
          }

          // ローディングオーバーレイ
          return Stack(
            children: [
              // 商品リスト
              ListView.builder(
                itemCount: productState.products.length,
                itemBuilder: (context, index) {
                  final product = productState.products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('¥${product.price}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref
                            .read(productListProvider.notifier)
                            .removeProduct(product.id);
                      },
                    ),
                  );
                },
              ),

              // ローディング表示
              if (productState.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 新規商品追加
          final newProduct = Product(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'New Product',
            price: 500,
          );
          ref.read(productListProvider.notifier).addProduct(newProduct);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
