import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/logger_service.dart';
import 'auth_service.dart';

/// 通知許可管理サービス
///
/// このサービスは以下の機能を提供します：
/// - FCM通知許可の一回限りリクエスト管理
/// - ログイン成功時の通知許可処理
/// - 重複リクエストの防止
class NotificationPermissionService {
  NotificationPermissionService(this._authService);
  static const String _hasRequestedPermissionKey = 'has_requested_notification_permission';
  static const String _userIdKey = 'last_permission_requested_user_id';

  final AuthService _authService;

  /// ログイン成功後に通知許可をリクエストする
  ///
  /// 各ユーザーに対して一回のみ実行される
  /// すでにリクエスト済みの場合は再度表示されない
  Future<void> requestPermissionAfterLogin() async {
    try {
      final currentUserId = _authService.getUserId();
      final prefs = await SharedPreferences.getInstance();

      // 現在のユーザーが既にリクエスト済みかチェック
      final hasRequested = prefs.getBool(_hasRequestedPermissionKey) ?? false;
      final lastUserId = prefs.getString(_userIdKey);

      // 同じユーザーで既にリクエスト済みなら何もしない
      if (hasRequested && lastUserId == currentUserId) {
        return;
      }

      // 通知許可をリクエスト
      await _requestPermission();

      // リクエスト済みフラグを設定
      await prefs.setBool(_hasRequestedPermissionKey, true);
      await prefs.setString(_userIdKey, currentUserId);
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('通知許可リクエストエラー: $e');
      }
    }
  }

  /// Firebase Cloud Messaging (FCM) の通知許可をリクエストし、FCMトークンを取得・設定する
  ///
  /// このメソッドは以下の処理を順次実行します：
  /// 1. Firebase Messaging インスタンスから通知許可をリクエスト
  /// 2. FCMトークンを取得
  /// 3. 許可状況に応じてトークンと通知設定を保存
  ///
  /// **許可状況の処理：**
  /// - `authorized` または `provisional`：通知許可済みとして処理
  /// - その他：通知拒否として処理
  ///
  /// **エラーハンドリング：**
  /// - FCMトークン取得失敗時はデバッグコンソールに出力
  /// - メソッド全体の例外は無視（アプリクラッシュを防止）
  ///
  /// **依存関係：**
  /// - `FirebaseMessaging` インスタンス
  /// - `_authService.setFcmTokenAndNotifySetting()` メソッド
  Future<void> _requestPermission() async {
    try {
      // Request notification permission
      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (fcmToken != null) {
          await _authService.setFcmTokenAndNotifySetting(fcmToken, true);
        } else {
          if (kDebugMode) {
            LoggerService.warn('Failed to get FCM token');
          }
        }
      } else {
        if (fcmToken != null) {
          await _authService.setFcmTokenAndNotifySetting(fcmToken, false);
        } else {
          if (kDebugMode) {
            LoggerService.warn('Failed to get FCM token');
          }
        }
        if (kDebugMode) {
          LoggerService.info('Notification permission denied by user');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Error requesting notification permission: $e');
      }
    }
  }

  /// 通知許可リクエスト履歴をクリア（テスト用）
  Future<void> clearPermissionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasRequestedPermissionKey);
    await prefs.remove(_userIdKey);
  }
}
