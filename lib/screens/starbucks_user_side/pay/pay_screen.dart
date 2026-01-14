import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/my_colors.dart';
import '../../../provider/auth_state_provider.dart';
import '../../../provider/connectivity_check_provider.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/splash_screen.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'state/pay_guest_content.dart';
import 'state/pay_login_content.dart';

///ヘッダーのテキスト
const String headerText = 'Starbucks Card';

///デジタルカードのパス
const String payCardSvgPath = 'assets/starbucks/svg/payment_card.svg';

///支払い画面トップ
class Pay extends ConsumerStatefulWidget {
  const Pay({super.key});
  static String routeName = '/starbucks_pay_top_page';

  @override
  ConsumerState<Pay> createState() => _PayState();
}

class _PayState extends ConsumerState<Pay> {
  @override
  Widget build(BuildContext context) {
    // ネットワーク接続状態を監視
    final nwConnectivity = ref.watch(connectivityCheckProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
      },
      child: nwConnectivity.when(
        loading: () => Center(
          child: const CircularProgressIndicator(
            color: MyColors.circularProgressIndicatorColor,
            strokeWidth: 4,
          ),
        ),
        error: (error, stackTrace) => Center(
          child: const CircularProgressIndicator(
            color: MyColors.circularProgressIndicatorColor,
            strokeWidth: 4,
          ),
        ),
        data: (connectivityResults) {
          final isOffline =
              connectivityResults.isEmpty ||
              connectivityResults.every((result) => result == ConnectivityResult.none);

          return isOffline
              ? FixedHeaderCommonComponent(
                  isLeadingIcon: false,
                  headerText: headerText,
                  isFab: false,
                  body: _OfflineContents(),
                )
              : _ContentsByAuthState();
        },
      ),
    );
  }
}

// オフライン時の表示画面
class _OfflineContents extends StatelessWidget {
  const _OfflineContents();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: .start,
        spacing: 30,
        children: const [
          SizedBox(height: 100), //オフラインを示すイラスト
          MyCustomText(text: '通信エラーが発生しました。', fontSize: 20, fontWeight: FontWeight.bold),
          MyCustomText(
            text: 'インターネット接続をご確認の上、再度お試しください',
            fontSize: 14,
            textColor: MyColors.greyText,
            fontWeight: FontWeight.bold,
          ),
          _ButtonReConnect(), //再接続ボタン
        ],
      ),
    );
  }
}

///再接続ボタン
class _ButtonReConnect extends ConsumerWidget {
  const _ButtonReConnect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () {
        // Providerを再読み込みするためにinvalidateを呼び出す
        ref.invalidate(connectivityCheckProvider);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: MyColors.greenButton,
        side: const BorderSide(color: MyColors.greenButton),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        minimumSize: const Size(0, 35), //垂直方向の余白調整
      ),
      child: const MyCustomText(
        text: 'もう一度試す',
        textColor: MyColors.greenText,
        // fontWeight: FontWeight.w700,
      ),
    );
  }
}

//認証状態に応じた表示制御
class _ContentsByAuthState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    return authAsync.when(
      loading: () => const SliverToBoxAdapter(child: SplashScreen()),
      error: (error, _) => SliverToBoxAdapter(child: ErrorScreen(error: error.toString())),
      data: (user) => user != null
          ? const PayLoginedContents()
          : const FixedHeaderCommonComponent(
              isLeadingIcon: false,
              headerText: headerText,
              isFab: true,
              body: PayNotLoginedContents(),
            ),
    );
  }
}
