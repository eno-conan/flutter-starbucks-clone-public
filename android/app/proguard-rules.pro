# flutter_secure_storage v10用
-keep class com.it_nomads.fluttersecurestorage.ciphers.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# 古い実装を除外（必要に応じて）
-dontwarn androidx.security.crypto.**

# =============================================================================
# ログ出力最適化 (R8/ProGuard)
# =============================================================================

# Flutterの不要デバッグログを削除 (リリースビルドのみ)
# LoggerServiceのデバッグ系メソッド（debug, info, trace）を削除
# 警告・エラー系（warn, error, fatal）は保持
-assumenosideeffects class io.flutter.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Flutter debugPrintを削除（パフォーマンス向上）
-assumenosideeffects class io.flutter.** {
    public static void debugPrint(...);
}

# Android Log.d, Log.v, Log.i を削除 (警告・エラーは保持)
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# =============================================================================
# Firebase Performance最適化
# =============================================================================

# Firebase Performance Monitoring - 不要なデバッグ情報を削除
-keepattributes *Annotation*
-keepclassmembers class com.google.firebase.perf.** { *; }
-keep class com.google.firebase.perf.** { *; }

# =============================================================================
# 一般的なAndroidアプリ最適化
# =============================================================================

# Kotlinコルーチン最適化
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# OkHttp最適化（HTTP通信ライブラリ）
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Gson最適化（JSONライブラリ）
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Retrofit最適化（HTTPクライアント）
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# アプリケーション固有の最適化
-keep class com.enoconan.testingappv2.** { *; }

# R8最適化の強化
-allowaccessmodification
-repackageclasses