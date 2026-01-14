import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/my_colors.dart';
import '../../../../core/models/cart.dart';
import '../../../../core/models/cart_detail.dart';
import '../../../../core/models/mobile_order_history.dart';
import '../../../../core/models/store_mobile_order.dart';
import '../../../../core/services/order_dialog_coordinator.dart';
import '../../../../data/repository/cart.dart';
import '../../../../provider/mobile_order_selected_store_provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/mobile_order_pay/order_validation_service.dart';
import '../mobileorder_tab_container.dart';
import 'histories_detail.dart';
import 'update_confirmation_dialogs.dart';

///モバイルオーダー：履歴タブ
class MobileOrderPayTabHistories extends StatelessWidget {
  const MobileOrderPayTabHistories({super.key, required this.orders});
  final List<MobileOrderHistory> orders;

  @override
  Widget build(BuildContext context) {
    // 履歴が空の場合
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/starbucks/png/no_history.png', width: 120, height: 150),
            SizedBox(height: 16),
            Text(
              '注文履歴はありません。\nご注文お待ちしております！',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final order = orders[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: LinearBorder.none,
              margin: EdgeInsets.symmetric(vertical: 5),
              child: InkWell(
                onTap: () {
                  context.go(
                    '${MobileOrderTabContainer.routeName}${MobileOrderPayTabHistoriesHistoryDetail.routeName}',
                    extra: order, // 詳細画面にオーダー情報を渡す
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DateAndStoreName(
                            date: order.formattedOrderDate,
                            storeName: order.storeName,
                          ),
                          SizedBox(height: 12),
                          OrderCountAndMenuWithIcon(items: order.items),
                          SizedBox(height: 16),
                          _ReOrderButton(order: order),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }, childCount: orders.length),
        ),
      ],
    );
  }
}

///日付・店舗名
class DateAndStoreName extends StatelessWidget {
  const DateAndStoreName({super.key, required this.date, required this.storeName});

  final String date;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(date, style: TextStyle(fontSize: 14, color: Colors.black54)),
        SizedBox(height: 4),
        Text(storeName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

///注文品・アイコン
class OrderCountAndMenuWithIcon extends StatelessWidget {
  const OrderCountAndMenuWithIcon({super.key, required this.items});

  final List<MobileOrderHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    // 商品の合計点数を計算
    final totalItems = items.fold(0, (sum, item) => sum + item.count);

    // 最初の商品名を表示し、2つ以上ある場合は「他」を追加
    String displayText = items.isNotEmpty ? items[0].productName : '';

    if (items.length > 1) {
      displayText += ' 他';
    }

    return Row(
      children: [
        Text(totalItems.toString(), style: TextStyle(fontSize: 16)),
        SizedBox(width: 8),
        Expanded(
          child: Text(displayText, style: TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
        ),
        Icon(Icons.chevron_right, color: Colors.black54),
      ],
    );
  }
}

///再注文ボタン
class _ReOrderButton extends ConsumerWidget {
  const _ReOrderButton({required this.order});
  final MobileOrderHistory order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () async {
        try {
          final supabase = Supabase.instance.client;
          final authService = AuthService();
          final cartRepository = CartRepository(supabase);
          final validationService = OrderValidationService.getInstance();
          final userId = authService.getUserId();

          // 注文時間外か判定する
          final validationResult = await validationService.validateStoreStatus(order.storeNumber);
          if (context.mounted) {
            final shouldContinue = OrderDialogCoordinator.showValidationResultDialog(
              context,
              validationResult,
            );

            if (!shouldContinue) {
              // 検証失敗 - ダイアログは既に表示され、ユーザーが閉じる
              // 処理を中断
              return;
            }
          }

          // カート情報の存在確認
          final hasExistingCart = await cartRepository.getUserCart(userId) != null;
          final hasCartDetails = await cartRepository.hasCartDetails(userId);

          if (hasExistingCart || hasCartDetails) {
            // 既存カート情報がある場合は確認ダイアログを表示
            if (context.mounted) {
              askUpdateCurrentStoreAndProductDialog(context, order);
            }
          } else {
            // カート情報がない場合は直接設定
            await _setupReorder(ref, cartRepository, userId, order);
            if (context.mounted) {
              context.go(MobileOrderTabContainer.routeName);
            }
          }
        } catch (e) {
          // エラーハンドリング
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('エラーが発生しました。もう一度お試しください。')));
          }
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: MyColors.greenButton,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        minimumSize: const Size(0, 35),
      ),
      child: const Text('再注文へすすむ', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  /// 再注文のセットアップ処理
  Future<void> _setupReorder(
    WidgetRef ref,
    CartRepository cartRepository,
    String userId,
    MobileOrderHistory order,
  ) async {
    // 店舗情報設定
    final StoreMobileOrder store = StoreMobileOrder(
      storeNumber: order.storeNumber,
      storeName: order.storeName,
      address: order.storeAddress,
    );
    ref.read(selectedStoreProvider.notifier).store = store;

    // カート概要情報の設定
    final cart = Cart(userId: userId, storeNumber: order.storeNumber, usage: order.usage);
    await cartRepository.upsertCart(cart);

    // カート詳細情報の設定
    final cartDetails = order.items.asMap().entries.map((entry) {
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
}
