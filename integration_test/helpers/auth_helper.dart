import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testingapp/data/repository/user_fcm_tokens.dart';
import 'package:testingapp/services/auth_service.dart';

import '../test_config.dart';

class AuthHelper {
  /// テストユーザーでログインする。
  /// 事前条件: LoginPage が表示されている状態で呼ぶこと。
  static Future<void> loginAsTestUser(WidgetTester tester) async {
    // メールアドレス入力
    await tester.enterText(find.byKey(const Key('login_form_email')), TestConfig.testEmail);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // パスワード入力（enterText が内部でフォーカス移動するため tap 不要）
    await tester.enterText(find.byKey(const Key('login_form_password')), TestConfig.testPassword);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // キーボードを閉じてフォーカスを外す
    // ヘッダー部分（y=80 付近）をタップしてテキストフィールドのフォーカスを解除する
    // resizeToAvoidBottomInset: false のためキーボードがボタンを覆っている可能性がある
    await tester.tapAt(const Offset(200, 80));
    await tester.pump(const Duration(milliseconds: 500));

    // ログインボタンをタップ
    // find.byType(FilledButton) はページ上で唯一の FilledButton を確実に特定する
    await tester.tap(find.byType(FilledButton));

    // Supabase 認証ネットワーク処理を待つ
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // ログイン後のダイアログを dismiss する
    await _dismissPostLoginDialogIfPresent(tester);

    // _navigateToHome() 内の 1500ms delay + アニメーションを待つ
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// ログイン後に表示されるダイアログを dismiss する。
  /// ダイアログが存在しない場合は何もしない。
  static Future<void> _dismissPostLoginDialogIfPresent(WidgetTester tester) async {
    // ダイアログ出現を最大 5 秒待つ（500ms × 10回）
    Finder? buttonToTap;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));

      final laterButton = find.text('後で'); // パスキー作成提案ダイアログ
      final noButton = find.text('いいえ'); // 旧: 認証情報保存ダイアログ（互換のため残す）

      if (laterButton.evaluate().isNotEmpty) {
        buttonToTap = laterButton;
        break;
      } else if (noButton.evaluate().isNotEmpty) {
        buttonToTap = noButton;
        break;
      }
    }

    if (buttonToTap != null) {
      await tester.tap(buttonToTap);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  /// 指定したパスワードでログインを試みる（失敗ケース検証用）。
  /// 事前条件: LoginPage が表示されている状態で呼ぶこと。
  static Future<void> attemptLoginWithWrongPassword(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('login_form_email')), TestConfig.testEmail);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byKey(const Key('login_form_password')), TestConfig.wrongPassword);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(const Offset(200, 80));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(FilledButton));

    // Supabase 認証ネットワーク処理を待つ
    await tester.pumpAndSettle(const Duration(seconds: 15));
  }

  /// AuthService を使ってログアウトする。
  /// UI に依存しないため、どの画面からでも呼べる。
  static Future<void> logoutTestUser() async {
    try {
      final authService = AuthService(
        Supabase.instance.client,
        UserFcmTokenRepository(Supabase.instance.client),
      );
      await authService.signOutWithEmailAndPassword();
    } catch (_) {
      // ログアウト済みなどのエラーは無視
    }
  }

  /// AuthService を使って UI なしで Supabase に直接認証する。
  /// setUpAll で1回だけ呼ぶことを想定している。
  static Future<void> loginOnce() async {
    final authService = AuthService(
      Supabase.instance.client,
      UserFcmTokenRepository(Supabase.instance.client),
    );
    await authService.signInWithEmailAndPassword(TestConfig.testEmail, TestConfig.testPassword);
  }
}
