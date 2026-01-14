import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'config/app_initializer.dart';
import 'config/observers.dart';
import 'config/service_locator.dart';

void main() async {
  runZonedGuarded(
    () async {
      // Flutterエンジンの初期化
      WidgetsFlutterBinding.ensureInitialized();

      // アプリの初期化処理（Firebase初期化 + Crashlytics設定を含む）
      await AppInitializer.initializeApp();

      // 🆕 GetItの初期化時のエラーハンドリング
      try {
        setupLocator();
      } catch (e, stack) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Error during service locator setup',
        );
        rethrow;
      }

      // 🆕 アプリ起動時のエラーハンドリング
      try {
        runApp(ProviderScope(observers: [Observers()], child: const TestingApp()));
      } catch (e, stack) {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error during app startup');
        rethrow;
      }
    },
    (error, stack) {
      // 🆕 キャッチされなかった非同期エラーをCrashlyticsに記録
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'Uncaught async error in main zone',
      );
    },
  );
}
