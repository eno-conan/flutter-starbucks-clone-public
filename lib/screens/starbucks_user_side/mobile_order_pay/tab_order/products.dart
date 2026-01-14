// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/my_colors.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/data_loading_performance_helper.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/navigation_performance_mixin.dart';
import '../../../../provider/mobile_order_selected_product_id_provider.dart';
import '../../../../provider/responsive_dimensions_provider.dart';
import '../../../../data/repository/product.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../mobileorder_tab_container.dart';
import 'product_selected.dart';

///商品一覧
class MobileOrderProducts extends StatefulWidget {
  const MobileOrderProducts({super.key});
  static String routeName = '/mobile_order_products';

  @override
  State<MobileOrderProducts> createState() => _MobileOrderProductsState();
}

class _MobileOrderProductsState extends State<MobileOrderProducts> {
  final GlobalKey<_ProductsState> _productsKey = GlobalKey<_ProductsState>();

  @override
  Widget build(BuildContext context) {
    // スマホの戻るボタン制御
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // モバイルオーダーのトップへ戻る
        context.go(MobileOrderTabContainer.routeName);
      },
      child: FixedHeaderCommonComponent(
        isLeadingIcon: true,
        icon: Icon(Icons.arrow_back_ios_new),
        headerText: 'Products',
        isFab: true,
        fabWidget: SizedBox(
          width: 128,
          child: FloatingActionButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            onPressed: () {
              _productsKey.currentState?._showCategoryBottomSheet();
            },
            backgroundColor: Colors.white,
            child: Row(
              mainAxisAlignment: .center,
              spacing: 3,
              children: const [
                MyCustomText(text: '絞り込む', fontSize: 16, fontWeight: FontWeight.bold),
                Icon(Icons.tune_outlined, color: Colors.black),
              ],
            ),
          ),
        ),
        onIconPressed: () {
          // モバイルオーダートップに戻る
          context.go(MobileOrderTabContainer.routeName);
        },
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: CustomScrollView(
            slivers: <Widget>[
              const _TaxAttentionMessage(),
              _Products(key: _productsKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxAttentionMessage extends StatelessWidget {
  const _TaxAttentionMessage();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: MyCustomText(text: '表示価格はすべて税込だよ!'),
      ),
    );
  }
}

class _Products extends StatefulWidget {
  const _Products({super.key});

  @override
  State<_Products> createState() => _ProductsState();
}

class _ProductsState extends State<_Products> {
  Map<String, List<Product>> _groupedProducts = {};
  List<String> _categories = [];
  String? _selectedCategory; // nullの場合は全カテゴリ表示
  bool _isLoading = true;
  bool _isError = false;
  late final ProductRepository _productRepository;

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepository(Supabase.instance.client);
    _loadData();
  }

  // 表示に必要なデータを取得
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      // 🔥 新しいパフォーマンス計測サービスを使用 - Repository経由でデータ取得
      await DataLoadingPerformanceHelper.measureDataLoadWithErrorHandling(
        'products_data_load',
        () async {
          final groupedProducts = await _productRepository.getProductsByCategory();
          
          _groupedProducts = groupedProducts;
          _categories = _groupedProducts.keys.toList();
          _isLoading = false;

          if (mounted) {
            setState(() {});
          }

          // 全商品のリストを返す
          final allProducts = groupedProducts.values.expand((products) => products).toList();
          return allProducts;
        },
        (error, stackTrace) {
          debugPrint('Error loading products: $error');
          _isLoading = false;
          _isError = true;
          if (mounted) {
            setState(() {});
          }
          return <Product>[];
        },
        cacheInfo: const CacheInfo(usedCache: false, cacheType: 'repository'),
        dataInfo: const DataInfo(
          itemCount: 0, // 実際の数は計測時に更新される
          dataType: 'products',
          source: 'repository',
        ),
      );
    } catch (e) {
      LoggerService.info('Unexpected error in _loadData: $e');
      _isLoading = false;
      _isError = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // カテゴリフィルタリング用のメソッド
  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // 表示用の商品リストを取得
  Map<String, List<Product>> _getDisplayProducts() {
    if (_selectedCategory == null) {
      return _groupedProducts;
    } else {
      return {_selectedCategory!: _groupedProducts[_selectedCategory] ?? []};
    }
  }

  // カテゴリ選択BottomSheetを表示
  void _showCategoryBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const MyCustomText(text: 'カテゴリを選択', fontSize: 18),
              const SizedBox(height: 16),
              // 全て表示オプション
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setModalState(() {
                      _selectedCategory = null;
                    });
                    await Future<void>.delayed(const Duration(milliseconds: 400));
                    _filterByCategory(null);
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  splashColor: Colors.grey.withOpacity(0.1),
                  highlightColor: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    title: const MyCustomText(text: '全て表示'),
                    leading: _selectedCategory == null
                        ? const Icon(
                            Icons.check_circle,
                            color: MyColors.circularProgressIndicatorColor,
                          )
                        : const Icon(Icons.radio_button_unchecked),
                  ),
                ),
              ),
              const Divider(),
              // カテゴリ別オプション
              ...(_categories
                  .map(
                    (category) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          setModalState(() {
                            _selectedCategory = category;
                          });
                          await Future<void>.delayed(const Duration(milliseconds: 400));
                          _filterByCategory(category);
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        },
                        splashColor: Colors.grey.withOpacity(0.1),
                        highlightColor: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          title: MyCustomText(text: category),
                          leading: _selectedCategory == category
                              ? const Icon(
                                  Icons.check_circle,
                                  color: MyColors.circularProgressIndicatorColor,
                                )
                              : const Icon(Icons.radio_button_unchecked),
                        ),
                      ),
                    ),
                  )
                  .toList()),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // エラー発生時
    if (_isError) {
      return const SliverFillRemaining(child: Center(child: Text('Error loading products')));
    }

    // ローディング中(画像プリロードは削除したので、データ取得のみ待つ)
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
        ),
      );
    }

    final displayProducts = _getDisplayProducts();

    return SliverMainAxisGroup(
      slivers: [
        ...displayProducts.entries.toList().asMap().entries.expand((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final category = entry.key;
          final products = entry.value;

          return [
            // カテゴリヘッダー
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: MyCustomText(
                  text: category,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  key: ValueKey('category_header_$category'),
                ),
              ),
            ),
            // 商品グリッド - SliverGridを使用
            _ProductGrid(products: products),
            // 区切り線(最後のカテゴリ以外)
            if (index < displayProducts.length - 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.grey, thickness: 1),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ];
        }),
      ],
    );
  }
}

/// 商品グリッドを表示するWidget
/// SliverGridを使用してLazy Loadingを実現
class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsiveDimensions = ref.watch(responsiveDimensionsProvider);
    final imageSizeFactor = responsiveDimensions.imageSizeFactor;
    final heightBetweenImageName = responsiveDimensions.heightBetweenImageName;

    // SliverGridを使用してLazy Loadingを実現
    // 画面外のアイテムは構築されず、
    // 画面付近(cacheExtent: デフォルト250px)のアイテムのみが構築される
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 25,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return ProductGridItem(
          product: products[index],
          imageSizeFactor: imageSizeFactor,
          heightBetweenImageName: heightBetweenImageName,
        );
      }, childCount: products.length),
    );
  }
}

/// 個別の商品アイテムを表示するWidget
class ProductGridItem extends StatefulWidget {
  const ProductGridItem({
    super.key,
    required this.product,
    required this.imageSizeFactor,
    required this.heightBetweenImageName,
  });

  final Product product;
  final double imageSizeFactor;
  final double heightBetweenImageName;

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> with NavigationPerformanceMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              measureNavigation(
                'product_selection',
                () {
                  ref
                      .read(selectedProductProvider.notifier)
                      .selectProduct(widget.product.id.toString(), widget.product.imageUrl);
                  // 商品詳細画面へ遷移
                  context.go(
                    '${MobileOrderTabContainer.routeName}${MobileOrderSelectedProduct.routeName}',
                  );
                },
                attributes: {
                  'product_id': widget.product.id.toString(),
                  'product_name': widget.product.name,
                  'category': widget.product.category,
                },
              );
            },
            splashFactory: InkRipple.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.grey.withOpacity(0.3),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                key: ValueKey('products_product_${widget.product.name}'),
                crossAxisAlignment: .start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 角丸の正方形画像
                  Align(
                    child: FractionallySizedBox(
                      widthFactor: widget.imageSizeFactor,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _ProductImage(product: widget.product),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: widget.heightBetweenImageName),
                  // 商品名
                  MyCustomText(
                    text: widget.product.name,
                    fontSize: 14,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 価格
                  MyCustomText(
                    text: widget.product.formattedPrice,
                    fontSize: 12,
                    textColor: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 🔥 画像読み込みをパフォーマンス測定するWidget
class _ProductImage extends StatefulWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage> {
  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // メモリ効率化: 画像を200pxにリサイズしてキャッシュ
      cacheWidth: 200,
      // デコード速度優先
      filterQuality: FilterQuality.low,
      // 🔥 読み込み開始時にトレース開始
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        if (frame != null) {
          // 画像読み込み完了
          return child;
        }

        // 読み込み中
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MyColors.circularProgressIndicatorColor,
            ),
          ),
        );
      },
      // エラー時の表示
      errorBuilder: (context, error, stackTrace) {
        _recordImageLoadError();
        debugPrint('Error loading image: $error');
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.error_outline, color: Colors.grey[600], size: 32),
        );
      },
    );
  }

  // 🔥 画像読み込みエラーを記録 - 新しいサービスを使用
  void _recordImageLoadError() {
    DataLoadingPerformanceHelper.recordImageLoadError(
      widget.product.imageUrl,
      errorMessage: 'Network image load failed',
    );
  }
}
