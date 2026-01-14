import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_tables.dart';
import '../core/services/logger_service.dart';

/// 認証関係の処理を行うクラス
class AuthService {
  AuthService();

  final supabase = Supabase.instance.client;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Googleの認証スコープ
  static const List<String> _googleScopes = <String>[
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'openid',
  ];

  /// 認証状態の確認
  bool isAuthenticated() {
    return supabase.auth.currentUser != null;
  }

  /// Crashlyticsにユーザー識別子を設定（UUID）
  Future<void> _setCrashlyticsUser() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
        await FirebaseCrashlytics.instance.setCustomKey('auth_status', 'authenticated');
        if (kDebugMode) {
          LoggerService.info('Crashlytics: ユーザー識別子を設定 (UUID)');
        }
      }
    } catch (e) {
      // Crashlytics設定のエラーはアプリの動作に影響を与えないようキャッチ
      if (kDebugMode) {
        LoggerService.warn('Crashlytics: ユーザー識別子の設定に失敗: $e');
      }
    }
  }

  /// Crashlyticsのユーザー識別子をクリア
  Future<void> _clearCrashlyticsUser() async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      await FirebaseCrashlytics.instance.setCustomKey('auth_status', 'unauthenticated');
      if (kDebugMode) {
        LoggerService.info('Crashlytics: ユーザー識別子をクリア');
      }
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Crashlytics: ユーザー識別子のクリアに失敗: $e');
      }
    }
  }

  /// Google Sign-In authentication (初期化は既に完了済み)
  Future<void> initializeGoogleSignIn() async {
    // 既に認証済みの場合はスキップ
    if (isAuthenticated()) {
      // 認証済みの場合、Crashlyticsにユーザー情報を設定
      await _setCrashlyticsUser();
      return;
    }

    // 初期化は既に完了しているので、直接認証処理を実行
    await _performAuthentication();
  }

  /// 認証処理の実行
  Future<void> _performAuthentication() async {
    try {
      final googleUser = await _googleSignIn.attemptLightweightAuthentication();

      if (googleUser == null) {
        throw Exception('attemptLightweightAuthentication failed');
      }

      var authorization = await googleUser.authorizationClient.authorizationForScopes(
        _googleScopes,
      );

      // If we don't have authorization, request it
      if (authorization == null) {
        final authorizeResult = await googleUser.authorizationClient.authorizeScopes(_googleScopes);

        if (authorizeResult.accessToken.isEmpty) {
          throw Exception('Failed to get authorization after user granted it');
        }

        // Update authorization with the newly obtained one
        authorization = authorizeResult;
      }

      // Step 3: Get tokens
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = authorization.accessToken;

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      // Step 4: Sign in with Supabase using the tokens
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 認証成功後、Crashlyticsにユーザー識別子を設定
      await _setCrashlyticsUser();
    } catch (error) {
      // 認証エラーはCrashlyticsに記録（機密情報は含めない）
      await FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'Google authentication failed',
      );
      rethrow;
    }
  }

  /// ログインユーザ情報取得
  Future<String?> retrieveLoginUser() async {
    try {
      final User? user = supabase.auth.currentUser;
      return user?.email;
    } catch (error) {
      rethrow;
    }
  }

  /// ユーザーIDを取得する共通関数
  String getUserId() {
    final SupabaseClient supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      LoggerService.warn('ユーザーが認証されていません');
      // 通常のログインチェック失敗なのでCrashlyticsには記録しない
      throw Exception('ユーザーが認証されていません');
    }
    return userId;
  }

  /// ログイン状態をチェックする（例外をthrowしない）
  ///
  /// ディープリンク処理などでログイン状態を確認したいが、
  /// 例外をキャッチしたくない場合に使用する
  ///
  /// Returns: ログイン済みの場合はユーザーID、未ログインの場合はnull
  String? checkUserLoginStatus() {
    try {
      final userId = supabase.auth.currentUser?.id;
      return userId;
    } catch (e) {
      // 予期しないエラーが発生した場合はログに記録してnullを返す
      LoggerService.warn('ログイン状態の確認中にエラーが発生しました: $e');
      return null;
    }
  }

  /// Emailとパスワードによるサインイン処理
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);

      // 認証成功後、Crashlyticsにユーザー識別子を設定
      await _setCrashlyticsUser();
    } catch (error) {
      // メールアドレスやパスワード誤りの詳細はCrashlyticsに記録しない
      // エラーの種類のみ記録
      await FirebaseCrashlytics.instance.recordError(
        Exception('Email/password sign-in failed'),
        StackTrace.current,
        reason: 'Sign-in attempt failed (credentials not logged)',
      );
      rethrow;
    }
  }

  /// Emailとパスワードによるサインアウト処理
  Future<void> signOutWithEmailAndPassword() async {
    try {
      // サインアウト前にCrashlyticsのユーザー識別子をクリア
      await _clearCrashlyticsUser();

      await supabase.auth.signOut();
    } catch (error) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'Sign-out failed',
      );
      rethrow;
    }
  }

  ///サインイン処理
  Future<void> signInWithGoogle() async {
    try {
      // Check if authenticate is supported on this platform
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Authenticate not supported on this platform');
      }

      // Step 1: Authenticate the user
      final googleUser = await _googleSignIn.authenticate();

      var authorization = await googleUser.authorizationClient.authorizationForScopes(
        _googleScopes,
      );
      // If we don't have authorization, request it
      if (authorization == null) {
        final authorizeResult = await googleUser.authorizationClient.authorizeScopes(_googleScopes);

        if (authorizeResult.accessToken.isEmpty) {
          throw Exception('Failed to get authorization after user granted it');
        }

        // Update authorization with the newly obtained one
        authorization = authorizeResult;
      }

      // Step 3: Get tokens
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = authorization.accessToken;

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      // Step 4: Sign in with Supabase using the tokens
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 認証成功後、Crashlyticsにユーザー識別子を設定
      await _setCrashlyticsUser();
    } catch (error) {
      // 認証エラーをCrashlyticsに記録（機密情報は含めない）
      await FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'Google sign-in failed',
      );
      rethrow;
    }
  }

  ///サインアウト処理
  Future<void> signOutWithGoogle() async {
    try {
      // サインアウト前にCrashlyticsのユーザー識別子をクリア
      await _clearCrashlyticsUser();

      await supabase.auth.signOut();

      await _googleSignIn.signOut();
    } catch (error) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'Google sign-out failed',
      );
      rethrow;
    }
  }

  ///デバイストークンの設定
  Future<void> setFcmTokenAndNotifySetting(String fcmToken, bool isNotify) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      if (kDebugMode) {
        LoggerService.info('デバイストークン登録');
      }
      final status = isNotify ? 1 : 0;
      await supabase.from(Tables.userFcmTokens).upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'is_notify': status,
      });
    } catch (error) {
      // FCMトークン設定のエラーをCrashlyticsに記録（UUIDは含まれる）
      await FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'FCM token registration failed',
      );
      rethrow;
    }
  }
}
