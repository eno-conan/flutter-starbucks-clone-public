import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../constants/my_colors.dart';
import '../../../../../constants/supabase_tables.dart';
import '../../../../../core/models/cart_detail.dart';
import '../../../../../core/models/product_detail.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../shared/widgets/dialogs/error_dialog.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import '../../mobileorder_tab_container.dart';
import 'common_widgets.dart';

/// Widget for add to cart button with functionality
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({
    super.key,
    required this.product,
    required this.selectedHotIcedIndex,
    required this.selectedSizeIndex,
    required this.selectedCount,
  });

  final ProductDetail product;
  final int selectedHotIcedIndex;
  final int selectedSizeIndex;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return PaddingContents(
      body: Row(
        mainAxisAlignment: .end,
        children: [
          SizedBox(
            width: 100, // 幅を広げる
            child: FloatingActionButton(
              elevation: 1,
              heroTag: null,
              onPressed: () async {
                try {
                  final authService = AuthService();
                  final SupabaseClient supabase = Supabase.instance.client;
                  // 現在の状態を取得
                  final currentCartDetails = await supabase.from(Tables.cartsDetail).select();
                  // 追加するデータの準備
                  final CartDetail cartDetail = CartDetail(
                    userId: authService.getUserId(),
                    itemIndex: currentCartDetails.isEmpty ? 0 : currentCartDetails.length,
                    productId: product.id,
                    temperatureTypeId: selectedHotIcedIndex + 1,
                    sizeId: selectedSizeIndex + 1,
                    count: selectedCount,
                    subtotalWithoutTax: product.price[selectedSizeIndex] * selectedCount,
                  );
                  // データ追加
                  await supabase
                      .from(Tables.cartsDetail)
                      .insert(cartDetail.toJson())
                      .select()
                      .maybeSingle();
                  // モバイルオーダートップに戻る
                  if (context.mounted) {
                    context.go(MobileOrderTabContainer.routeName);
                  }
                } catch (e) {
                  if (context.mounted) {
                    showErrorDialog(context, '商品のカート追加失敗：$e');
                  }
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
              backgroundColor: MyColors.fabGreenButton,
              child: const MyCustomText(text: '決定する', fontSize: 18, textColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
