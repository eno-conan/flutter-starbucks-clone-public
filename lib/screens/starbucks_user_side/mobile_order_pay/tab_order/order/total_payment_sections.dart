import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/my_colors.dart';
import '../../../../../core/models/card_model.dart';
import '../../../../../core/models/cart.dart';
import '../../../../../core/models/cart_detail.dart';
import '../../../../../core/services/order_dialog_coordinator.dart';
import '../../../../../provider/last_order_completion_provider.dart';
import '../../../../../provider/order_settlement_provider.dart';
import '../../../../../shared/widgets/dialogs/order_confirmation_dialog.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import '../../order_success_screen.dart';

/// 合計金額表示エリア
class GrandTotalSection extends ConsumerWidget {
  const GrandTotalSection({
    super.key,
    required this.taxRate,
    required this.totalAmountExcludingTax,
    required this.totalTax,
    required this.totalAmountIncludingTax,
    required this.itemCount,
  });
  final int taxRate;
  final String totalAmountExcludingTax;
  final String totalTax;
  final String totalAmountIncludingTax;
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Column(
        spacing: 10,
        crossAxisAlignment: .end,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: .end,
              spacing: 5,
              children: [
                MyCustomText(
                  text: '本体合計($itemCount点) ¥$totalAmountExcludingTax',
                  fontSize: 16,
                  textColor: MyColors.greyText,
                ),
                const SizedBox(height: 5),
                if (itemCount > 0)
                  MyCustomText(
                    text: '($taxRate%対象 ¥$totalAmountExcludingTax 消費税 ¥$totalTax)',
                    fontSize: 16,
                    textColor: MyColors.greyText,
                  )
                else
                  MyCustomText(text: '消費税 ¥$totalTax)', fontSize: 16, textColor: MyColors.greyText),
                const MyCustomText(text: '全ての商品に軽減税率', fontSize: 12, textColor: MyColors.greyText),
                const Text(
                  '複数商品を購入する場合',
                  style: TextStyle(
                    fontSize: 12,
                    color: MyColors.greyText,
                    decoration: TextDecoration.underline,
                    decorationColor: MyColors.greyText,
                  ),
                ),
                const SizedBox(height: 5),
                MyCustomText(
                  text: '総合計 ¥$totalAmountIncludingTax',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          Divider(color: MyColors.horizontalDivider, thickness: 0.5),
        ],
      ),
    );
  }
}

/// カード情報を表示利用規約・決済ボタン
class CardInfoAndButtonSettlement extends ConsumerStatefulWidget {
  const CardInfoAndButtonSettlement({
    super.key,
    required this.cart,
    required this.cartDetailsData,
    required this.totalAmountExcludingTax,
    required this.totalAmountIncludingTax,
    this.cardData,
    required this.onRefreshOrders,
    this.nickname,
  });
  final Cart? cart;
  final List<CartDetail>? cartDetailsData;
  final int totalAmountExcludingTax;
  final int totalAmountIncludingTax;
  final CardModel? cardData;
  final Future<void> Function() onRefreshOrders;
  final String? nickname;

  @override
  ConsumerState<CardInfoAndButtonSettlement> createState() => _CardInfoAndButtonSettlementState();
}

class _CardInfoAndButtonSettlementState extends ConsumerState<CardInfoAndButtonSettlement> {
  @override
  Widget build(BuildContext context) {
    bool isEnoughBalance = false;
    // 決済可能判定フラグ
    bool isAbleSettleFlg = false;
    // 決済実施中
    const bool isProcessing = false;

    // 商品がない状態のときは、決済不可のみ
    if (widget.cartDetailsData == null) {
      isEnoughBalance = true;
    }

    // 商品情報が存在し、カード残高が、注文商品一覧より少ない場合は決済不可
    if (widget.cartDetailsData != null && widget.cardData != null) {
      isAbleSettleFlg = widget.cardData!.balance >= Price(widget.totalAmountIncludingTax);
      isEnoughBalance = widget.cardData!.balance >= Price(widget.totalAmountExcludingTax);
    }

    // 完了画面への遷移
    void navigateToCompletePage() {
      widget.onRefreshOrders();
    }

    // 決済ボタン押下時の処理（Provider対応版）
    Future<void> handleSettlementButtonPressed() async {
      // 1. 店舗情報の検証
      if (widget.cart == null || widget.cart!.storeNumber.isEmpty) {
        if (context.mounted) {
          OrderDialogCoordinator.showSettlementError(context, '店舗情報が登録されていません');
        }
        return;
      }

      // 2. 店舗営業状況を検証
      final notifier = ref.read(orderSettlementProvider.notifier);
      final validationResult = await notifier.validateStoreStatus(widget.cart!.storeNumber);

      // 3. 検証結果に基づいてダイアログ表示
      if (!context.mounted) {
        return;
      }
      final shouldContinue = OrderDialogCoordinator.showValidationResultDialog(
        context,
        validationResult,
      );

      if (!shouldContinue) {
        return; // 検証失敗時は中断
      }

      // 4. 注文確認ダイアログを表示（Provider経由で決済処理）
      if (!context.mounted) {
        return;
      }

      // ローカル関数として決済処理を定義
      Future<void> processSettlementWithProvider() async {
        if (widget.cart == null || widget.cartDetailsData == null) {
          return;
        }

        final notifier = ref.read(orderSettlementProvider.notifier);

        // CircularProgressIndicator を表示
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
              ),
            );
          },
        );

        // 決済処理を実行
        await notifier.processSettlement(
          cart: widget.cart!,
          cartDetails: widget.cartDetailsData!,
          totalAmountExcludingTax: widget.totalAmountExcludingTax,
          totalAmountIncludingTax: widget.totalAmountIncludingTax,
          nickname: widget.nickname,
        );

        // 状態を監視して処理結果を反映
        final state = ref.read(orderSettlementProvider);

        if (context.mounted) {
          Navigator.of(context).pop(); // CircularProgressIndicator を閉じる
        }

        if (state is OrderSettlementSuccess) {
          // 注文完了時刻を記録
          ref.read(lastOrderCompletionProvider.notifier).markOrderCompleted();
          navigateToCompletePage();

          if (context.mounted) {
            context.go(OrderSuccessScreen.routeName, extra: {'store': state.completion});
          }
        } else if (state is OrderSettlementError) {
          if (context.mounted) {
            OrderDialogCoordinator.showSettlementError(context, state.message);
          }
        }

        // 処理完了後にProviderをリセット
        notifier.reset();
      }

      showOrderConfirmationDialog(context, processSettlementWithProvider, widget.cart);
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .end, // ここを追加して右寄せにする
        spacing: 15,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: .end,
              spacing: 5,
              children: [
                const MyCustomText(text: 'お支払い方法', fontSize: 16, textColor: MyColors.greyText),
                if (widget.cardData?.cardName != null) ...[
                  MyCustomText(
                    text: '${widget.cardData?.cardName}(メインカード)',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    textColor: MyColors.greyText,
                  ),
                  const SizedBox(height: 10),
                ],
                if (widget.cardData?.formattedBalance != null) ...[
                  MyCustomText(
                    text: '残高 ${widget.cardData?.formattedBalance}',
                    fontSize: 16,
                    textColor: MyColors.greyText,
                  ),
                  const SizedBox(height: 5),
                ],
                if (widget.cardData?.cardName == null || widget.cardData?.formattedBalance == null)
                  Row(
                    mainAxisAlignment: .end,
                    spacing: 5,
                    children: const [
                      Icon(Icons.warning, color: MyColors.errorMessageText),
                      MyCustomText(
                        text: 'カードが登録されていません',
                        textColor: MyColors.errorMessageText,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  )
                else if (!isEnoughBalance)
                  Row(
                    mainAxisAlignment: .end,
                    spacing: 5,
                    children: const [
                      Icon(Icons.warning, color: MyColors.errorMessageText),
                      MyCustomText(
                        text: '残高が不足しています',
                        textColor: MyColors.errorMessageText,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Align(
            // 以下の要素は中央寄せのまま
            child: Column(
              spacing: 15,
              children: [
                const Text(
                  '利用規約',
                  style: TextStyle(
                    fontSize: 12,
                    color: MyColors.greyText,
                    decoration: TextDecoration.underline,
                    decorationColor: MyColors.greyText,
                  ),
                ),
                FilledButton(
                  onPressed:
                      isAbleSettleFlg &&
                          !isProcessing &&
                          widget.cardData?.cardName != null &&
                          widget.cardData?.formattedBalance != null
                      ? handleSettlementButtonPressed
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        (isAbleSettleFlg &&
                            widget.cardData?.cardName != null &&
                            widget.cardData?.formattedBalance != null)
                        ? MyColors.greenButton
                        : MyColors.greyText,
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    minimumSize: Size(0, 50),
                    splashFactory: InkSplash.splashFactory,
                  ),
                  child: const MyCustomText(
                    text: '利用規約に同意の上、決済する',
                    textColor: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
