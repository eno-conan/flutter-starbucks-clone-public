import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/my_colors.dart';
import '../../provider/auth_state_provider.dart';
import '../../screens/starbucks_user_side/pay/payment/deposit_screen.dart';
import '../../screens/starbucks_user_side/signin/login.dart';
import '../../screens/starbucks_user_side/signup_pre/pre_signup.dart';
import 'texts/my_custom_text.dart';

/// 認証状態に応じて適切なFloating Action Buttonを表示するウィジェット
///
/// ユーザーの認証状態を監視し、以下の3つの状態に応じて表示を切り替えます：
/// - ローディング中: 何も表示しない（SizedBox.shrink）
/// - 未ログイン: ログインと新規会員登録のボタンを表示
/// - ログイン済み: 残高表示と支払いボタン([CurrentMoneyBalance])を表示
///
/// このウィジェットは[authStateProvider]を監視し、
/// リアルタイムで認証状態の変更に自動的に反応します。
///
/// Example:
/// ```dart
/// Scaffold(
///   floatingActionButton: SignupSignInFloatingActionButton(),
/// )
/// ```
class SignupSignInFloatingActionButton extends ConsumerWidget {
  const SignupSignInFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // リアルタイムの認証状態を監視
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      // loading時は何も表示しない（FloatingActionButtonとして空のウィジェットを返す）
      loading: () => const SizedBox.shrink(),
      error: (error, _) => _SignInSignUpFabStack(),
      data: (user) {
        return user != null
            ? const CurrentMoneyBalance() // ログイン時
            : _SignInSignUpFabStack(); // 未ログイン時
      },
    );
  }
}

// ログイン・新規登録のFABボタン設定用Stackウィジェット
class _SignInSignUpFabStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _FloatingActionButtonBuilder(bottom: 10, width: 150, widget: _SignUpFloatingButton()),
        _FloatingActionButtonBuilder(bottom: 90, width: 100, widget: _LoginFloatingButton()),
      ],
    );
  }
}

// FloatingActionButton土台
class _FloatingActionButtonBuilder extends StatelessWidget {
  const _FloatingActionButtonBuilder({
    required this.bottom,
    required this.width,
    required this.widget,
  });
  final double bottom;
  final double width;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: 5,
      child: SizedBox(width: width, child: widget),
    );
  }
}

///ログインボタン
class _LoginFloatingButton extends StatelessWidget {
  const _LoginFloatingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          context.push(LoginPage.routeName);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: Colors.white,
        child: const MyCustomText(text: 'ログイン', fontSize: 18),
      ),
    );
  }
}

///新規会員登録ボタン
class _SignUpFloatingButton extends StatelessWidget {
  const _SignUpFloatingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          // 仮登録用のフォーム画面表示
          context.push(PreSignUp.routeName);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: MyColors.fabGreenButton,
        child: const MyCustomText(text: '新規会員登録', textColor: Colors.white, fontSize: 18),
      ),
    );
  }
}

/// 残高表示のFloatButton
class CurrentMoneyBalance extends StatelessWidget {
  const CurrentMoneyBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 100,
      child: FloatingActionButton(
        heroTag: null, // Disables the hero transition
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: MyColors.fabGreenButton,
        onPressed: () {
          // 支払い画面へ
          context.push(PayPayment.routeName);
        },
        child: const Row(
          mainAxisAlignment: .center,
          spacing: 5,
          children: [MyCustomText(text: '支払う', fontSize: 18, textColor: Colors.white)],
        ),
      ),
    );
  }
}
