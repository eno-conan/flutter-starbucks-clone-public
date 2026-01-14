// lib/config/deep_link_paths.dart
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../core/services/logger_service.dart';
import '../screens/starbucks_user_side/home/main.dart';
import '../screens/starbucks_user_side/signup/signup.dart';
import '../screens/starbucks_user_side/signup/signup_error.dart';
import '../services/auth_service.dart';
import '../utils/sanitization_utils.dart';

enum DeepLinkPath {
  register('/register')
  // 今後のパスをここに追加
  // profile('/profile'),
  // settings('/settings'),
  ;

  const DeepLinkPath(this.path);
  final String path;

  /// パス文字列からEnumを取得
  static DeepLinkPath? fromString(String path) {
    try {
      return DeepLinkPath.values.firstWhere((e) => e.path == path);
    } catch (_) {
      return null;
    }
  }

  /// このパスに対する処理を実行
  void handle(Uri uri, GoRouter router, AuthService authService) {
    switch (this) {
      case DeepLinkPath.register:
        _handleRegister(uri, router, authService);
      // case DeepLinkPath.profile:
      //   _handleProfile(uri, router, authService);
      //   break;
    }
  }

  /// /register パスの処理
  void _handleRegister(Uri uri, GoRouter router, AuthService authService) {
    final userId = authService.checkUserLoginStatus();

    if (userId != null) {
      if (kDebugMode) {
        LoggerService.info('ユーザーは既にログイン済みのため、ホーム画面に遷移します');
      }
      router.go(Home.routeName);
    } else {
      final token = uri.queryParameters['token'] ?? '';

      // HTMLエスケープとサニタイゼーションを適用
      final sanitizedToken = SanitizationUtils.sanitizeToken(token);

      if (sanitizedToken.isEmpty || !_isValidToken(sanitizedToken)) {
        if (kDebugMode && token != sanitizedToken) {
          LoggerService.warn('Token was sanitized due to suspicious content');
        }
        router.go(SignUpError.routeName);
      } else {
        router.go(SignUp.routeName, extra: {'token': sanitizedToken});
      }
    }
  }

  /// トークンの基本的な検証
  bool _isValidToken(String token) {
    if (token.length < 6 || token.length > 64) {
      return false;
    }
    final tokenRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
    return tokenRegex.hasMatch(token);
  }
}
