import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/logger_service.dart';

// 初回の認証状態を取得
final initialAuthStateProvider = FutureProvider<User?>((ref) async {
  final SupabaseClient supabase = GetIt.instance<SupabaseClient>();

  try {
    // 現在のセッションを直接取得（これは即座に完了する）
    final session = supabase.auth.currentSession;
    if (kDebugMode) {
      LoggerService.info('initialAuthStateProvider: ${session?.user.email ?? "未ログイン"}');
    }
    return session?.user;
  } catch (e) {
    if (kDebugMode) {
      LoggerService.warn('initialAuthStateProvider error: $e');
    }
    return null;
  }
});

// リアルタイムの認証状態変更を監視
final authStateProvider = StreamProvider<User?>((ref) {
  final SupabaseClient supabase = GetIt.instance<SupabaseClient>();
  return supabase.auth.onAuthStateChange.map((data) {
    try {
      switch (data.event) {
        case AuthChangeEvent.initialSession:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.initialSession');
          }
          return data.session?.user;
        case AuthChangeEvent.signedIn:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.signedIn');
          }
          return data.session?.user;
        case AuthChangeEvent.signedOut:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.signedOut');
          }
          return null;
        case AuthChangeEvent.tokenRefreshed:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.tokenRefreshed');
          }
          return data.session?.user;
        case AuthChangeEvent.userUpdated:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.userUpdated');
          }
          return data.session?.user;
        case AuthChangeEvent.userDeleted:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.userDeleted');
          }
          return null;
        case AuthChangeEvent.mfaChallengeVerified:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.mfaChallengeVerified');
          }
          return data.session?.user;
        case AuthChangeEvent.passwordRecovery:
          if (kDebugMode) {
            LoggerService.info('authStateProvider:AuthChangeEvent.passwordRecovery');
          }
          return data.session?.user;
      }
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Auth state error: $e');
      }
      return null;
    }
  });
});
