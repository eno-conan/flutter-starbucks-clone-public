import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_shell.dart';
import '../../app/menu.dart';
import '../../core/models/mobile_order_completion.dart';
import '../../core/models/mobile_order_history.dart';
import '../../screens/starbucks_store_side/mobileorder/orders.dart';
import '../../screens/starbucks_user_side/e_ticket/e_ticket_use_in_store.dart';
import '../../screens/starbucks_user_side/e_ticket/main.dart';
import '../../screens/starbucks_user_side/gift/gift_screen.dart';
import '../../screens/starbucks_user_side/gift/gift_starbucks_egift/egift_creation_screen.dart';
import '../../screens/starbucks_user_side/home/main.dart';
import '../../screens/starbucks_user_side/inbox/main.dart';
import '../../screens/starbucks_user_side/map/main.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/mobileorder_tab_container.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/order_success_screen.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/store/store_selection.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/tab_histories/histories_detail.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/tab_order/pickup_method.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/tab_order/product_selected.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/tab_order/products.dart';
import '../../screens/starbucks_user_side/pay/pay_screen.dart';
import '../../screens/starbucks_user_side/pay/payment/deposit_screen.dart';
import '../../screens/starbucks_user_side/pay/setting/pay_setting_screen.dart';
import '../../screens/starbucks_user_side/rewards/rewards_screen.dart';
import '../../screens/starbucks_user_side/setting/main.dart';
import '../../screens/starbucks_user_side/setting/switch_notify_setting/main.dart';
import '../../screens/starbucks_user_side/star_reward_exchange/main.dart';
import '../../utils/sanitization_utils.dart';

/// メイン画面・その他のルート定義
final class MainRoutes {
  static List<RouteBase> get routes => [
    // メニュー画面
    GoRoute(
      path: MenuPage.routeName,
      builder: (context, state) {
        final extra = GoRouter.of(context).state.extra as Map<String, dynamic>? ?? {};
        final showSnackBar = extra['showSnackBar'] as bool? ?? false;
        return MenuPage(showSnackBar: showSnackBar);
      },
      // routes: AppRouter.routeList,
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithCustomNavBar(navigationShell: navigationShell);
      },
      branches: [
        // ホームタブ
        StatefulShellBranch(
          routes: [GoRoute(path: Home.routeName, builder: (context, state) => Home())],
        ),
        // 支払タブ
        StatefulShellBranch(
          routes: [GoRoute(path: Pay.routeName, builder: (context, state) => Pay())],
        ),
        // 店舗タブ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Store.routeName,
              builder: (context, state) {
                return const Store();
              },
            ),
          ],
        ),
        // モバイルオーダータブ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: MobileOrderTabContainer.routeName,
              builder: (context, state) {
                final tabParam = SanitizationUtils.sanitizeQueryParameter(
                  state.uri.queryParameters['tab'] ?? '0',
                );
                final tabIndex = int.tryParse(tabParam) ?? 0;
                return MobileOrderTabContainer(initialTabIndex: tabIndex);
              },
              routes: [
                // 店舗選択
                GoRoute(
                  path: StoreSelect.routeName,
                  builder: (context, state) => const StoreSelect(),
                  // routes: [],
                ),
                // 受取方法選択
                GoRoute(
                  path: MobileOrderPickupMethod.routeName,
                  builder: (context, state) => const MobileOrderPickupMethod(),
                ),
                // 商品一覧
                GoRoute(
                  path: MobileOrderProducts.routeName,
                  builder: (context, state) => const MobileOrderProducts(),
                ),
                // 商品詳細
                GoRoute(
                  path: MobileOrderSelectedProduct.routeName,
                  builder: (context, state) => const MobileOrderSelectedProduct(),
                ),
                GoRoute(
                  path: MobileOrderPayTabHistoriesHistoryDetail.routeName,
                  builder: (context, state) {
                    final MobileOrderHistory order = state.extra! as MobileOrderHistory;
                    return MobileOrderPayTabHistoriesHistoryDetail(orderHistory: order);
                  },
                ),
              ],
            ),
          ],
        ),
        // Giftタブ
        StatefulShellBranch(
          routes: [GoRoute(path: Gift.routeName, builder: (context, state) => Gift())],
        ),
      ],
    ),
    // Home -> 設定画面
    GoRoute(
      path: Setting.routeName,
      builder: (context, state) {
        return const Setting();
      },
    ),
    // 設定画面-> 通知設定
    GoRoute(
      path: SwitchNotifySetting.routeName,
      pageBuilder: (context, state) =>
          _buildPageWithAnimationFromBottomToTop(const SwitchNotifySetting()),
    ), //     // Eギフトを贈る
    // ==========Home経由で表示==========
    // Home -> eチケット
    GoRoute(
      path: ETicket.routeName,
      builder: (context, state) {
        return const ETicket();
      },
    ),
    // Home -> Inbox
    GoRoute(
      path: InboxTopPage.routeName,
      builder: (context, state) {
        return const InboxTopPage();
      },
    ),
    // Home -> スターリワードに交換
    GoRoute(
      path: ExchangeStarReward.routeName,
      builder: (context, state) {
        return const ExchangeStarReward();
      },
    ),
    // eチケット店内利用画面
    GoRoute(
      path: ETicketUseInStore.routeName,
      pageBuilder: (context, state) =>
          _buildPageWithAnimationFromRightToLeft(const ETicketUseInStore()),
    ), // Home -> スターリワード
    GoRoute(
      path: Rewards.routeName,
      pageBuilder: (context, state) => _buildPageWithAnimationFromRightToLeft(const Rewards()),
      // routes: [
      //   // トップ -> スターリワード -> 会員ステータス
      //   GoRoute(
      //     path: StarRewardMemberStatus.routeName,
      //     pageBuilder: (context, state) =>
      //         _buildPageWithAnimationFromBottomToTop(const StarRewardMemberStatus()),
      //   ),
      //   // トップ -> スターリワード -> Star獲得・交換・失効履歴
      //   GoRoute(
      //     path: StarRewardExpirationDateRetainedStarsHistories.routeName,
      //     builder: (context, state) {
      //       return const StarRewardExpirationDateRetainedStarsHistories();
      //     },
      //   ),
      // ],
    ),
    // ==========Pay経由で表示==========
    // Pay ->　支払い
    GoRoute(
      path: PayPayment.routeName,
      builder: (context, state) {
        return const PayPayment();
      },
    ),
    // Pay -> 設定画面
    GoRoute(
      path: PaySettingPage.routeName,
      builder: (context, state) {
        return const PaySettingPage();
      },
    ),
    // ==========注文完了画面==========
    GoRoute(
      path: OrderSuccessScreen.routeName,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final MobileOrderCompletion selectedStore = extra?['store'] as MobileOrderCompletion;
        return OrderSuccessScreen(selectedStore: selectedStore);
      },
    ),
    // ==========eチケット関係==========
    GoRoute(
      path: GiftEgift.routeName,
      pageBuilder: (context, state) => _buildPageWithAnimationFromRightToLeft(const GiftEgift()),
    ),
    // ====================店舗側====================
    GoRoute(
      path: StoreSideOrderList.routeName,
      builder: (context, state) => const StoreSideOrderList(),
    ),
  ];

  /// 画面遷移アニメーション:右から左へスライドイン
  static CustomTransitionPage<void> _buildPageWithAnimationFromRightToLeft(Widget page) {
    return CustomTransitionPage<void>(
      child: page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = Offset(1.0, 0.0); // 右から左へスライド
        final Animatable<Offset> tween = Tween(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        final Animation<Offset> offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// 画面遷移アニメーション:下から上へスライドイン
  static CustomTransitionPage<void> _buildPageWithAnimationFromBottomToTop(Widget page) {
    return CustomTransitionPage<void>(
      child: page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = Offset(0.0, 1.0); // 下から上へスライド
        final Animatable<Offset> tween = Tween(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        final Animation<Offset> offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
