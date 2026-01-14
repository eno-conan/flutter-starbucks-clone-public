import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/id_keys.dart';
import 'fcm_initializer.dart';
import 'firebase_options.dart';
import 'supabase_http_client.dart';

class AppInitializer {
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// 全ての初期化処理を実行
  static Future<void> initializeApp() async {
    // 🔥 まず最初にFirebaseを初期化（Performance監視より前に！）
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // 🆕 Firebase初期化直後にCrashlyticsを設定
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    // FirebasePerformance
    final appStartTrace = FirebasePerformance.instance.newTrace('app_initialization');
    await appStartTrace.start();

    try {
      AppConstants.initialize();

      // 並列で複数の初期化処理を実行
      final parallelInitTrace = FirebasePerformance.instance.newTrace(
        'parallel_services_initialization',
      );
      await parallelInitTrace.start();

      // 🆕 より細かい並列化: 独立した処理を完全に分離
      await Future.wait([
        _initFCM(),
        _initSupabase(),
        _initGoogleSignIn(),
        _setOrientations(),
      ], eagerError: true); // エラーがあれば即座に失敗

      await parallelInitTrace.stop();

      // 成功時にカウンターを増加
      appStartTrace.incrementMetric('successful_initialization', 1);
    } catch (e, stackTrace) {
      // エラー時にカウンターを増加
      appStartTrace.incrementMetric('failed_initialization', 1);

      // 🆕 初期化エラーもCrashlyticsに記録（スタックトレース付き）
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'App initialization failed',
        fatal: true,
      );

      rethrow;
    } finally {
      // トレースを終了
      await appStartTrace.stop();
    }
  }

  // FCMの初期化
  static Future<void> _initFCM() async {
    final fcmTrace = FirebasePerformance.instance.newTrace('fcm_initialization');
    await fcmTrace.start();

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FCMInitializer.initialize();
      fcmTrace.incrementMetric('fcm_init_success', 1);
    } catch (e, stackTrace) {
      fcmTrace.incrementMetric('fcm_init_error', 1);
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    } finally {
      await fcmTrace.stop();
    }
  }

  // Supabase初期化
  static Future<void> _initSupabase() async {
    final supabaseTrace = FirebasePerformance.instance.newTrace('supabase_initialization');
    await supabaseTrace.start();

    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        httpClient: SupabaseHttpClient(),
      );
      supabaseTrace.incrementMetric('supabase_init_success', 1);
    } catch (e, stackTrace) {
      supabaseTrace.incrementMetric('supabase_init_error', 1);
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    } finally {
      await supabaseTrace.stop();
    }
  }

  // Google Sign-In初期化
  static Future<void> _initGoogleSignIn() async {
    final googleSignInTrace = FirebasePerformance.instance.newTrace('google_signin_initialization');
    await googleSignInTrace.start();

    try {
      await GoogleSignIn.instance.initialize(
        clientId: AppConstants.googleClientId,
        serverClientId: AppConstants.googleWebServerClientId,
      );
      googleSignInTrace.incrementMetric('google_signin_init_success', 1);
    } catch (e, stackTrace) {
      googleSignInTrace.incrementMetric('google_signin_init_error', 1);
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    } finally {
      await googleSignInTrace.stop();
    }
  }

  // 画面の向きを設定
  static Future<void> _setOrientations() async {
    final orientationTrace = FirebasePerformance.instance.newTrace('orientation_setup');
    await orientationTrace.start();

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      orientationTrace.incrementMetric('orientation_setup_success', 1);
    } catch (e, stackTrace) {
      orientationTrace.incrementMetric('orientation_setup_error', 1);
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    } finally {
      await orientationTrace.stop();
    }
  }
}
