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
import '../../../../services/mobile_order_pay/store/tab_favorite_stores_service.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../mobileorder_tab_container.dart';
import 'update_confirmation_dialogs.dart';

///モバイルオーダー履歴詳細
class MobileOrderPayTabHistoriesHistoryDetail extends StatelessWidget {
  const MobileOrderPayTabHistoriesHistoryDetail({super.key, required this.orderHistory});

  static String routeName = '/starbucks_mobileorder_history_detail';
  final MobileOrderHistory orderHistory;

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: true,
      icon: Icon(Icons.arrow_back_ios),
      headerText: '履歴詳細',
      isFab: true,
      fabWidget: _ReOrderButton(orderHistory: orderHistory),
      onIconPressed: () {
        // 履歴タブ（インデックス1）を表示して戻る
        context.go('${MobileOrderTabContainer.routeName}?tab=1');
      },
      body: _Contents(orderHistory: orderHistory),
    );
  }
}

class _Contents extends StatefulWidget {
  const _Contents({required this.orderHistory});

  final MobileOrderHistory orderHistory;

  @override
  State<_Contents> createState() => _ContentsState();
}

class _ContentsState extends State<_Contents> {
  final FavoriteStoreService _favoriteService = FavoriteStoreService();
  final Map<String, bool> _favoriteStores = {};
  // こんな使い方できたんだ。
  bool get isFavorite => _favoriteStores[widget.orderHistory.storeNumber] ?? false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final isFavorite = await _favoriteService.isStoreFavorite(widget.orderHistory.storeNumber);
      setState(() {
        _favoriteStores[widget.orderHistory.storeNumber] = isFavorite;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入りの取得中にエラーが発生しました: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// お気に入り店舗の追加・削除
  Future<void> _toggleFavorite(String storeNumber) async {
    final isFavorite = _favoriteStores[storeNumber] ?? false;

    try {
      if (isFavorite) {
        await _favoriteService.removeFavoriteStore(storeNumber);
      } else {
        await _favoriteService.addFavoriteStore(storeNumber);
      }

      // Update state
      setState(() {
        _favoriteStores[storeNumber] = !isFavorite;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入りの更新中にエラーが発生しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  MyCustomText(
                    text: widget.orderHistory.storeName,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // お気に入りの追加・削除
                      _toggleFavorite(widget.orderHistory.storeNumber);
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border_sharp,
                      color: isFavorite ? MyColors.greenButton : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.info_outline),
                ],
              ),
              const SizedBox(height: 4),
              Row(children: [MyCustomText(text: widget.orderHistory.storeAddress, fontSize: 14)]),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const Divider(color: MyColors.horizontalDivider),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  MyCustomText(text: '利用方法', fontSize: 16, fontWeight: FontWeight.bold),
                  const Spacer(),
                  MyCustomText(text: widget.orderHistory.usageLabel, fontSize: 16),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const Divider(color: MyColors.horizontalDivider),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  MyCustomText(
                    text: '受取番号 ${widget.orderHistory.pickupNumber}',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const Spacer(),
                  MyCustomText(
                    text: widget.orderHistory.formattedOrderDate,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 商品一覧を表示
              ...widget.orderHistory.items.map(
                (item) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          MyCustomText(text: item.productName + (item.sizeName), fontSize: 14),
                          if (item.count > 1) MyCustomText(text: '${item.count}点', fontSize: 14),
                        ],
                      ),
                    ),
                    MyCustomText(text: '￥${item.subtotalWithoutTax}', fontSize: 16),
                  ],
                ),
              ),
              const Divider(color: MyColors.horizontalDivider),
              Row(
                children: [
                  MyCustomText(text: '本体合計', fontSize: 16),
                  const Spacer(),
                  MyCustomText(
                    text: '￥${widget.orderHistory.formattedPriceWithoutTax}',
                    fontSize: 16,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: .end,
                children: [
                  MyCustomText(
                    text:
                        '(10%対象 ￥${widget.orderHistory.formattedPriceWithoutTax} 消費税 ￥${widget.orderHistory.formattedTax})',
                    fontSize: 14,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: .end,
                children: [
                  MyCustomText(text: '総合計', fontSize: 18, fontWeight: FontWeight.bold),
                  Spacer(),
                  MyCustomText(
                    text: '￥${widget.orderHistory.formattedPriceWithTax}',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const Divider(color: MyColors.horizontalDivider),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  MyCustomText(text: '支払い方法', fontSize: 16, fontWeight: FontWeight.bold),
                  const Spacer(),
                  MyCustomText(text: widget.orderHistory.paymentMethod, fontSize: 16),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const Divider(color: MyColors.horizontalDivider),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  MyCustomText(text: 'オーダーID', fontSize: 16, fontWeight: FontWeight.bold),
                  const Spacer(),
                  MyCustomText(text: widget.orderHistory.orderId, fontSize: 16),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}

///再注文ボタン
class _ReOrderButton extends StatelessWidget {
  const _ReOrderButton({required this.orderHistory});

  final MobileOrderHistory orderHistory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 150,
      child: FloatingActionButton(
        elevation: 2,
        heroTag: null,
        onPressed: () async {
          try {
            final supabase = Supabase.instance.client;
            final authService = AuthService();
            final cartRepository = CartRepository(supabase);
            final validationService = OrderValidationService.getInstance();
            final userId = authService.getUserId();

            // 注文時間外か判定する
            final validationResult = await validationService.validateStoreStatus(
              orderHistory.storeNumber,
            );
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
                askUpdateCurrentStoreAndProductDialog(context, orderHistory);
              }
            } else {
              // カート情報がない場合は直接設定
              await _setupReorder(cartRepository, userId, orderHistory);
              if (context.mounted) {
                context.go(MobileOrderTabContainer.routeName);
              }
            }
          } catch (e) {
            // エラーハンドリング
            if (kDebugMode) {
              debugPrint('再注文処理でエラーが発生しました: $e');
            }
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('エラーが発生しました。もう一度お試しください。')));
            }
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: MyColors.fabGreenButton,
        child: const MyCustomText(
          text: '再注文へすすむ',
          fontSize: 18,
          textColor: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 再注文のセットアップ処理
  Future<void> _setupReorder(
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
}
