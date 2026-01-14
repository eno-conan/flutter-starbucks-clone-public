import '../app/env/env.dart';

/// 定数クラス
class AppConstants {
  //supabase
  static late final String supabaseUrl;
  static late final String supabaseAnonKey;
  // other project web page
  static late final String starbucksWebUrl;
  // Google Cloud
  static late final String googleClientId;
  static late final String googleWebServerClientId;
  static late final String firebaseHostingDomain;
  // SSL Pinning
  static late final String sslSha256FingerPrint;

  static Future<void> initialize() async {
    supabaseUrl = Env.supabaseUrl;
    starbucksWebUrl = Env.starbucksWebUrl;
    supabaseAnonKey = Env.supabaseAnonKey;
    googleClientId = Env.googleClientId;
    googleWebServerClientId = Env.googleWebServerClientId;
    firebaseHostingDomain = Env.firebaseHostingDomain;
    sslSha256FingerPrint = Env.sslSha256FingerPrint;
  }
}
