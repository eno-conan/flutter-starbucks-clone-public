// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/my_colors.dart';
import '../../../../constants/supabase_rpcs.dart';
import '../../../../core/models/product_detail.dart';
import '../../../../provider/mobile_order_selected_product_id_provider.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../mobileorder_tab_container.dart';
import 'product_selected/add_to_cart_button.dart';
import 'product_selected/product_description.dart';
import 'product_selected/product_image_and_name.dart';
import 'product_selected/quantity_selector.dart';
import 'product_selected/size_selector.dart';
import 'product_selected/temperature_selector.dart';
import 'products.dart';

class MobileOrderSelectedProduct extends ConsumerWidget {
  const MobileOrderSelectedProduct({super.key});
  static String routeName = '/mobile_order_product_select';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 商品IDを取得（nullチェック付き）
    final selectedProduct = ref.watch(selectedProductProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // 商品一覧に戻る
        context.go('${MobileOrderTabContainer.routeName}${MobileOrderProducts.routeName}');
      },
      child: FixedHeaderCommonComponent(
        isLeadingIcon: true,
        icon: Icon(Icons.close),
        onIconPressed: () {
          // 商品一覧に戻る
          context.go('${MobileOrderTabContainer.routeName}${MobileOrderProducts.routeName}');
        },
        headerText: '商品選択',
        appBarBackgroundColor: MyColors.backgroundGrey,
        bodyBackgroundColor: MyColors.backgroundGrey,
        isFab: false,
        body: CustomScrollView(
          slivers: [SliverToBoxAdapter(child: _Contents(selectedProduct: selectedProduct))],
        ),
      ),
    );
  }
}

/// Main content widget for product selection screen
class _Contents extends ConsumerStatefulWidget {
  const _Contents({required this.selectedProduct});
  final SelectedProduct selectedProduct;

  @override
  ConsumerState<_Contents> createState() => _ContentsState();
}

class _ContentsState extends ConsumerState<_Contents> {
  ProductDetail? product;
  bool isLoading = true;
  int selectedHotIcedIndex = 0; // HOT/ICED
  int selectedSizeIndex = 0; // サイズ
  int selectedCount = 1; // 注文数

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      // 選択商品の情報を取得
      final response = await supabase.rpc<Map<String, dynamic>>(
        Rpcs.getProductById,
        params: {'product_id_param': int.parse(widget.selectedProduct.id)},
      );

      final ProductDetail fetchedProduct = ProductDetail.fromJson({...response});
      setState(() {
        product = fetchedProduct;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // エラー処理（実際の実装ではスナックバーなどで表示するとよい）
      debugPrint('Error loading products: $e');
    }
  }

  void updateSelectedHotIced(int index) {
    if (selectedHotIcedIndex != index) {
      setState(() {
        selectedHotIcedIndex = index;
      });
    }
  }

  void updateSelectedSize(int index) {
    if (selectedSizeIndex != index) {
      setState(() {
        selectedSizeIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
          )
        : Column(
            crossAxisAlignment: .start,
            spacing: 5,
            children: [
              const SizedBox(height: 10),
              ProductImageAndName(selectedProduct: widget.selectedProduct, product: product!),
              const Divider(color: MyColors.settingDivider, thickness: 1),
              ProductDescription(product: product!),
              const Divider(color: MyColors.settingDivider, thickness: 1),
              TemperatureSelector(
                product: product!,
                selectedIndex: selectedHotIcedIndex,
                onSelected: updateSelectedHotIced,
              ),
              const SizedBox(height: 20),
              SizeSelector(
                product: product!,
                selectedIndex: selectedSizeIndex,
                onSelected: updateSelectedSize,
              ),
              const SizedBox(height: 5),
              const Divider(color: MyColors.settingDivider, thickness: 1),
              QuantitySelector(
                count: selectedCount,
                minusCount: () {
                  if (selectedCount > 1) {
                    setState(() {
                      selectedCount--;
                    });
                  }
                },
                plusCount: () {
                  setState(() {
                    selectedCount++;
                  });
                },
              ),
              const Divider(color: MyColors.settingDivider, thickness: 1),
              AddToCartButton(
                product: product!,
                selectedHotIcedIndex: selectedHotIcedIndex,
                selectedSizeIndex: selectedSizeIndex,
                selectedCount: selectedCount,
              ),
              const SizedBox(height: 20), // 下部にスペースを追加
            ],
          );
  }
}
