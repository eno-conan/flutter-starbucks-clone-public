import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../screens/starbucks_user_side/signin/login.dart';
import '../../screens/starbucks_user_side/signup/signup.dart';
import '../../screens/starbucks_user_side/signup/signup_completion.dart';
import '../../screens/starbucks_user_side/signup/signup_error.dart';
import '../../screens/starbucks_user_side/signup_pre/pre_signup.dart';
import '../../screens/starbucks_user_side/signup_pre/pre_signup_completion.dart';

/// 認証関連のルート定義
final class AuthRoutes {
  static List<RouteBase> get routes => [
    // ====================ユーザー側====================
    //新規会員仮登録
    GoRoute(
      path: PreSignUp.routeName,
      pageBuilder: (context, state) => _buildPageWithAnimationFromBottomToTop(const PreSignUp()),
    ),
    //新規会員仮登録完了
    GoRoute(
      path: PreSignUpCompletion.routeName,
      builder: (context, state) {
        return const PreSignUpCompletion();
      },
    ),
    //新規会員登録
    GoRoute(
      path: SignUp.routeName,
      builder: (context, state) {
        return const SignUp();
      },
    ),
    //新規会員登録失敗画面
    GoRoute(
      path: SignUpError.routeName,
      builder: (context, state) {
        return const SignUpError();
      },
    ),
    //新規会員本登録完了
    GoRoute(
      path: SignUpCompletion.routeName,
      builder: (context, state) {
        return const SignUpCompletion();
      },
    ),
    // ログイン画面
    GoRoute(
      path: LoginPage.routeName,
      builder: (context, state) {
        return const LoginPage();
      },
    ),
  ];

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
