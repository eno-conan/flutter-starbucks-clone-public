import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/my_colors.dart';
import '../../../../core/models/cart.dart';
import '../../../../core/models/cart_detail.dart';
import '../../../../core/models/mobile_order_history.dart';
import '../../../../core/services/order_dialog_coordinator.dart';
import '../../../../data/repository/cart.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/mobile_order_pay/order_validation_service.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../mobileorder_tab_container.dart';

/// カート情報を更新してよいか確認
void askUpdateCurrentStoreAndProductDialog(BuildContext context, MobileOrderHistory orderHistory) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルトの40から縮小
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 30),
              const MyCustomText(
                text: '現在のオーダーで選択されている店舗と商品を上書きします。',
                fontSize: 14,
                softwrap: true,
              ),
              const SizedBox(height: 15),
              Row(
                spacing: 15,
                mainAxisAlignment: .end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MyColors.greenButton,
                      side: BorderSide(color: MyColors.greenButton, width: 0.8),
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      minimumSize: Size(0, 35),
                      splashFactory: InkSplash.splashFactory,
                    ),
                    child: const MyCustomText(text: 'キャンセル', textColor: MyColors.greenButton),
                  ),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final SupabaseClient supabase = Supabase.instance.client;
                        final authService = AuthService();
                        final CartRepository cartRepository = CartRepository(supabase);
                        final userId = authService.getUserId();

                        // 注文時間外か判定する（ダイアログ表示中に時間が経過した場合に対応）
                        final validationService = OrderValidationService.getInstance();
                        final validationResult = await validationService.validateStoreStatus(
                          orderHistory.storeNumber,
                        );

                        if (context.mounted) {
                          final shouldContinue = OrderDialogCoordinator.showValidationResultDialog(
                            context,
                            validationResult,
                          );

                          if (!shouldContinue) {
                            // 確認ダイアログを閉じる
                            Navigator.of(context).pop();
                            return;
                          }
                        }

                        // カート情報を削除
                        await cartRepository.clearUserCart(userId);

                        // 再注文内容でカートテーブルを更新
                        await _setupReorderFromDialog(cartRepository, userId, orderHistory);

                        if (kDebugMode) {
                          debugPrint('再注文処理が完了しました');
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          debugPrint('再注文処理でエラーが発生しました: $e');
                        }
                      }

                      // テーブル操作完了後モーダルを閉じる
                      Navigator.of(context).pop();

                      // モバイルオーダートップ（オーダータブ）へ遷移
                      context.go('${MobileOrderTabContainer.routeName}?tab=0');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: MyColors.greenButton,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      minimumSize: const Size(0, 35),
                    ),
                    child: const MyCustomText(text: 'OK', textColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 再注文のセットアップ処理（ダイアログ用）
Future<void> _setupReorderFromDialog(
  CartRepository cartRepository,
  String userId,
  MobileOrderHistory orderHistory,
) async {
  // カート概要情報の設定
  final cart = Cart(
    userId: userId,
    storeNumber: orderHistory.storeNumber,
    usage: orderHistory.usage,
  );
  await cartRepository.upsertCart(cart);

  // カート詳細情報の設定
  final cartDetails = orderHistory.items.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;
    return CartDetail(
      userId: userId,
      itemIndex: index,
      productId: item.productId,
      temperatureTypeId: item.temperatureTypeId,
      sizeId: item.sizeId,
      count: item.count,
      subtotalWithoutTax: item.subtotalWithoutTax,
    );
  }).toList();

  await cartRepository.insertCartDetails(cartDetails);
}
