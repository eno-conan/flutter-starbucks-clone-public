import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/my_colors.dart';
import '../../../../constants/order_type.dart';
import '../../../../core/models/cart.dart';
import '../../../../data/repository/cart.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../mobileorder_tab_container.dart';
import 'products.dart';

/// 利用方法（店内飲食・テイクアウト・ドライブスルーの選択画面）
class MobileOrderPickupMethod extends StatefulWidget {
  const MobileOrderPickupMethod({super.key});
  static String routeName = '/mobile_order_pickup_method';

  @override
  State<MobileOrderPickupMethod> createState() => _MobileOrderPickupMethodState();
}

class _MobileOrderPickupMethodState extends State<MobileOrderPickupMethod> {
  // ドライブスルー対象店舗かどうか
  bool isDriveThruAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final CartRepository cartRepository = CartRepository(supabase);
      final authService = AuthService();
      final bool isAvaileble = await cartRepository.isStoreDriveThruAvailable(
        authService.getUserId(),
      );
      setState(() {
        isDriveThruAvailable = isAvaileble;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ドライブスルー利用可能か取得時にエラー発生: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        icon: Icon(Icons.arrow_back_ios),
        headerText: '利用方法',
        isFab: false,
        onIconPressed: () {
          // モバイルオーダートップに戻る
          context.go(MobileOrderTabContainer.routeName);
        },
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: .start,
          children: [
            if (isDriveThruAvailable) // ドライブスルー(利用可能な場合のみ表示)
              _DriveThru(),
            _Togo(), // 持ち帰り
            _InsideStore(), //店内飲食
            _AttentionMessage(),
          ],
        ),
      ),
    );
  }
}

/// ドライブスルー
class _DriveThru extends ConsumerWidget {
  const _DriveThru();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: MyColors.settingDivider, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            // アイコン
            Column(),
            Column(
              spacing: 10,
              crossAxisAlignment: .start,
              children: [
                // アイコン
                const SizedBox(height: 5),
                const MyCustomText(text: 'ドライブスルー', fontWeight: FontWeight.bold, fontSize: 16),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.85,
                  child: const MyCustomText(
                    text: 'ドライブスルーレーンでバリスタへモバイルオーダーとお伝えください',
                    fontSize: 14,
                    textColor: MyColors.greyText,
                    softwrap: true,
                  ),
                ),
                const _SelectButton(orderType: OrderType.driveThru),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// TO GO（お持ち帰り）
class _Togo extends ConsumerWidget {
  const _Togo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: MyColors.settingDivider, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          crossAxisAlignment: .start,
          children: const [
            // アイコン
            Column(),
            Column(
              spacing: 10,
              crossAxisAlignment: .start,
              children: [
                // アイコン
                SizedBox(height: 5),
                MyCustomText(text: 'TOGO(お持ち帰り)', fontWeight: FontWeight.bold, fontSize: 16),
                _SelectButton(orderType: OrderType.toGo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 店内飲食
class _InsideStore extends ConsumerWidget {
  const _InsideStore();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: MyColors.settingDivider, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          children: [
            // アイコン
            Column(),
            Column(
              spacing: 10,
              crossAxisAlignment: .start,
              children: [
                const SizedBox(height: 5),
                const MyCustomText(text: '店内飲食', fontWeight: FontWeight.bold, fontSize: 16),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.85,
                  child: const MyCustomText(
                    text:
                        '※注文確定後に座席が確保できないことによるキャンセル、TO GO（お持ち帰り）への変更による消費税の返金はできません。あらかじめお席を確保の上ご注文ください',
                    textColor: Color(0xFFB1B1B1),
                    softwrap: true,
                    fontSize: 14,
                  ),
                ),
                const _SelectButton(orderType: OrderType.insideStore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 選択ボタン
class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.orderType});

  final OrderType orderType;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        // カート情報設定
        await _handleOrderTypeSelection(orderType);
        // 画面遷移
        if (context.mounted) {
          context.go('${MobileOrderTabContainer.routeName}${MobileOrderProducts.routeName}');
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: MyColors.greenButton,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        minimumSize: const Size(0, 35),
        splashFactory: InkSplash.splashFactory,
      ),
      child: const MyCustomText(text: '選択する', textColor: Colors.white),
    );
  }
}

/// 利用方法について、テーブルを更新
Future<void> _handleOrderTypeSelection(OrderType orderType) async {
  // カートテーブルデータを追加/挿入
  final SupabaseClient supabase = Supabase.instance.client;

  try {
    // 既存のカート情報を取得
    final CartRepository cartRepository = CartRepository(supabase);
    final authService = AuthService();
    final currentCart = await cartRepository.getUserCart(authService.getUserId());
    if (currentCart != null) {
      // 店内/持ち帰り/ドライブスルーの値を更新
      final Cart updateCart = currentCart.copyWith(usage: orderType.typeValue);
      await cartRepository.upsertCart(updateCart);
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('カート情報取得・更新時にエラー発生: $e');
    }
  }
}

///税込価格とかの注意書き
class _AttentionMessage extends StatelessWidget {
  const _AttentionMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .all(15),
      child: MyCustomText(text: '商品表示価格はすべて税込価格でーす\n利用方法によって税率が異なるよん♪', fontSize: 14),
    );
  }
}
