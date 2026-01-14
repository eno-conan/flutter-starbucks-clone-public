import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../constants/supabase_tables.dart';
import '../../../../../core/models/cart.dart';
import '../../../../../core/models/cart_detail.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../shared/widgets/dialogs/product_delete_confirmation_dialog.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import '../../mobileorder_tab_container.dart';
import '../products.dart';

final formatter = NumberFormat('#,###');

/// 商品選択エリア
class SelectedProductSection extends ConsumerWidget {
  const SelectedProductSection({
    super.key,
    required this.cart,
    required this.cartDetailsData,
    required this.onRefreshCart,
  });
  final Cart? cart;
  final List<CartDetail>? cartDetailsData;
  final Future<void> Function() onRefreshCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cartDetailsData == null) {
      // 商品がない場合の表示
      return TileNotExistAnyProduct(cart: cart);
    } else {
      // SliverListを使用して商品リストを表示
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < cartDetailsData!.length) {
              final product = cartDetailsData![index];
              return TileProductInfo(product: product, index: index, onRefreshCart: onRefreshCart);
            } else {
              // リストの最後の1つの要素として表示
              return MaterialGoSelectProductWhenProductIsNotEmpty();
            }
          },
          childCount: cartDetailsData!.length + 1, // 商品の数 + 1（商品追加用）
        ),
      );
    }
  }
}

/// 商品がない場合の表示
class TileNotExistAnyProduct extends StatelessWidget {
  const TileNotExistAnyProduct({super.key, required this.cart});
  final Cart? cart;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: cart != null
              ? () {
                  context.go(
                    '${MobileOrderTabContainer.routeName}${MobileOrderProducts.routeName}',
                  );
                }
              : null,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFFD8D8D8), width: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                MyCustomText(
                  text: '商品を選択してください',
                  textColor: cart != null ? Colors.black : Colors.grey,
                  fontSize: 16,
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: .center,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: cart != null ? Colors.black : Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 各商品情報を設定
class TileProductInfo extends ConsumerWidget {
  const TileProductInfo({
    super.key,
    required this.product,
    required this.index,
    required this.onRefreshCart,
  });
  final CartDetail product;
  final int index;
  final Future<void> Function() onRefreshCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFD8D8D8), width: 0.25)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                showProductDeleteConfirmationDialog(context, () async {
                  final SupabaseClient supabase = Supabase.instance.client;
                  final authService = AuthService();
                  // カート詳細テーブルの対象データ削除
                  await supabase
                      .from(Tables.cartsDetail)
                      .delete()
                      .eq('user_id', authService.getUserId())
                      .eq('item_index', product.itemIndex);
                  // 再取得して表示情報の更新
                  await onRefreshCart();
                });
              },
              child: const Icon(Icons.do_disturb_on_outlined, size: 28),
            ),
            const SizedBox(width: 15),
            MyCustomText(text: product.sizeName ?? '', textColor: Colors.black, fontSize: 16),
            const SizedBox(width: 5),
            MyCustomText(text: product.productName ?? '', textColor: Colors.black, fontSize: 16),
            const SizedBox(width: 5),
            MyCustomText(text: '${product.count}点', textColor: Colors.black, fontSize: 16),
            const Spacer(),
            MyCustomText(
              text: '¥${formatter.format(product.subtotalWithoutTax)}',
              textColor: Colors.black,
              fontSize: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// 商品追加用のWidget
class MaterialGoSelectProductWhenProductIsNotEmpty extends StatelessWidget {
  const MaterialGoSelectProductWhenProductIsNotEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // 商品一覧画面へ遷移
          context.go('${MobileOrderTabContainer.routeName}${MobileOrderProducts.routeName}');
        },
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFD8D8D8), width: 0.5)),
          ),
          child: Row(
            // mainAxisAlignment: .center,
            children: const [
              Icon(Icons.add_circle_outline, size: 28),
              SizedBox(width: 15),
              MyCustomText(text: '商品を追加する', textColor: Colors.black, fontSize: 16),
              Spacer(),
              Column(
                mainAxisAlignment: .center,
                children: [Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 16)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
